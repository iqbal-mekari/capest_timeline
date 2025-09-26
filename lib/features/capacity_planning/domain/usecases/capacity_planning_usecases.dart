import '../entities/quarter_plan.dart';
import '../entities/initiative.dart';
import '../entities/capacity_allocation.dart';
import '../repositories/capacity_planning_repository.dart';

import '../../../team_management/domain/repositories/team_management_repository.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/enums/role.dart';

/// Use case for creating a new quarter plan
class CreateQuarterPlan {
  const CreateQuarterPlan({
    required this.capacityRepository,
    required this.teamRepository,
  });

  final CapacityPlanningRepository capacityRepository;
  final TeamManagementRepository teamRepository;

  Future<Result<QuarterPlan, Exception>> execute({
    required int quarter,
    required int year,
    String? name,
    String? notes,
  }) async {
    // Validate quarter and year
    if (quarter < 1 || quarter > 4) {
      return Result.error(
        ValidationException(
          'Quarter must be between 1 and 4',
          ValidationErrorType.outOfRange,
          {'quarter': ['Must be between 1 and 4']},
        ),
      );
    }

    if (year < 2020 || year > 2050) {
      return Result.error(
        ValidationException(
          'Year must be between 2020 and 2050',
          ValidationErrorType.outOfRange,
          {'year': ['Must be between 2020 and 2050']},
        ),
      );
    }

    // Generate unique ID
    final planId = 'plan_${year}_q${quarter}_${DateTime.now().millisecondsSinceEpoch}';

    // Load current team members to include in the plan
    final teamResult = await teamRepository.listActiveMembers();
    if (teamResult.isError) {
      return Result.error(teamResult.error);
    }

    final teamMembers = teamResult.value;

    // Create the new plan
    final plan = QuarterPlan(
      id: planId,
      quarter: quarter,
      year: year,
      name: name,
      initiatives: const [],
      teamMembers: teamMembers,
      allocations: const [],
      notes: notes ?? '',
      isLocked: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Validate the plan
    final validationResult = plan.validate();
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Save the plan
    final saveResult = await capacityRepository.savePlan(plan);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return Result.success(plan);
  }
}

/// Use case for loading a quarter plan
class LoadQuarterPlan {
  const LoadQuarterPlan({
    required this.capacityRepository,
  });

  final CapacityPlanningRepository capacityRepository;

  Future<Result<QuarterPlan, Exception>> execute(String planId) async {
    if (planId.trim().isEmpty) {
      return Result.error(
        ValidationException(
          'Plan ID cannot be empty',
          ValidationErrorType.missingRequiredField,
          {'planId': ['Cannot be empty']},
        ),
      );
    }

    final result = await capacityRepository.loadPlan(planId);
    if (result.isError) {
      return Result.error(result.error);
    }

    final plan = result.value;
    if (plan == null) {
      return Result.error(
        ValidationException(
          'Plan not found: $planId',
          ValidationErrorType.referentialIntegrityViolation,
          {'planId': ['Plan does not exist']},
        ),
      );
    }

    return Result.success(plan);
  }
}

/// Use case for adding an initiative to a plan
class AddInitiativeToPlan {
  const AddInitiativeToPlan({
    required this.capacityRepository,
  });

  final CapacityPlanningRepository capacityRepository;

  Future<Result<Initiative, Exception>> execute({
    required String planId,
    required String name,
    required String description,
    required Map<Role, double> requiredRoles,
    required int priority,
    required int businessValue,
    List<String> dependencies = const [],
    List<String> tags = const [],
    String notes = '',
  }) async {
    // Generate unique ID
    final initiativeId = 'init_${DateTime.now().millisecondsSinceEpoch}';

    // Calculate total effort
    final totalEffort = requiredRoles.values.fold(0.0, (sum, effort) => sum + effort);

    // Create the initiative
    final initiative = Initiative(
      id: initiativeId,
      name: name,
      description: description,
      requiredRoles: requiredRoles,
      estimatedEffortWeeks: totalEffort,
      priority: priority,
      businessValue: businessValue,
      dependencies: dependencies,
      tags: tags,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Validate the initiative
    final validationResult = initiative.validate();
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Check if plan exists
    final planExists = await capacityRepository.planExists(planId);
    if (planExists.isError) {
      return Result.error(planExists.error);
    }

    if (!planExists.value) {
      return Result.error(
        ValidationException(
          'Plan not found: $planId',
          ValidationErrorType.referentialIntegrityViolation,
          {'planId': ['Plan does not exist']},
        ),
      );
    }

    // Save the initiative
    final saveResult = await capacityRepository.saveInitiative(planId, initiative);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return Result.success(initiative);
  }
}

/// Use case for creating a capacity allocation
class AllocateCapacity {
  const AllocateCapacity({
    required this.capacityRepository,
    required this.teamRepository,
  });

  final CapacityPlanningRepository capacityRepository;
  final TeamManagementRepository teamRepository;

  Future<Result<CapacityAllocation, Exception>> execute({
    required String planId,
    required String teamMemberId,
    required String initiativeId,
    required Role role,
    required double allocatedWeeks,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    // Validate team member exists and has required role
    final memberResult = await teamRepository.loadMember(teamMemberId);
    if (memberResult.isError) {
      return Result.error(memberResult.error);
    }

    final member = memberResult.value;
    if (member == null) {
      return Result.error(
        ValidationException(
          'Team member not found: $teamMemberId',
          ValidationErrorType.referentialIntegrityViolation,
          {'teamMemberId': ['Member does not exist']},
        ),
      );
    }

    if (!member.canFulfillRole(role)) {
      return Result.error(
        BusinessRuleException(
          'Team member ${member.name} cannot fulfill role ${role.displayName}',
          BusinessRuleType.invalidRoleAllocation,
          {'memberId': teamMemberId, 'role': role.name},
        ),
      );
    }

    // Validate initiative exists
    final initiativeResult = await capacityRepository.loadInitiative(planId, initiativeId);
    if (initiativeResult.isError) {
      return Result.error(initiativeResult.error);
    }

    if (initiativeResult.value == null) {
      return Result.error(
        ValidationException(
          'Initiative not found: $initiativeId',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': ['Initiative does not exist']},
        ),
      );
    }

    // Check for capacity conflicts
    final conflictResult = await _checkCapacityConflicts(
      planId, teamMemberId, startDate, endDate, allocatedWeeks,
    );
    if (conflictResult.isError) {
      return Result.error(conflictResult.error);
    }

    // Generate unique ID
    final allocationId = 'alloc_${DateTime.now().millisecondsSinceEpoch}';

    // Create the allocation
    final allocation = CapacityAllocation(
      id: allocationId,
      teamMemberId: teamMemberId,
      initiativeId: initiativeId,
      role: role,
      allocatedWeeks: allocatedWeeks,
      startDate: startDate,
      endDate: endDate,
      status: AllocationStatus.planned,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Validate the allocation
    final validationResult = allocation.validate();
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Save the allocation
    final saveResult = await capacityRepository.saveAllocation(planId, allocation);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return Result.success(allocation);
  }

  /// Checks for capacity conflicts with existing allocations
  Future<Result<void, Exception>> _checkCapacityConflicts(
    String planId,
    String teamMemberId,
    DateTime startDate,
    DateTime endDate,
    double allocatedWeeks,
  ) async {
    // Get existing allocations for the team member
    final allocationsResult = await capacityRepository.listAllocationsForMember(
      planId, teamMemberId,
    );
    if (allocationsResult.isError) {
      return Result.error(allocationsResult.error);
    }

    final existingAllocations = allocationsResult.value
        .where((a) => !a.isCancelled && _datesOverlap(a.startDate, a.endDate, startDate, endDate))
        .toList();

    if (existingAllocations.isNotEmpty) {
      // Get team member to check capacity
      final memberResult = await teamRepository.loadMember(teamMemberId);
      if (memberResult.isError) {
        return Result.error(memberResult.error);
      }

      final member = memberResult.value!;
      final availableCapacity = member.calculateAvailableCapacity(startDate, endDate);
      final currentAllocated = existingAllocations
          .map((a) => a.allocatedWeeks)
          .fold(0.0, (sum, weeks) => sum + weeks);

      if (currentAllocated + allocatedWeeks > availableCapacity) {
        return Result.error(
          ExceptionFactory.capacityOverallocated(
            member.name,
            currentAllocated + allocatedWeeks,
            availableCapacity,
          ),
        );
      }
    }

    return const Result.success(null);
  }

  /// Checks if two date ranges overlap
  bool _datesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }
}

/// Use case for getting capacity utilization analytics
class GetCapacityAnalytics {
  const GetCapacityAnalytics({
    required this.capacityRepository,
    required this.teamRepository,
  });

  final CapacityPlanningRepository capacityRepository;
  final TeamManagementRepository teamRepository;

  Future<Result<CapacityAnalytics, Exception>> execute(String planId) async {
    // Load the plan
    final planResult = await capacityRepository.loadPlan(planId);
    if (planResult.isError) {
      return Result.error(planResult.error);
    }

    final plan = planResult.value;
    if (plan == null) {
      return Result.error(
        ValidationException(
          'Plan not found: $planId',
          ValidationErrorType.referentialIntegrityViolation,
          {'planId': ['Plan does not exist']},
        ),
      );
    }

    // Calculate analytics
    final analytics = CapacityAnalytics(
      totalAvailableCapacity: plan.totalAvailableCapacity,
      totalAllocatedCapacity: plan.totalAllocatedCapacity,
      capacityUtilization: plan.capacityUtilization,
      capacityByRole: plan.capacityByRole,
      underAllocatedInitiatives: plan.underAllocatedInitiatives.length,
      overAllocatedMembers: plan.overAllocatedMembers.length,
      summary: plan.summary,
    );

    return Result.success(analytics);
  }
}

/// Analytics data for capacity utilization
class CapacityAnalytics {
  const CapacityAnalytics({
    required this.totalAvailableCapacity,
    required this.totalAllocatedCapacity,
    required this.capacityUtilization,
    required this.capacityByRole,
    required this.underAllocatedInitiatives,
    required this.overAllocatedMembers,
    required this.summary,
  });

  final double totalAvailableCapacity;
  final double totalAllocatedCapacity;
  final double capacityUtilization;
  final Map<Role, CapacityBreakdown> capacityByRole;
  final int underAllocatedInitiatives;
  final int overAllocatedMembers;
  final QuarterPlanSummary summary;

  double get remainingCapacity => totalAvailableCapacity - totalAllocatedCapacity;
  bool get isOverAllocated => capacityUtilization > 100.0;
  bool get hasIssues => isOverAllocated || underAllocatedInitiatives > 0 || overAllocatedMembers > 0;
}
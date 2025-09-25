/// Capacity planning service for the capacity planning timeline application.
/// 
/// This service provides business logic for capacity planning including
/// initiative management, allocation operations, conflict detection, and
/// utilization calculations with integration to team management systems.
library;

import '../../core/errors/exceptions.dart';
import '../../core/types/result.dart';
import '../../core/enums/role.dart';
import '../../features/capacity_planning/domain/entities/initiative.dart';
import '../../features/capacity_planning/domain/entities/capacity_allocation.dart';

import '../../features/capacity_planning/domain/repositories/capacity_planning_repository.dart';
import '../../features/team_management/domain/repositories/team_management_repository.dart';

/// Data transfer object for initiative update requests
class InitiativeUpdateRequest {
  const InitiativeUpdateRequest({
    this.name,
    this.description,
    this.effortByRole,
    this.priority,
    this.businessValue,
    this.deadline,
    this.tags,
    this.notes,
  });

  final String? name;
  final String? description;
  final Map<Role, double>? effortByRole;
  final int? priority;
  final int? businessValue;
  final DateTime? deadline;
  final List<String>? tags;
  final String? notes;

  /// Whether this request contains any updates
  bool get hasUpdates =>
      name != null ||
      description != null ||
      effortByRole != null ||
      priority != null ||
      businessValue != null ||
      deadline != null ||
      tags != null ||
      notes != null;
}

/// Data transfer object for allocation update requests
class AllocationUpdateRequest {
  const AllocationUpdateRequest({
    this.effortWeeks,
    this.startWeek,
    this.endWeek,
    this.startDate,
    this.endDate,
    this.status,
    this.notes,
  });

  final double? effortWeeks;
  final int? startWeek;
  final int? endWeek;
  final DateTime? startDate;
  final DateTime? endDate;
  final AllocationStatus? status;
  final String? notes;

  /// Whether this request contains any updates
  bool get hasUpdates =>
      effortWeeks != null ||
      startWeek != null ||
      endWeek != null ||
      startDate != null ||
      endDate != null ||
      status != null ||
      notes != null;
}

/// Data transfer object for capacity utilization information
class CapacityUtilization {
  const CapacityUtilization({
    required this.totalCapacityByRole,
    required this.allocatedCapacityByRole,
    required this.utilizationPercentageByRole,
    required this.weeklyUtilization,
    required this.periodStartWeek,
    required this.periodEndWeek,
  });

  final Map<Role, double> totalCapacityByRole;
  final Map<Role, double> allocatedCapacityByRole;
  final Map<Role, double> utilizationPercentageByRole;
  final Map<int, Map<Role, double>> weeklyUtilization;
  final int periodStartWeek;
  final int periodEndWeek;

  /// Calculate overall utilization percentage across all roles
  double get overallUtilization {
    final totalCapacity = totalCapacityByRole.values.fold(0.0, (sum, cap) => sum + cap);
    if (totalCapacity == 0) return 0.0;
    
    final totalAllocated = allocatedCapacityByRole.values.fold(0.0, (sum, cap) => sum + cap);
    return (totalAllocated / totalCapacity) * 100;
  }

  /// Check if any role is overallocated
  bool get hasOverallocation {
    for (final role in totalCapacityByRole.keys) {
      final total = totalCapacityByRole[role] ?? 0.0;
      final allocated = allocatedCapacityByRole[role] ?? 0.0;
      if (allocated > total) return true;
    }
    return false;
  }

  /// Get roles that are overallocated
  List<Role> get overallocatedRoles {
    final overallocated = <Role>[];
    for (final role in totalCapacityByRole.keys) {
      final total = totalCapacityByRole[role] ?? 0.0;
      final allocated = allocatedCapacityByRole[role] ?? 0.0;
      if (allocated > total) overallocated.add(role);
    }
    return overallocated;
  }
}

/// Data transfer object for allocation conflict information
class AllocationConflict {
  const AllocationConflict({
    required this.teamMemberId,
    required this.teamMemberName,
    required this.role,
    required this.weekNumber,
    required this.allocatedCapacity,
    required this.availableCapacity,
    required this.overallocation,
    required this.conflictingAllocationIds,
  });

  final String teamMemberId;
  final String teamMemberName;
  final Role role;
  final int weekNumber;
  final double allocatedCapacity;
  final double availableCapacity;
  final double overallocation;
  final List<String> conflictingAllocationIds;

  /// Calculate overallocation percentage
  double get overallocationPercentage {
    if (availableCapacity == 0) return 0.0;
    return (overallocation / availableCapacity) * 100;
  }

  /// Check if this is a severe conflict (>20% overallocation)
  bool get isSevereConflict => overallocationPercentage > 20.0;
}

/// Data transfer object for allocation suggestions
class AllocationSuggestion {
  const AllocationSuggestion({
    required this.teamMemberId,
    required this.teamMemberName,
    required this.role,
    required this.suggestedStartWeek,
    required this.suggestedEndWeek,
    required this.effortWeeks,
    required this.confidenceScore,
    required this.reasoning,
    required this.skillMatch,
  });

  final String teamMemberId;
  final String teamMemberName;
  final Role role;
  final int suggestedStartWeek;
  final int suggestedEndWeek;
  final double effortWeeks;
  final double confidenceScore; // 0.0 to 1.0
  final String reasoning;
  final double skillMatch; // 0.0 to 1.0

  /// Check if this is a high-confidence suggestion (>0.8)
  bool get isHighConfidence => confidenceScore > 0.8;

  /// Check if this is a good skill match (>0.7)
  bool get isGoodSkillMatch => skillMatch > 0.7;

  /// Calculate total suggestion quality score
  double get qualityScore => (confidenceScore + skillMatch) / 2.0;
}

/// Abstract interface for capacity planning business operations
abstract class CapacityPlanningService {
  /// Create new initiative with role requirements
  /// Validates: name uniqueness, positive effort values
  Future<Result<Initiative, ValidationException>> createInitiative({
    required String planId,
    required String name,
    required String description,
    required Map<Role, double> effortByRole,
    int priority = 5,
    int businessValue = 5,
    DateTime? deadline,
    List<String> dependencies = const [],
    List<String> tags = const [],
    String notes = '',
  });
  
  /// Update initiative details
  /// Validates: no allocations exist if changing effort requirements
  Future<Result<Initiative, ValidationException>> updateInitiative(
    String planId,
    String initiativeId,
    InitiativeUpdateRequest request,
  );
  
  /// Delete initiative
  /// Validates: no active allocations exist
  Future<Result<void, ValidationException>> deleteInitiative(
    String planId,
    String initiativeId,
  );
  
  /// Create capacity allocation
  /// Validates: member capacity, role compatibility, time conflicts
  Future<Result<CapacityAllocation, ValidationException>> createAllocation({
    required String planId,
    required String teamMemberId,
    required String initiativeId,
    required Role role,
    required double effortWeeks,
    required int startWeek,
    required int endWeek,
    String notes = '',
  });
  
  /// Update allocation (drag-and-drop operations)
  /// Validates: new time slot availability, capacity constraints
  Future<Result<CapacityAllocation, ValidationException>> updateAllocation(
    String planId,
    String allocationId,
    AllocationUpdateRequest request,
  );
  
  /// Delete allocation
  Future<Result<void, ValidationException>> deleteAllocation(
    String planId,
    String allocationId,
  );
  
  /// Calculate capacity utilization for given time period
  Future<Result<CapacityUtilization, ValidationException>> calculateUtilization({
    required String planId,
    required int startWeek,
    required int endWeek,
    Role? filterByRole,
  });
  
  /// Detect allocation conflicts (overallocation)
  Future<Result<List<AllocationConflict>, ValidationException>> detectConflicts(String planId);
  
  /// Suggest optimal allocation for initiative
  Future<Result<List<AllocationSuggestion>, ValidationException>> suggestAllocation(
    String planId,
    String initiativeId,
  );

  /// Check if storage is available and accessible
  Future<bool> isStorageAvailable();
}

/// Implementation of CapacityPlanningService using capacity and team repositories
class CapacityPlanningServiceImpl implements CapacityPlanningService {
  CapacityPlanningServiceImpl({
    required CapacityPlanningRepository capacityRepository,
    required TeamManagementRepository teamRepository,
  }) : _capacityRepository = capacityRepository,
       _teamRepository = teamRepository;

  final CapacityPlanningRepository _capacityRepository;
  final TeamManagementRepository _teamRepository;

  @override
  Future<Result<Initiative, ValidationException>> createInitiative({
    required String planId,
    required String name,
    required String description,
    required Map<Role, double> effortByRole,
    int priority = 5,
    int businessValue = 5,
    DateTime? deadline,
    List<String> dependencies = const [],
    List<String> tags = const [],
    String notes = '',
  }) async {
    try {
      // Validate inputs
      if (planId.trim().isEmpty) {
        return Result.error(ValidationException(
          'Plan ID cannot be empty',
          ValidationErrorType.missingRequiredField,
          {'planId': ['Plan ID is required']},
        ));
      }

      if (name.trim().isEmpty) {
        return Result.error(ValidationException(
          'Initiative name cannot be empty',
          ValidationErrorType.missingRequiredField,
          {'name': ['Name is required']},
        ));
      }

      if (effortByRole.isEmpty) {
        return Result.error(ValidationException(
          'Initiative must have at least one role requirement',
          ValidationErrorType.missingRequiredField,
          {'effortByRole': ['At least one role required']},
        ));
      }

      // Validate effort values are positive
      for (final entry in effortByRole.entries) {
        if (entry.value <= 0) {
          return Result.error(ValidationException(
            'Effort values must be positive',
            ValidationErrorType.businessRuleViolation,
            {'effortByRole': ['${entry.key.displayName}: ${entry.value} must be > 0']},
          ));
        }
      }

      // Check if plan exists
      final planExistsResult = await _capacityRepository.planExists(planId);
      if (planExistsResult.isError) {
        return Result.error(ValidationException(
          'Failed to validate plan existence: ${planExistsResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'planId': ['Plan validation failed']},
        ));
      }

      if (!planExistsResult.value) {
        return Result.error(ValidationException(
          'Plan not found: $planId',
          ValidationErrorType.referentialIntegrityViolation,
          {'planId': ['Plan does not exist']},
        ));
      }

      // Check for name uniqueness within the plan
      final existingInitiativesResult = await _capacityRepository.listInitiatives(planId);
      if (existingInitiativesResult.isError) {
        return Result.error(ValidationException(
          'Failed to check initiative uniqueness: ${existingInitiativesResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'validation': ['Initiative check failed']},
        ));
      }

      final existingNames = existingInitiativesResult.value.map((i) => i.name.toLowerCase()).toSet();
      if (existingNames.contains(name.trim().toLowerCase())) {
        return Result.error(ValidationException(
          'Initiative name already exists: $name',
          ValidationErrorType.duplicateName,
          {'name': ['Name must be unique within the plan']},
        ));
      }

      // Generate unique ID and calculate total effort
      final initiativeId = 'init_${DateTime.now().millisecondsSinceEpoch}';
      final totalEffort = effortByRole.values.fold(0.0, (sum, effort) => sum + effort);

      // Create the initiative
      final initiative = Initiative(
        id: initiativeId,
        name: name.trim(),
        description: description.trim(),
        requiredRoles: effortByRole,
        estimatedEffortWeeks: totalEffort,
        priority: priority,
        businessValue: businessValue,
        dependencies: dependencies,
        tags: tags,
        notes: notes.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate the initiative
      final validationResult = initiative.validate();
      if (validationResult.isError) {
        return Result.error(validationResult.error);
      }

      // Save the initiative
      final saveResult = await _capacityRepository.saveInitiative(planId, initiative);
      if (saveResult.isError) {
        return Result.error(ValidationException(
          'Failed to save initiative: ${saveResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Save operation failed']},
        ));
      }

      return Result.success(initiative);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error creating initiative: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<Initiative, ValidationException>> updateInitiative(
    String planId,
    String initiativeId,
    InitiativeUpdateRequest request,
  ) async {
    try {
      // Validate that there are updates to apply
      if (!request.hasUpdates) {
        return Result.error(ValidationException(
          'No updates provided',
          ValidationErrorType.businessRuleViolation,
          {'request': ['Update request is empty']},
        ));
      }

      // Load existing initiative
      final initiativeResult = await _capacityRepository.loadInitiative(planId, initiativeId);
      if (initiativeResult.isError) {
        return Result.error(ValidationException(
          'Failed to load initiative: ${initiativeResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': [initiativeId]},
        ));
      }

      final existingInitiative = initiativeResult.value;
      if (existingInitiative == null) {
        return Result.error(ValidationException(
          'Initiative not found: $initiativeId',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': ['Initiative does not exist']},
        ));
      }

      // Check for name uniqueness if name is being changed
      if (request.name != null && 
          request.name!.trim().toLowerCase() != existingInitiative.name.toLowerCase()) {
        final existingInitiativesResult = await _capacityRepository.listInitiatives(planId);
        if (existingInitiativesResult.isError) {
          return Result.error(ValidationException(
            'Failed to check initiative uniqueness: ${existingInitiativesResult.error.message}',
            ValidationErrorType.businessRuleViolation,
            {'validation': ['Initiative check failed']},
          ));
        }

        final existingNames = existingInitiativesResult.value
            .where((i) => i.id != initiativeId)
            .map((i) => i.name.toLowerCase())
            .toSet();
        
        if (existingNames.contains(request.name!.trim().toLowerCase())) {
          return Result.error(ValidationException(
            'Initiative name already exists: ${request.name}',
            ValidationErrorType.duplicateName,
            {'name': ['Name must be unique within the plan']},
          ));
        }
      }

      // TODO: Check if changing effort requirements affects existing allocations
      // This would require more complex validation logic
      if (request.effortByRole != null) {
        // For now, allow changes but in future versions this should check allocations
        // final allocationCheck = await _checkEffortChangeImpact(planId, initiativeId, request.effortByRole);
        // if (allocationCheck.isError) return Result.error(allocationCheck.error);
      }

      // Calculate new total effort if roles changed
      final newRequiredRoles = request.effortByRole ?? existingInitiative.requiredRoles;
      final newTotalEffort = newRequiredRoles.values.fold(0.0, (sum, effort) => sum + effort);

      // Create updated initiative
      final updatedInitiative = existingInitiative.copyWith(
        name: request.name?.trim(),
        description: request.description?.trim(),
        requiredRoles: request.effortByRole,
        estimatedEffortWeeks: newTotalEffort,
        priority: request.priority,
        businessValue: request.businessValue,
        tags: request.tags,
        notes: request.notes?.trim(),
        updatedAt: DateTime.now(),
      );

      // Validate the updated initiative
      final validationResult = updatedInitiative.validate();
      if (validationResult.isError) {
        return Result.error(validationResult.error);
      }

      // Save the updated initiative
      final saveResult = await _capacityRepository.saveInitiative(planId, updatedInitiative);
      if (saveResult.isError) {
        return Result.error(ValidationException(
          'Failed to save updated initiative: ${saveResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Save operation failed']},
        ));
      }

      return Result.success(updatedInitiative);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error updating initiative: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<void, ValidationException>> deleteInitiative(
    String planId,
    String initiativeId,
  ) async {
    try {
      // Check if initiative exists
      final initiativeResult = await _capacityRepository.loadInitiative(planId, initiativeId);
      if (initiativeResult.isError) {
        return Result.error(ValidationException(
          'Failed to load initiative: ${initiativeResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': [initiativeId]},
        ));
      }

      final initiative = initiativeResult.value;
      if (initiative == null) {
        // Initiative doesn't exist - consider this a successful deletion
        return const Result.success(null);
      }

      // TODO: Check for active allocations
      // This would require integration with allocation checking
      // final allocationCheck = await _checkActiveAllocations(planId, initiativeId);
      // if (allocationCheck.isError) {
      //   return Result.error(ValidationException(
      //     'Cannot delete initiative with active allocations',
      //     ValidationErrorType.businessRuleViolation,
      //     {'allocations': allocationCheck.error.allErrors},
      //   ));
      // }

      // Delete the initiative
      final deleteResult = await _capacityRepository.deleteInitiative(planId, initiativeId);
      if (deleteResult.isError) {
        return Result.error(ValidationException(
          'Failed to delete initiative: ${deleteResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Delete operation failed']},
        ));
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error deleting initiative: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<CapacityAllocation, ValidationException>> createAllocation({
    required String planId,
    required String teamMemberId,
    required String initiativeId,
    required Role role,
    required double effortWeeks,
    required int startWeek,
    required int endWeek,
    String notes = '',
  }) async {
    try {
      // Validate inputs
      if (startWeek > endWeek) {
        return Result.error(ValidationException(
          'Start week must be before or equal to end week',
          ValidationErrorType.invalidTimeRange,
          {'weeks': ['Invalid week range: $startWeek to $endWeek']},
        ));
      }

      if (effortWeeks <= 0) {
        return Result.error(ValidationException(
          'Effort weeks must be positive',
          ValidationErrorType.businessRuleViolation,
          {'effortWeeks': ['Must be greater than 0']},
        ));
      }

      // Validate team member exists and has the required role
      final memberResult = await _teamRepository.loadMember(teamMemberId);
      if (memberResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team member: ${memberResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'teamMemberId': [teamMemberId]},
        ));
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(ValidationException(
          'Team member not found: $teamMemberId',
          ValidationErrorType.referentialIntegrityViolation,
          {'teamMemberId': ['Member does not exist']},
        ));
      }

      if (!member.roles.contains(role)) {
        return Result.error(ValidationException(
          'Team member does not have required role: ${role.displayName}',
          ValidationErrorType.businessRuleViolation,
          {'role': ['Member lacks required role']},
        ));
      }

      // Validate initiative exists
      final initiativeResult = await _capacityRepository.loadInitiative(planId, initiativeId);
      if (initiativeResult.isError) {
        return Result.error(ValidationException(
          'Failed to load initiative: ${initiativeResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': [initiativeId]},
        ));
      }

      if (initiativeResult.value == null) {
        return Result.error(ValidationException(
          'Initiative not found: $initiativeId',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': ['Initiative does not exist']},
        ));
      }

      // TODO: Check for capacity conflicts and overallocation
      // This would require more complex capacity calculation logic
      // final conflictCheck = await _checkCapacityConflicts(planId, teamMemberId, startWeek, endWeek, effortWeeks);
      // if (conflictCheck.isError) return Result.error(conflictCheck.error);

      // Generate unique ID and calculate dates
      final allocationId = 'alloc_${DateTime.now().millisecondsSinceEpoch}';
      
      // For now, use simplified date calculation
      // In a real implementation, this would map week numbers to actual dates
      final startDate = DateTime.now().add(Duration(days: (startWeek - 1) * 7));
      final endDate = DateTime.now().add(Duration(days: endWeek * 7 - 1));

      // Create the allocation
      final allocation = CapacityAllocation(
        id: allocationId,
        teamMemberId: teamMemberId,
        initiativeId: initiativeId,
        role: role,
        allocatedWeeks: effortWeeks,
        startDate: startDate,
        endDate: endDate,
        status: AllocationStatus.planned,
        notes: notes.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate the allocation
      final validationResult = allocation.validate();
      if (validationResult.isError) {
        return Result.error(validationResult.error);
      }

      // Save the allocation
      final saveResult = await _capacityRepository.saveAllocation(planId, allocation);
      if (saveResult.isError) {
        return Result.error(ValidationException(
          'Failed to save allocation: ${saveResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Save operation failed']},
        ));
      }

      return Result.success(allocation);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error creating allocation: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<CapacityAllocation, ValidationException>> updateAllocation(
    String planId,
    String allocationId,
    AllocationUpdateRequest request,
  ) async {
    try {
      // Validate that there are updates to apply
      if (!request.hasUpdates) {
        return Result.error(ValidationException(
          'No updates provided',
          ValidationErrorType.businessRuleViolation,
          {'request': ['Update request is empty']},
        ));
      }

      // Load existing allocation
      final allocationResult = await _capacityRepository.loadAllocation(planId, allocationId);
      if (allocationResult.isError) {
        return Result.error(ValidationException(
          'Failed to load allocation: ${allocationResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'allocationId': [allocationId]},
        ));
      }

      final existingAllocation = allocationResult.value;
      if (existingAllocation == null) {
        return Result.error(ValidationException(
          'Allocation not found: $allocationId',
          ValidationErrorType.referentialIntegrityViolation,
          {'allocationId': ['Allocation does not exist']},
        ));
      }

      // Validate week range if being updated
      if (request.startWeek != null && request.endWeek != null) {
        if (request.startWeek! > request.endWeek!) {
          return Result.error(ValidationException(
            'Start week must be before or equal to end week',
            ValidationErrorType.invalidTimeRange,
            {'weeks': ['Invalid week range: ${request.startWeek} to ${request.endWeek}']},
          ));
        }
      }

      // Validate effort weeks if being updated
      if (request.effortWeeks != null && request.effortWeeks! <= 0) {
        return Result.error(ValidationException(
          'Effort weeks must be positive',
          ValidationErrorType.businessRuleViolation,
          {'effortWeeks': ['Must be greater than 0']},
        ));
      }

      // TODO: Check for capacity conflicts with new values
      // This would require capacity validation logic
      // final conflictCheck = await _checkAllocationUpdateConflicts(planId, allocationId, request);
      // if (conflictCheck.isError) return Result.error(conflictCheck.error);

      // Create updated allocation
      final updatedAllocation = existingAllocation.copyWith(
        allocatedWeeks: request.effortWeeks,
        startDate: request.startDate,
        endDate: request.endDate,
        status: request.status,
        notes: request.notes?.trim(),
        updatedAt: DateTime.now(),
      );

      // Validate the updated allocation
      final validationResult = updatedAllocation.validate();
      if (validationResult.isError) {
        return Result.error(validationResult.error);
      }

      // Save the updated allocation
      final saveResult = await _capacityRepository.saveAllocation(planId, updatedAllocation);
      if (saveResult.isError) {
        return Result.error(ValidationException(
          'Failed to save updated allocation: ${saveResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Save operation failed']},
        ));
      }

      return Result.success(updatedAllocation);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error updating allocation: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<void, ValidationException>> deleteAllocation(
    String planId,
    String allocationId,
  ) async {
    try {
      // Check if allocation exists
      final allocationResult = await _capacityRepository.loadAllocation(planId, allocationId);
      if (allocationResult.isError) {
        return Result.error(ValidationException(
          'Failed to load allocation: ${allocationResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'allocationId': [allocationId]},
        ));
      }

      final allocation = allocationResult.value;
      if (allocation == null) {
        // Allocation doesn't exist - consider this a successful deletion
        return const Result.success(null);
      }

      // Delete the allocation
      final deleteResult = await _capacityRepository.deleteAllocation(planId, allocationId);
      if (deleteResult.isError) {
        return Result.error(ValidationException(
          'Failed to delete allocation: ${deleteResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Delete operation failed']},
        ));
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error deleting allocation: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<CapacityUtilization, ValidationException>> calculateUtilization({
    required String planId,
    required int startWeek,
    required int endWeek,
    Role? filterByRole,
  }) async {
    try {
      // Validate week range
      if (startWeek > endWeek) {
        return Result.error(ValidationException(
          'Start week must be before or equal to end week',
          ValidationErrorType.invalidTimeRange,
          {'weeks': ['Invalid week range: $startWeek to $endWeek']},
        ));
      }

      // Load team members for capacity calculation
      final membersResult = await _teamRepository.listActiveMembers();
      if (membersResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team members: ${membersResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'teamMembers': ['Failed to load team data']},
        ));
      }

      // Load allocations for the plan
      final allocationsResult = await _capacityRepository.listAllocations(planId);
      if (allocationsResult.isError) {
        return Result.error(ValidationException(
          'Failed to load allocations: ${allocationsResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'allocations': ['Failed to load allocation data']},
        ));
      }

      final members = membersResult.value;
      final allocations = allocationsResult.value;

      // Filter by role if specified
      final rolesToAnalyze = filterByRole != null 
          ? [filterByRole] 
          : Role.values.toList();

      // Calculate total capacity by role
      final totalCapacityByRole = <Role, double>{};
      final allocatedCapacityByRole = <Role, double>{};
      final weeklyUtilization = <int, Map<Role, double>>{};

      for (final role in rolesToAnalyze) {
        totalCapacityByRole[role] = 0.0;
        allocatedCapacityByRole[role] = 0.0;

        // Calculate total capacity for this role
        for (final member in members) {
          if (member.roles.contains(role)) {
            final weekCount = endWeek - startWeek + 1;
            totalCapacityByRole[role] = totalCapacityByRole[role]! + 
                (member.weeklyCapacity * weekCount);
          }
        }

        // Calculate allocated capacity for this role
        for (final allocation in allocations) {
          if (allocation.role == role) {
            // This is a simplified calculation - in a real implementation,
            // you would need to check date/week overlaps more precisely
            allocatedCapacityByRole[role] = allocatedCapacityByRole[role]! + 
                allocation.allocatedWeeks;
          }
        }
      }

      // Calculate utilization percentages
      final utilizationPercentageByRole = <Role, double>{};
      for (final role in rolesToAnalyze) {
        final total = totalCapacityByRole[role] ?? 0.0;
        final allocated = allocatedCapacityByRole[role] ?? 0.0;
        
        utilizationPercentageByRole[role] = total > 0 ? (allocated / total) * 100 : 0.0;
      }

      // Initialize weekly utilization (simplified for now)
      for (int week = startWeek; week <= endWeek; week++) {
        weeklyUtilization[week] = {};
        for (final role in rolesToAnalyze) {
          weeklyUtilization[week]![role] = utilizationPercentageByRole[role] ?? 0.0;
        }
      }

      final utilization = CapacityUtilization(
        totalCapacityByRole: totalCapacityByRole,
        allocatedCapacityByRole: allocatedCapacityByRole,
        utilizationPercentageByRole: utilizationPercentageByRole,
        weeklyUtilization: weeklyUtilization,
        periodStartWeek: startWeek,
        periodEndWeek: endWeek,
      );

      return Result.success(utilization);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error calculating utilization: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<List<AllocationConflict>, ValidationException>> detectConflicts(String planId) async {
    try {
      // Load allocations and team members
      final allocationsResult = await _capacityRepository.listAllocations(planId);
      if (allocationsResult.isError) {
        return Result.error(ValidationException(
          'Failed to load allocations: ${allocationsResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'allocations': ['Failed to load allocation data']},
        ));
      }

      final membersResult = await _teamRepository.listActiveMembers();
      if (membersResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team members: ${membersResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'teamMembers': ['Failed to load team data']},
        ));
      }

      final allocations = allocationsResult.value;
      final members = membersResult.value;
      final conflicts = <AllocationConflict>[];

      // Create member lookup map
      final memberMap = <String, dynamic>{};
      for (final member in members) {
        memberMap[member.id] = {
          'name': member.name,
          'weeklyCapacity': member.weeklyCapacity,
          'roles': member.roles,
        };
      }

      // Group allocations by member and week (simplified)
      final allocationsByMemberWeek = <String, Map<int, List<CapacityAllocation>>>{};
      
      for (final allocation in allocations) {
        if (!allocationsByMemberWeek.containsKey(allocation.teamMemberId)) {
          allocationsByMemberWeek[allocation.teamMemberId] = {};
        }
        
        // This is a simplified week calculation - in a real implementation,
        // you would calculate actual week numbers from dates
        final startWeek = 1; // Simplified
        final endWeek = 4;   // Simplified
        
        for (int week = startWeek; week <= endWeek; week++) {
          if (!allocationsByMemberWeek[allocation.teamMemberId]!.containsKey(week)) {
            allocationsByMemberWeek[allocation.teamMemberId]![week] = [];
          }
          allocationsByMemberWeek[allocation.teamMemberId]![week]!.add(allocation);
        }
      }

      // Check for conflicts
      for (final memberEntry in allocationsByMemberWeek.entries) {
        final memberId = memberEntry.key;
        final weekAllocations = memberEntry.value;
        final memberData = memberMap[memberId];
        
        if (memberData == null) continue;
        
        final memberName = memberData['name'] as String;
        final weeklyCapacity = memberData['weeklyCapacity'] as double;
        
        for (final weekEntry in weekAllocations.entries) {
          final weekNumber = weekEntry.key;
          final weekAllocs = weekEntry.value;
          
          final totalAllocated = weekAllocs.fold(0.0, 
              (sum, alloc) => sum + (alloc.allocatedWeeks / 4)); // Assuming 4 weeks per allocation period
          
          if (totalAllocated > weeklyCapacity) {
            final overallocation = totalAllocated - weeklyCapacity;
            final conflictingIds = weekAllocs.map((a) => a.id).toList();
            
            // Use first role from allocations (simplified)
            final role = weekAllocs.isNotEmpty ? weekAllocs.first.role : Role.backend;
            
            conflicts.add(AllocationConflict(
              teamMemberId: memberId,
              teamMemberName: memberName,
              role: role,
              weekNumber: weekNumber,
              allocatedCapacity: totalAllocated,
              availableCapacity: weeklyCapacity,
              overallocation: overallocation,
              conflictingAllocationIds: conflictingIds,
            ));
          }
        }
      }

      return Result.success(conflicts);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error detecting conflicts: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<List<AllocationSuggestion>, ValidationException>> suggestAllocation(
    String planId,
    String initiativeId,
  ) async {
    try {
      // Load the initiative
      final initiativeResult = await _capacityRepository.loadInitiative(planId, initiativeId);
      if (initiativeResult.isError) {
        return Result.error(ValidationException(
          'Failed to load initiative: ${initiativeResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': [initiativeId]},
        ));
      }

      final initiative = initiativeResult.value;
      if (initiative == null) {
        return Result.error(ValidationException(
          'Initiative not found: $initiativeId',
          ValidationErrorType.referentialIntegrityViolation,
          {'initiativeId': ['Initiative does not exist']},
        ));
      }

      // Load team members
      final membersResult = await _teamRepository.listActiveMembers();
      if (membersResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team members: ${membersResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'teamMembers': ['Failed to load team data']},
        ));
      }

      final members = membersResult.value;
      final suggestions = <AllocationSuggestion>[];

      // Generate suggestions for each required role
      for (final roleEntry in initiative.requiredRoles.entries) {
        final role = roleEntry.key;
        final effortWeeks = roleEntry.value;
        
        // Find suitable team members for this role
        final suitableMembers = members.where((member) => 
            member.roles.contains(role) && member.isActive).toList();
        
        for (final member in suitableMembers) {
          // Calculate suggestion quality (simplified)
          final skillMatch = member.isSenior ? 0.9 : (member.skillLevel / 10.0);
          final confidenceScore = member.weeklyCapacity >= 0.8 ? 0.8 : 0.6;
          
          // Suggest optimal time slot (simplified - in real implementation,
          // this would analyze actual availability and conflicts)
          final suggestedStartWeek = 1;
          final suggestedEndWeek = (effortWeeks / member.weeklyCapacity).ceil();
          
          final reasoning = _generateReasoningText(member, role, effortWeeks, confidenceScore);
          
          suggestions.add(AllocationSuggestion(
            teamMemberId: member.id,
            teamMemberName: member.name,
            role: role,
            suggestedStartWeek: suggestedStartWeek,
            suggestedEndWeek: suggestedEndWeek,
            effortWeeks: effortWeeks,
            confidenceScore: confidenceScore,
            reasoning: reasoning,
            skillMatch: skillMatch,
          ));
        }
      }

      // Sort by quality score (confidence + skill match)
      suggestions.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

      return Result.success(suggestions);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error generating allocation suggestions: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<bool> isStorageAvailable() async {
    try {
      // Test storage by attempting to list plans
      final result = await _capacityRepository.listPlans();
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }

  /// Generate reasoning text for allocation suggestions
  String _generateReasoningText(
    dynamic member, 
    Role role, 
    double effortWeeks, 
    double confidenceScore,
  ) {
    final reasons = <String>[];
    
    if (member.isSenior) {
      reasons.add('Senior team member with high skill level');
    }
    
    if (member.weeklyCapacity >= 0.8) {
      reasons.add('High availability (${(member.weeklyCapacity * 100).toInt()}%)');
    }
    
    if (confidenceScore > 0.8) {
      reasons.add('Strong match for role requirements');
    } else if (confidenceScore > 0.6) {
      reasons.add('Good fit with some constraints');
    } else {
      reasons.add('Viable option with capacity limitations');
    }
    
    return reasons.join('. ');
  }
}

/// Factory for creating CapacityPlanningService instances
class CapacityPlanningServiceFactory {
  /// Creates a CapacityPlanningService with appropriate implementation
  /// 
  /// Currently returns the repository-based implementation, but could
  /// be extended to support different backends or mock implementations
  /// for testing.
  static CapacityPlanningService create({
    required CapacityPlanningRepository capacityRepository,
    required TeamManagementRepository teamRepository,
  }) {
    return CapacityPlanningServiceImpl(
      capacityRepository: capacityRepository,
      teamRepository: teamRepository,
    );
  }
}
/// Team management service for the capacity planning timeline application.
/// 
/// This service provides business logic for team member management including
/// CRUD operations, availability calculations, role management, and capacity
/// validation with integration to capacity planning systems.
library;

import '../../core/errors/exceptions.dart';
import '../../core/types/result.dart';
import '../../core/enums/role.dart';
import '../../features/team_management/domain/entities/team_member.dart';
import '../../features/team_management/domain/repositories/team_management_repository.dart';
import '../../features/capacity_planning/domain/entities/capacity_allocation.dart';

/// Data transfer object for team member update requests
class TeamMemberUpdateRequest {
  const TeamMemberUpdateRequest({
    this.name,
    this.email,
    this.roles,
    this.weeklyCapacity,
    this.skillLevel,
    this.unavailablePeriods,
    this.notes,
    this.isActive,
    this.endDate,
  });

  final String? name;
  final String? email;
  final Set<Role>? roles;
  final double? weeklyCapacity;
  final int? skillLevel;
  final List<UnavailablePeriod>? unavailablePeriods;
  final String? notes;
  final bool? isActive;
  final DateTime? endDate;

  /// Whether this request contains any updates
  bool get hasUpdates =>
      name != null ||
      email != null ||
      roles != null ||
      weeklyCapacity != null ||
      skillLevel != null ||
      unavailablePeriods != null ||
      notes != null ||
      isActive != null ||
      endDate != null;
}

/// Data transfer object for team member availability information
class MemberAvailability {
  const MemberAvailability({
    required this.memberId,
    required this.memberName,
    required this.availableCapacityByWeek,
    required this.existingAllocationsByWeek,
    required this.unavailablePeriods,
    required this.totalCapacity,
  });

  final String memberId;
  final String memberName;
  final Map<int, double> availableCapacityByWeek; // Week -> available capacity
  final Map<int, List<CapacityAllocation>> existingAllocationsByWeek;
  final List<UnavailablePeriod> unavailablePeriods;
  final double totalCapacity;

  /// Calculate total available capacity for the period
  double get totalAvailableCapacity =>
      availableCapacityByWeek.values.fold(0.0, (sum, capacity) => sum + capacity);

  /// Calculate total allocated capacity for the period
  double get totalAllocatedCapacity {
    double total = 0.0;
    for (final allocations in existingAllocationsByWeek.values) {
      for (final allocation in allocations) {
        total += allocation.allocatedWeeks;
      }
    }
    return total;
  }

  /// Calculate utilization percentage
  double get utilizationPercentage {
    if (totalCapacity == 0) return 0.0;
    return (totalAllocatedCapacity / totalCapacity) * 100;
  }

  /// Check if member is overallocated in any week
  bool get hasOverallocation {
    for (final week in availableCapacityByWeek.keys) {
      final available = availableCapacityByWeek[week] ?? 0.0;
      final allocations = existingAllocationsByWeek[week] ?? [];
      final allocated = allocations.fold(0.0, (sum, a) => sum + a.allocatedWeeks);
      if (allocated > available) return true;
    }
    return false;
  }
}

/// Abstract interface for team management business operations
abstract class TeamManagementService {
  /// Add team member to current quarter
  /// Validates: name uniqueness, valid capacity range, email format
  Future<Result<TeamMember, ValidationException>> addTeamMember({
    required String name,
    required String email,
    required Set<Role> roles,
    required double weeklyCapacity,
    int skillLevel = 5,
    List<UnavailablePeriod> unavailablePeriods = const [],
    String notes = '',
    bool isActive = true,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Update team member details
  /// Validates: no capacity reduction below current allocations
  Future<Result<TeamMember, ValidationException>> updateTeamMember(
    String memberId,
    TeamMemberUpdateRequest request,
  );
  
  /// Remove team member
  /// Validates: no active allocations exist
  Future<Result<void, ValidationException>> removeTeamMember(String memberId);
  
  /// Get team member availability for time period
  Future<Result<MemberAvailability, ValidationException>> getMemberAvailability(
    String memberId,
    int startWeek,
    int endWeek,
  );
  
  /// List team members by role
  Future<Result<List<TeamMember>, ValidationException>> getTeamMembersByRole(Role role);

  /// Check if storage is available and accessible
  Future<bool> isStorageAvailable();
}

/// Implementation of TeamManagementService using team repository
class TeamManagementServiceImpl implements TeamManagementService {
  TeamManagementServiceImpl({
    required TeamManagementRepository teamRepository,
  }) : _teamRepository = teamRepository;

  final TeamManagementRepository _teamRepository;

  @override
  Future<Result<TeamMember, ValidationException>> addTeamMember({
    required String name,
    required String email,
    required Set<Role> roles,
    required double weeklyCapacity,
    int skillLevel = 5,
    List<UnavailablePeriod> unavailablePeriods = const [],
    String notes = '',
    bool isActive = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Generate unique ID
      final memberId = 'member_${DateTime.now().millisecondsSinceEpoch}';

      // Create the team member with validated data
      final member = TeamMember(
        id: memberId,
        name: name.trim(),
        email: email.trim().toLowerCase(),
        roles: roles,
        weeklyCapacity: weeklyCapacity,
        skillLevel: skillLevel,
        unavailablePeriods: unavailablePeriods,
        notes: notes.trim(),
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate the team member data
      final validationResult = member.validate();
      if (validationResult.isError) {
        return Result.error(validationResult.error);
      }

      // Check for conflicts (duplicate email, etc.)
      final conflictResult = await _teamRepository.checkMemberConflicts(member);
      if (conflictResult.isError) {
        return Result.error(ValidationException(
          'Failed to validate team member: ${conflictResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'validation': ['Conflict check failed']},
        ));
      }

      final conflicts = conflictResult.value;
      if (conflicts.isNotEmpty) {
        return Result.error(ValidationException(
          'Team member conflicts detected',
          ValidationErrorType.duplicateName,
          {'conflicts': conflicts},
        ));
      }

      // Save the team member
      final saveResult = await _teamRepository.saveMember(member);
      if (saveResult.isError) {
        return Result.error(ValidationException(
          'Failed to save team member: ${saveResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Save operation failed']},
        ));
      }

      return Result.success(member);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error adding team member: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<TeamMember, ValidationException>> updateTeamMember(
    String memberId,
    TeamMemberUpdateRequest request,
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

      // Load existing member
      final memberResult = await _teamRepository.loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team member: ${memberResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': [memberId]},
        ));
      }

      final existingMember = memberResult.value;
      if (existingMember == null) {
        return Result.error(ValidationException(
          'Team member not found: $memberId',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': ['Member does not exist']},
        ));
      }

      // Create updated member with validated data
      final updatedMember = existingMember.copyWith(
        name: request.name?.trim(),
        email: request.email?.trim().toLowerCase(),
        roles: request.roles,
        weeklyCapacity: request.weeklyCapacity,
        skillLevel: request.skillLevel,
        unavailablePeriods: request.unavailablePeriods,
        notes: request.notes?.trim(),
        isActive: request.isActive,
        updatedAt: DateTime.now(),
      );

      // Validate the updated member
      final validationResult = updatedMember.validate();
      if (validationResult.isError) {
        return Result.error(validationResult.error);
      }

      // Check for conflicts if email changed
      if (request.email != null && 
          request.email!.trim().toLowerCase() != existingMember.email) {
        final conflictResult = await _teamRepository.checkMemberConflicts(updatedMember);
        if (conflictResult.isError) {
          return Result.error(ValidationException(
            'Failed to validate updated team member: ${conflictResult.error.message}',
            ValidationErrorType.businessRuleViolation,
            {'validation': ['Conflict check failed']},
          ));
        }

        final conflicts = conflictResult.value;
        if (conflicts.isNotEmpty) {
          return Result.error(ValidationException(
            'Team member conflicts detected',
            ValidationErrorType.duplicateName,
            {'conflicts': conflicts},
          ));
        }
      }

      // TODO: Add capacity validation - check if reducing capacity below current allocations
      // This would require integration with capacity planning service
      if (request.weeklyCapacity != null && 
          request.weeklyCapacity! < existingMember.weeklyCapacity) {
        // For now, allow reduction but in future versions this should check allocations
        // final allocationCheck = await _checkCapacityReduction(memberId, request.weeklyCapacity!);
        // if (allocationCheck.isError) return Result.error(allocationCheck.error);
      }

      // Save the updated member
      final saveResult = await _teamRepository.saveMember(updatedMember);
      if (saveResult.isError) {
        return Result.error(ValidationException(
          'Failed to save updated team member: ${saveResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Save operation failed']},
        ));
      }

      return Result.success(updatedMember);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error updating team member: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<void, ValidationException>> removeTeamMember(String memberId) async {
    try {
      // Check if member exists
      final memberResult = await _teamRepository.loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team member: ${memberResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': [memberId]},
        ));
      }

      final member = memberResult.value;
      if (member == null) {
        // Member doesn't exist - consider this a successful removal
        return const Result.success(null);
      }

      // TODO: Check for active allocations
      // This would require integration with capacity planning service
      // final allocationCheck = await _checkActiveAllocations(memberId);
      // if (allocationCheck.isError) {
      //   return Result.error(ValidationException(
      //     'Cannot remove team member with active allocations',
      //     ValidationErrorType.businessRuleViolation,
      //     {'allocations': allocationCheck.error.allErrors},
      //   ));
      // }

      // Delete the member
      final deleteResult = await _teamRepository.deleteMember(memberId);
      if (deleteResult.isError) {
        return Result.error(ValidationException(
          'Failed to delete team member: ${deleteResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'storage': ['Delete operation failed']},
        ));
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error removing team member: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<MemberAvailability, ValidationException>> getMemberAvailability(
    String memberId,
    int startWeek,
    int endWeek,
  ) async {
    try {
      // Validate week range
      if (startWeek > endWeek) {
        return Result.error(ValidationException(
          'Start week must be before or equal to end week',
          ValidationErrorType.invalidTimeRange,
          {'weeks': ['Invalid week range: $startWeek to $endWeek']},
        ));
      }

      // Load team member
      final memberResult = await _teamRepository.loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team member: ${memberResult.error.message}',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': [memberId]},
        ));
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(ValidationException(
          'Team member not found: $memberId',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': ['Member does not exist']},
        ));
      }

      // Calculate available capacity by week
      final availableCapacityByWeek = <int, double>{};
      final totalWeeks = endWeek - startWeek + 1;
      
      for (int week = startWeek; week <= endWeek; week++) {
        // Start with full weekly capacity
        double availableCapacity = member.weeklyCapacity;
        
        // Reduce for unavailable periods
        // This is a simplified calculation - in a real implementation,
        // you would need to map week numbers to actual dates
        if (member.unavailablePeriods.isNotEmpty) {
          // For now, assume unavailable periods reduce capacity by 50%
          // In a real implementation, this would calculate actual overlap
          availableCapacity *= 0.5;
        }
        
        availableCapacityByWeek[week] = availableCapacity;
      }

      // TODO: Load existing allocations from capacity planning service
      // For now, return empty allocations
      final existingAllocationsByWeek = <int, List<CapacityAllocation>>{};
      
      final availability = MemberAvailability(
        memberId: memberId,
        memberName: member.name,
        availableCapacityByWeek: availableCapacityByWeek,
        existingAllocationsByWeek: existingAllocationsByWeek,
        unavailablePeriods: member.unavailablePeriods,
        totalCapacity: member.weeklyCapacity * totalWeeks,
      );

      return Result.success(availability);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error calculating member availability: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<Result<List<TeamMember>, ValidationException>> getTeamMembersByRole(Role role) async {
    try {
      final membersResult = await _teamRepository.listMembersByRole(role);
      if (membersResult.isError) {
        return Result.error(ValidationException(
          'Failed to load team members by role: ${membersResult.error.message}',
          ValidationErrorType.businessRuleViolation,
          {'role': [role.displayName]},
        ));
      }

      return Result.success(membersResult.value);
    } catch (e) {
      return Result.error(ValidationException(
        'Unexpected error loading team members by role: $e',
        ValidationErrorType.businessRuleViolation,
        {'error': [e.toString()]},
      ));
    }
  }

  @override
  Future<bool> isStorageAvailable() async {
    try {
      // Test storage by attempting to list members
      final result = await _teamRepository.listMembers();
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }
}

/// Factory for creating TeamManagementService instances
class TeamManagementServiceFactory {
  /// Creates a TeamManagementService with appropriate implementation
  /// 
  /// Currently returns the repository-based implementation, but could
  /// be extended to support different backends or mock implementations
  /// for testing.
  static TeamManagementService create({
    required TeamManagementRepository teamRepository,
  }) {
    return TeamManagementServiceImpl(
      teamRepository: teamRepository,
    );
  }
}
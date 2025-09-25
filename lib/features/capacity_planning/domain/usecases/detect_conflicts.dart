import '../entities/capacity_allocation.dart';
import '../../../team_management/domain/entities/team_member.dart';
import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Request object for detecting allocation conflicts
class DetectConflictsRequest {
  final List<TeamMember> teamMembers;
  final List<CapacityAllocation> allocations;
  final DateTime? startDate;
  final DateTime? endDate;
  final Role? filterByRole;
  final String? filterByMemberId;

  const DetectConflictsRequest({
    required this.teamMembers,
    required this.allocations,
    this.startDate,
    this.endDate,
    this.filterByRole,
    this.filterByMemberId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetectConflictsRequest &&
          runtimeType == other.runtimeType &&
          _listEquals(teamMembers, other.teamMembers) &&
          _listEquals(allocations, other.allocations) &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          filterByRole == other.filterByRole &&
          filterByMemberId == other.filterByMemberId;

  @override
  int get hashCode =>
      teamMembers.hashCode ^
      allocations.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      filterByRole.hashCode ^
      filterByMemberId.hashCode;

  /// Deep equality check for lists
  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'DetectConflictsRequest(members: ${teamMembers.length}, allocations: ${allocations.length}, '
      'period: ${startDate?.toIso8601String().split('T')[0] ?? "all"} - ${endDate?.toIso8601String().split('T')[0] ?? "all"})';
}

/// Represents an allocation conflict (overallocation)
class AllocationConflict {
  final String teamMemberId;
  final String teamMemberName;
  final Role role;
  final DateTime conflictStart;
  final DateTime conflictEnd;
  final double allocatedCapacity;
  final double availableCapacity;
  final double overallocation;
  final List<String> conflictingAllocationIds;
  final ConflictSeverity severity;
  final String description;

  const AllocationConflict({
    required this.teamMemberId,
    required this.teamMemberName,
    required this.role,
    required this.conflictStart,
    required this.conflictEnd,
    required this.allocatedCapacity,
    required this.availableCapacity,
    required this.overallocation,
    required this.conflictingAllocationIds,
    required this.severity,
    required this.description,
  });

  /// Duration of the conflict in weeks
  double get conflictDurationWeeks => conflictEnd.difference(conflictStart).inDays / 7.0;

  /// Overallocation percentage
  double get overallocationPercentage => availableCapacity == 0 ? 0 : (overallocation / availableCapacity) * 100;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllocationConflict &&
          runtimeType == other.runtimeType &&
          teamMemberId == other.teamMemberId &&
          role == other.role &&
          conflictStart == other.conflictStart &&
          conflictEnd == other.conflictEnd;

  @override
  int get hashCode =>
      teamMemberId.hashCode ^
      role.hashCode ^
      conflictStart.hashCode ^
      conflictEnd.hashCode;

  @override
  String toString() =>
      'AllocationConflict(member: $teamMemberName, role: ${role.displayName}, '
      'overallocation: ${overallocation.toStringAsFixed(1)}w, severity: ${severity.name})';
}

/// Severity levels for allocation conflicts
enum ConflictSeverity {
  low('Low', 'Minor overallocation (< 20%)'),
  medium('Medium', 'Moderate overallocation (20-50%)'),
  high('High', 'Significant overallocation (50-100%)'),
  critical('Critical', 'Severe overallocation (> 100%)');

  const ConflictSeverity(this.displayName, this.description);

  final String displayName;
  final String description;

  /// Determines severity based on overallocation percentage
  static ConflictSeverity fromPercentage(double percentage) {
    if (percentage > 100) return ConflictSeverity.critical;
    if (percentage > 50) return ConflictSeverity.high;
    if (percentage > 20) return ConflictSeverity.medium;
    return ConflictSeverity.low;
  }

  /// Gets color indicator for UI display
  String get colorIndicator {
    switch (this) {
      case ConflictSeverity.low:
        return 'yellow';
      case ConflictSeverity.medium:
        return 'orange';
      case ConflictSeverity.high:
        return 'red';
      case ConflictSeverity.critical:
        return 'darkred';
    }
  }
}

/// Use case for detecting allocation conflicts (overallocation)
/// Identifies when team members are allocated beyond their capacity
class DetectConflicts {
  /// Detect allocation conflicts for the given team and allocations
  /// 
  /// Analyzes:
  /// - Team member capacity vs allocated time
  /// - Time period overlaps
  /// - Role compatibility
  /// - Unavailable periods
  /// - Multiple allocation conflicts
  /// 
  /// Returns: List of detected conflicts
  Future<Result<List<AllocationConflict>, ValidationException>> call(
    DetectConflictsRequest request,
  ) async {
    // Validate request
    final validationResult = _validateRequest(request);
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    try {
      final conflicts = <AllocationConflict>[];

      // Create a map of team members for easy lookup
      final memberMap = <String, TeamMember>{};
      for (final member in request.teamMembers) {
        memberMap[member.id] = member;
      }

      // Filter allocations based on request criteria
      final filteredAllocations = _filterAllocations(request);

      // Group allocations by team member and role
      final allocationsByMemberAndRole = <String, Map<Role, List<CapacityAllocation>>>{};
      for (final allocation in filteredAllocations) {
        if (allocation.isCancelled) continue; // Skip cancelled allocations

        allocationsByMemberAndRole.putIfAbsent(allocation.teamMemberId, () => {});
        allocationsByMemberAndRole[allocation.teamMemberId]!
            .putIfAbsent(allocation.role, () => [])
            .add(allocation);
      }

      // Check each member-role combination for conflicts
      for (final memberEntry in allocationsByMemberAndRole.entries) {
        final memberId = memberEntry.key;
        final member = memberMap[memberId];
        if (member == null || !member.isActive) continue;

        for (final roleEntry in memberEntry.value.entries) {
          final role = roleEntry.key;
          final allocations = roleEntry.value;

          // Check if member can fulfill this role
          if (!member.canFulfillRole(role)) {
            // This is a role compatibility conflict
            final conflict = _createRoleConflict(member, role, allocations);
            conflicts.add(conflict);
            continue;
          }

          // Detect time-based overallocation conflicts
          final timeConflicts = _detectTimeBasedConflicts(member, role, allocations, request);
          conflicts.addAll(timeConflicts);
        }
      }

      return Result.success(conflicts);
    } catch (e) {
      return Result.error(
        ValidationException(
          'Failed to detect conflicts: ${e.toString()}',
          ValidationErrorType.businessRuleViolation,
        ),
      );
    }
  }

  /// Validates the detect conflicts request
  Result<void, ValidationException> _validateRequest(DetectConflictsRequest request) {
    final fieldErrors = <String, List<String>>{};

    // Validate date range if provided
    if (request.startDate != null && request.endDate != null) {
      if (request.startDate!.isAfter(request.endDate!)) {
        fieldErrors['dateRange'] = ['Start date must be before or equal to end date'];
      }
    }

    if (fieldErrors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Conflict detection validation failed',
          ValidationErrorType.missingRequiredField,
          fieldErrors,
        ),
      );
    }

    return const Result.success(null);
  }

  /// Filters allocations based on request criteria
  List<CapacityAllocation> _filterAllocations(DetectConflictsRequest request) {
    return request.allocations.where((allocation) {
      // Filter by date range
      if (request.startDate != null && request.endDate != null) {
        if (!_periodsOverlap(
          allocation.startDate,
          allocation.endDate,
          request.startDate!,
          request.endDate!,
        )) {
          return false;
        }
      }

      // Filter by role
      if (request.filterByRole != null && allocation.role != request.filterByRole) {
        return false;
      }

      // Filter by member ID
      if (request.filterByMemberId != null && allocation.teamMemberId != request.filterByMemberId) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Creates a role compatibility conflict
  AllocationConflict _createRoleConflict(
    TeamMember member,
    Role role,
    List<CapacityAllocation> allocations,
  ) {
    final earliestStart = allocations.map((a) => a.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    final latestEnd = allocations.map((a) => a.endDate).reduce((a, b) => a.isAfter(b) ? a : b);
    final totalAllocation = allocations.fold(0.0, (sum, a) => sum + a.allocatedWeeks);

    return AllocationConflict(
      teamMemberId: member.id,
      teamMemberName: member.name,
      role: role,
      conflictStart: earliestStart,
      conflictEnd: latestEnd,
      allocatedCapacity: totalAllocation,
      availableCapacity: 0.0, // Member cannot fulfill this role
      overallocation: totalAllocation,
      conflictingAllocationIds: allocations.map((a) => a.id).toList(),
      severity: ConflictSeverity.critical,
      description: '${member.name} cannot fulfill role ${role.displayName}',
    );
  }

  /// Detects time-based overallocation conflicts
  List<AllocationConflict> _detectTimeBasedConflicts(
    TeamMember member,
    Role role,
    List<CapacityAllocation> allocations,
    DetectConflictsRequest request,
  ) {
    final conflicts = <AllocationConflict>[];

    // Sort allocations by start date
    allocations.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Find overlapping periods and check for overallocation
    for (int i = 0; i < allocations.length; i++) {
      final currentAllocation = allocations[i];
      final overlappingAllocations = <CapacityAllocation>[currentAllocation];

      // Find all allocations that overlap with current allocation
      for (int j = i + 1; j < allocations.length; j++) {
        final otherAllocation = allocations[j];
        if (_periodsOverlap(
          currentAllocation.startDate,
          currentAllocation.endDate,
          otherAllocation.startDate,
          otherAllocation.endDate,
        )) {
          overlappingAllocations.add(otherAllocation);
        }
      }

      // If there are overlapping allocations, check for overallocation
      if (overlappingAllocations.length > 1) {
        final conflict = _analyzeOverlappingAllocations(member, role, overlappingAllocations);
        if (conflict != null) {
          conflicts.add(conflict);
        }
      }
    }

    return conflicts;
  }

  /// Analyzes overlapping allocations for overallocation
  AllocationConflict? _analyzeOverlappingAllocations(
    TeamMember member,
    Role role,
    List<CapacityAllocation> overlappingAllocations,
  ) {
    // Find the overall conflict period
    final conflictStart = overlappingAllocations
        .map((a) => a.startDate)
        .reduce((a, b) => a.isAfter(b) ? a : b); // Latest start
    final conflictEnd = overlappingAllocations
        .map((a) => a.endDate)
        .reduce((a, b) => a.isBefore(b) ? a : b); // Earliest end

    // Calculate total weekly capacity needed during conflict period
    var totalWeeklyCapacityNeeded = 0.0;
    for (final allocation in overlappingAllocations) {
      totalWeeklyCapacityNeeded += allocation.weeklyCapacityNeeded;
    }

    // Calculate available weekly capacity for the member
    final conflictDurationWeeks = conflictEnd.difference(conflictStart).inDays / 7.0;
    final availableCapacity = member.calculateAvailableCapacity(conflictStart, conflictEnd);
    final availableWeeklyCapacity = conflictDurationWeeks > 0 ? availableCapacity / conflictDurationWeeks : 0;

    // Check if overallocated
    final overallocation = totalWeeklyCapacityNeeded - availableWeeklyCapacity;
    if (overallocation <= 0.01) return null; // No significant overallocation

    final overallocationPercentage = availableWeeklyCapacity == 0 
        ? 100.0 
        : (overallocation / availableWeeklyCapacity) * 100;

    return AllocationConflict(
      teamMemberId: member.id,
      teamMemberName: member.name,
      role: role,
      conflictStart: conflictStart,
      conflictEnd: conflictEnd,
      allocatedCapacity: totalWeeklyCapacityNeeded * conflictDurationWeeks,
      availableCapacity: availableCapacity,
      overallocation: overallocation * conflictDurationWeeks,
      conflictingAllocationIds: overlappingAllocations.map((a) => a.id).toList(),
      severity: ConflictSeverity.fromPercentage(overallocationPercentage),
      description: '${member.name} is overallocated by ${overallocation.toStringAsFixed(1)} weeks '
          'for ${role.displayName} role during ${conflictStart.toIso8601String().split('T')[0]} - '
          '${conflictEnd.toIso8601String().split('T')[0]}',
    );
  }

  /// Checks if two time periods overlap
  bool _periodsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }
}
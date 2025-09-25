import '../entities/capacity_allocation.dart';
import '../../../team_management/domain/entities/team_member.dart';
import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Request object for calculating capacity utilization
class CalculateUtilizationRequest {
  final DateTime startDate;
  final DateTime endDate;
  final Role? filterByRole;
  final List<TeamMember> teamMembers;
  final List<CapacityAllocation> allocations;

  const CalculateUtilizationRequest({
    required this.startDate,
    required this.endDate,
    required this.teamMembers,
    required this.allocations,
    this.filterByRole,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculateUtilizationRequest &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          filterByRole == other.filterByRole &&
          _listEquals(teamMembers, other.teamMembers) &&
          _listEquals(allocations, other.allocations);

  @override
  int get hashCode =>
      startDate.hashCode ^
      endDate.hashCode ^
      filterByRole.hashCode ^
      teamMembers.hashCode ^
      allocations.hashCode;

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
      'CalculateUtilizationRequest(period: ${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]}, '
      'role: ${filterByRole?.displayName ?? "all"}, members: ${teamMembers.length}, allocations: ${allocations.length})';
}

/// Result object containing capacity utilization calculations
class CapacityUtilization {
  final Map<Role, double> totalCapacityByRole;
  final Map<Role, double> allocatedCapacityByRole;
  final Map<Role, double> utilizationPercentageByRole;
  final Map<int, Map<Role, double>> weeklyUtilization;
  final DateTime startDate;
  final DateTime endDate;
  final Role? filterByRole;

  const CapacityUtilization({
    required this.totalCapacityByRole,
    required this.allocatedCapacityByRole,
    required this.utilizationPercentageByRole,
    required this.weeklyUtilization,
    required this.startDate,
    required this.endDate,
    this.filterByRole,
  });

  /// Gets the overall utilization percentage across all roles
  double get overallUtilization {
    final totalCapacity = totalCapacityByRole.values.fold(0.0, (sum, capacity) => sum + capacity);
    final allocatedCapacity = allocatedCapacityByRole.values.fold(0.0, (sum, capacity) => sum + capacity);
    
    if (totalCapacity == 0) return 0.0;
    return (allocatedCapacity / totalCapacity) * 100;
  }

  /// Gets remaining capacity by role
  Map<Role, double> get remainingCapacityByRole {
    final remaining = <Role, double>{};
    for (final role in totalCapacityByRole.keys) {
      final total = totalCapacityByRole[role] ?? 0.0;
      final allocated = allocatedCapacityByRole[role] ?? 0.0;
      remaining[role] = (total - allocated).clamp(0.0, double.infinity);
    }
    return remaining;
  }

  /// Gets over-allocated roles (utilization > 100%)
  Set<Role> get overAllocatedRoles {
    return utilizationPercentageByRole.entries
        .where((entry) => entry.value > 100.0)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Gets under-utilized roles (utilization < 80%)
  Set<Role> get underUtilizedRoles {
    return utilizationPercentageByRole.entries
        .where((entry) => entry.value < 80.0)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Duration of the utilization calculation period in weeks
  double get durationInWeeks => endDate.difference(startDate).inDays / 7.0;

  @override
  String toString() =>
      'CapacityUtilization(period: ${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]}, '
      'overall: ${overallUtilization.toStringAsFixed(1)}%, roles: ${totalCapacityByRole.keys.length})';
}

/// Use case for calculating capacity utilization for a given time period
/// Analyzes team member capacity vs allocated capacity across roles and time
class CalculateUtilization {
  /// Calculate capacity utilization for given time period
  /// 
  /// Calculates:
  /// - Total available capacity by role
  /// - Total allocated capacity by role
  /// - Utilization percentages by role
  /// - Weekly utilization breakdown
  /// - Overall utilization metrics
  /// 
  /// Returns: Utilization analysis or validation exception
  Future<Result<CapacityUtilization, ValidationException>> call(
    CalculateUtilizationRequest request,
  ) async {
    // Validate request
    final validationResult = _validateRequest(request);
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    try {
      // Calculate total capacity by role
      final totalCapacityByRole = _calculateTotalCapacity(request);

      // Calculate allocated capacity by role
      final allocatedCapacityByRole = _calculateAllocatedCapacity(request);

      // Calculate utilization percentages
      final utilizationPercentageByRole = _calculateUtilizationPercentages(
        totalCapacityByRole,
        allocatedCapacityByRole,
      );

      // Calculate weekly utilization breakdown
      final weeklyUtilization = _calculateWeeklyUtilization(request);

      final result = CapacityUtilization(
        totalCapacityByRole: totalCapacityByRole,
        allocatedCapacityByRole: allocatedCapacityByRole,
        utilizationPercentageByRole: utilizationPercentageByRole,
        weeklyUtilization: weeklyUtilization,
        startDate: request.startDate,
        endDate: request.endDate,
        filterByRole: request.filterByRole,
      );

      return Result.success(result);
    } catch (e) {
      return Result.error(
        ValidationException(
          'Failed to calculate utilization: ${e.toString()}',
          ValidationErrorType.businessRuleViolation,
        ),
      );
    }
  }

  /// Validates the calculate utilization request
  Result<void, ValidationException> _validateRequest(
    CalculateUtilizationRequest request,
  ) {
    final fieldErrors = <String, List<String>>{};

    // Validate date range
    if (request.startDate.isAfter(request.endDate)) {
      fieldErrors['dateRange'] = ['Start date must be before or equal to end date'];
    }

    // Validate reasonable time range (not more than 2 years)
    final maxDuration = const Duration(days: 730); // 2 years
    if (request.endDate.difference(request.startDate) > maxDuration) {
      fieldErrors['dateRange'] = ['Time period cannot exceed 2 years'];
    }

    // Validate minimum duration (at least 1 day)
    if (request.endDate.difference(request.startDate).inDays < 1) {
      fieldErrors['dateRange'] = ['Time period must be at least 1 day'];
    }

    if (fieldErrors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Utilization calculation validation failed',
          ValidationErrorType.missingRequiredField,
          fieldErrors,
        ),
      );
    }

    return const Result.success(null);
  }

  /// Calculates total available capacity by role for the time period
  Map<Role, double> _calculateTotalCapacity(CalculateUtilizationRequest request) {
    final capacityByRole = <Role, double>{};

    for (final member in request.teamMembers) {
      if (!member.isActive) continue;

      // Calculate member's available capacity for the period
      final availableCapacity = member.calculateAvailableCapacity(
        request.startDate,
        request.endDate,
      );

      // Add capacity for each role the member can fulfill
      for (final role in member.roles) {
        if (request.filterByRole != null && role != request.filterByRole) continue;
        
        capacityByRole[role] = (capacityByRole[role] ?? 0.0) + availableCapacity;
      }
    }

    return capacityByRole;
  }

  /// Calculates total allocated capacity by role for the time period
  Map<Role, double> _calculateAllocatedCapacity(CalculateUtilizationRequest request) {
    final allocatedByRole = <Role, double>{};

    for (final allocation in request.allocations) {
      // Skip cancelled allocations
      if (allocation.isCancelled) continue;

      // Check if allocation overlaps with the requested time period
      if (!_periodsOverlap(
        allocation.startDate,
        allocation.endDate,
        request.startDate,
        request.endDate,
      )) continue;

      // Filter by role if specified
      if (request.filterByRole != null && allocation.role != request.filterByRole) continue;

      // Calculate overlapping portion of the allocation
      final overlapStart = allocation.startDate.isAfter(request.startDate)
          ? allocation.startDate
          : request.startDate;
      final overlapEnd = allocation.endDate.isBefore(request.endDate)
          ? allocation.endDate
          : request.endDate;

      final overlapWeeks = overlapEnd.difference(overlapStart).inDays / 7.0;
      final allocationWeeks = allocation.endDate.difference(allocation.startDate).inDays / 7.0;
      
      // Calculate proportional allocation for the overlapping period
      final proportionalAllocation = (overlapWeeks / allocationWeeks) * allocation.allocatedWeeks;

      allocatedByRole[allocation.role] = (allocatedByRole[allocation.role] ?? 0.0) + proportionalAllocation;
    }

    return allocatedByRole;
  }

  /// Calculates utilization percentages by role
  Map<Role, double> _calculateUtilizationPercentages(
    Map<Role, double> totalCapacity,
    Map<Role, double> allocatedCapacity,
  ) {
    final utilizationByRole = <Role, double>{};

    for (final role in totalCapacity.keys) {
      final total = totalCapacity[role] ?? 0.0;
      final allocated = allocatedCapacity[role] ?? 0.0;

      if (total == 0) {
        utilizationByRole[role] = 0.0;
      } else {
        utilizationByRole[role] = (allocated / total) * 100;
      }
    }

    return utilizationByRole;
  }

  /// Calculates weekly utilization breakdown
  Map<int, Map<Role, double>> _calculateWeeklyUtilization(CalculateUtilizationRequest request) {
    final weeklyUtilization = <int, Map<Role, double>>{};
    final startOfWeek = _getStartOfWeek(request.startDate);
    var currentWeek = startOfWeek;
    var weekNumber = 1;

    while (currentWeek.isBefore(request.endDate)) {
      final weekEnd = currentWeek.add(const Duration(days: 6));
      final effectiveWeekEnd = weekEnd.isBefore(request.endDate) ? weekEnd : request.endDate;

      final weeklyCapacity = <Role, double>{};
      final weeklyAllocated = <Role, double>{};

      // Calculate capacity for this week
      for (final member in request.teamMembers) {
        if (!member.isActive) continue;

        final memberWeeklyCapacity = member.calculateAvailableCapacity(currentWeek, effectiveWeekEnd);
        
        for (final role in member.roles) {
          if (request.filterByRole != null && role != request.filterByRole) continue;
          weeklyCapacity[role] = (weeklyCapacity[role] ?? 0.0) + memberWeeklyCapacity;
        }
      }

      // Calculate allocations for this week
      for (final allocation in request.allocations) {
        if (allocation.isCancelled) continue;
        if (request.filterByRole != null && allocation.role != request.filterByRole) continue;

        if (_periodsOverlap(allocation.startDate, allocation.endDate, currentWeek, effectiveWeekEnd)) {
          final weeklyAllocationPortion = allocation.weeklyCapacityNeeded;
          weeklyAllocated[allocation.role] = (weeklyAllocated[allocation.role] ?? 0.0) + weeklyAllocationPortion;
        }
      }

      // Calculate utilization percentages for this week
      final weekUtilization = <Role, double>{};
      for (final role in weeklyCapacity.keys) {
        final capacity = weeklyCapacity[role] ?? 0.0;
        final allocated = weeklyAllocated[role] ?? 0.0;
        weekUtilization[role] = capacity == 0 ? 0.0 : (allocated / capacity) * 100;
      }

      weeklyUtilization[weekNumber] = weekUtilization;
      
      currentWeek = currentWeek.add(const Duration(days: 7));
      weekNumber++;
    }

    return weeklyUtilization;
  }

  /// Checks if two time periods overlap
  bool _periodsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  /// Gets the start of the week (Monday) for a given date
  DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return date.subtract(Duration(days: daysFromMonday));
  }
}
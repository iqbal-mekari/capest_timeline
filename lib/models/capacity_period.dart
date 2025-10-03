import 'package:equatable/equatable.dart';
import 'assignment.dart';
import 'team_member.dart';

/// Represents capacity and assignments for a specific time period
class CapacityPeriod extends Equatable {
  const CapacityPeriod({
    required this.weekStart,
    required this.weekEnd,
    required this.assignments,
    required this.totalCapacityAvailable,
    this.teamMembers = const [],
    this.utilizedCapacity = 0.0,
    this.availableCapacity = 0.0,
    this.isOverAllocated = false,
    this.conflictDetails = const [],
  });

  /// Start date of the capacity period (typically Monday)
  final DateTime weekStart;

  /// End date of the capacity period (typically Sunday)
  final DateTime weekEnd;

  /// List of assignments during this period
  final List<Assignment> assignments;

  /// Total capacity available in hours for this period
  final double totalCapacityAvailable;

  /// Team members contributing to this period's capacity
  final List<TeamMember> teamMembers;

  /// Capacity currently utilized in hours
  final double utilizedCapacity;

  /// Remaining available capacity in hours
  final double availableCapacity;

  /// Whether this period is over-allocated
  final bool isOverAllocated;

  /// Details about any capacity conflicts
  final List<String> conflictDetails;

  /// Get the calculated utilized capacity from assignments
  double get calculatedUtilizedCapacity {
    return assignments.fold(0.0, (sum, assignment) {
      if (assignment.isActiveOn(weekStart) || 
          assignment.overlapsWithRange(weekStart, weekEnd)) {
        return sum + assignment.hoursPerWeek;
      }
      return sum;
    });
  }

  /// Get the calculated available capacity
  double get calculatedAvailableCapacity {
    return (totalCapacityAvailable - calculatedUtilizedCapacity).clamp(0.0, double.infinity);
  }

  /// Check if period is over-allocated based on assignments
  bool get calculatedIsOverAllocated {
    return calculatedUtilizedCapacity > totalCapacityAvailable;
  }

  /// Get utilization percentage (0.0 to 100.0+)
  double get utilizationPercentage {
    if (totalCapacityAvailable == 0) return 0.0;
    return (calculatedUtilizedCapacity / totalCapacityAvailable) * 100;
  }

  /// Get capacity status (healthy, warning, critical, over-allocated)
  String get capacityStatus {
    final utilization = utilizationPercentage;
    if (calculatedIsOverAllocated) return 'over-allocated';
    if (utilization >= 90) return 'critical';
    if (utilization >= 75) return 'warning';
    return 'healthy';
  }

  /// Get assignments by platform type
  List<Assignment> getAssignmentsByPlatform(String platformType) {
    return assignments
        .where((assignment) => assignment.platformType.name == platformType)
        .toList();
  }

  /// Get assignments for a specific team member
  List<Assignment> getAssignmentsForMember(String memberId) {
    return assignments
        .where((assignment) => assignment.memberId == memberId)
        .toList();
  }

  /// Check if can accommodate additional hours
  bool canAccommodate(double additionalHours) {
    return (calculatedUtilizedCapacity + additionalHours) <= totalCapacityAvailable;
  }

  /// Get week number for display
  int get weekNumber {
    final jan1 = DateTime(weekStart.year, 1, 1);
    final dayOfYear = weekStart.difference(jan1).inDays;
    return ((dayOfYear + jan1.weekday - 1) / 7).ceil();
  }

  /// Get display string for the week range
  String get weekRangeDisplay {
    return '${_formatDate(weekStart)} - ${_formatDate(weekEnd)}';
  }

  /// Get short week display (e.g., "Week 12")
  String get shortWeekDisplay {
    return 'Week $weekNumber';
  }

  /// Get capacity utilization for a specific member
  double getMemberUtilization(String memberId) {
    final memberAssignments = getAssignmentsForMember(memberId);
    return memberAssignments.fold(0.0, (sum, assignment) => sum + assignment.hoursPerWeek);
  }

  /// Get total capacity for a specific platform
  double getPlatformCapacity(String platformType) {
    final platformAssignments = getAssignmentsByPlatform(platformType);
    return platformAssignments.fold(0.0, (sum, assignment) => sum + assignment.hoursPerWeek);
  }

  /// Create capacity period with recalculated values
  CapacityPeriod withRecalculatedValues() {
    return copyWith(
      utilizedCapacity: calculatedUtilizedCapacity,
      availableCapacity: calculatedAvailableCapacity,
      isOverAllocated: calculatedIsOverAllocated,
    );
  }

  /// Create a copy with modified fields
  CapacityPeriod copyWith({
    DateTime? weekStart,
    DateTime? weekEnd,
    List<Assignment>? assignments,
    double? totalCapacityAvailable,
    List<TeamMember>? teamMembers,
    double? utilizedCapacity,
    double? availableCapacity,
    bool? isOverAllocated,
    List<String>? conflictDetails,
  }) {
    return CapacityPeriod(
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      assignments: assignments ?? this.assignments,
      totalCapacityAvailable: totalCapacityAvailable ?? this.totalCapacityAvailable,
      teamMembers: teamMembers ?? this.teamMembers,
      utilizedCapacity: utilizedCapacity ?? this.utilizedCapacity,
      availableCapacity: availableCapacity ?? this.availableCapacity,
      isOverAllocated: isOverAllocated ?? this.isOverAllocated,
      conflictDetails: conflictDetails ?? this.conflictDetails,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'assignments': assignments.map((a) => a.toJson()).toList(),
      'totalCapacityAvailable': totalCapacityAvailable,
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
      'utilizedCapacity': utilizedCapacity,
      'availableCapacity': availableCapacity,
      'isOverAllocated': isOverAllocated,
      'conflictDetails': conflictDetails,
    };
  }

  /// Create from JSON map
  factory CapacityPeriod.fromJson(Map<String, dynamic> json) {
    return CapacityPeriod(
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      assignments: (json['assignments'] as List<dynamic>)
          .map((a) => Assignment.fromJson(a as Map<String, dynamic>))
          .toList(),
      totalCapacityAvailable: (json['totalCapacityAvailable'] as num).toDouble(),
      teamMembers: (json['teamMembers'] as List<dynamic>?)
          ?.map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      utilizedCapacity: (json['utilizedCapacity'] as num?)?.toDouble() ?? 0.0,
      availableCapacity: (json['availableCapacity'] as num?)?.toDouble() ?? 0.0,
      isOverAllocated: json['isOverAllocated'] as bool? ?? false,
      conflictDetails: (json['conflictDetails'] as List<dynamic>?)
          ?.map((c) => c as String)
          .toList() ?? [],
    );
  }

  /// Factory for creating empty capacity period
  factory CapacityPeriod.empty({
    required DateTime weekStart,
    required DateTime weekEnd,
  }) {
    return CapacityPeriod(
      weekStart: weekStart,
      weekEnd: weekEnd,
      assignments: [],
      totalCapacityAvailable: 0.0,
    );
  }

  /// Factory for creating capacity period from team members
  factory CapacityPeriod.fromTeamMembers({
    required DateTime weekStart,
    required DateTime weekEnd,
    required List<TeamMember> teamMembers,
    List<Assignment>? assignments,
  }) {
    final activeMembers = teamMembers.where((m) => m.isActive).toList();
    final totalCapacity = activeMembers
        .fold(0.0, (sum, member) => sum + member.weeklyCapacity * 40); // 40 hours per week

    final period = CapacityPeriod(
      weekStart: weekStart,
      weekEnd: weekEnd,
      assignments: assignments ?? [],
      totalCapacityAvailable: totalCapacity,
      teamMembers: activeMembers,
    );

    return period.withRecalculatedValues();
  }

  /// Helper method to format dates
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  /// Validate capacity period
  String? validate() {
    if (weekEnd.isBefore(weekStart)) {
      return 'Week end cannot be before week start';
    }
    if (totalCapacityAvailable < 0) {
      return 'Total capacity cannot be negative';
    }
    if (utilizedCapacity < 0) {
      return 'Utilized capacity cannot be negative';
    }

    for (final assignment in assignments) {
      final validation = assignment.validate();
      if (validation != null) {
        return 'Assignment validation failed: $validation';
      }
    }

    return null;
  }

  @override
  List<Object?> get props => [
        weekStart,
        weekEnd,
        assignments,
        totalCapacityAvailable,
        teamMembers,
        utilizedCapacity,
        availableCapacity,
        isOverAllocated,
        conflictDetails,
      ];

  @override
  String toString() {
    return 'CapacityPeriod(week: $shortWeekDisplay, '
        'utilization: ${utilizationPercentage.toStringAsFixed(1)}%, '
        'assignments: ${assignments.length}, '
        'status: $capacityStatus)';
  }
}
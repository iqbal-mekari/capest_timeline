import 'package:equatable/equatable.dart';
import 'team_member.dart';

/// Represents capacity data for a specific time period
class CapacityData extends Equatable {
  const CapacityData({
    required this.totalCapacity,
    required this.usedCapacity,
    required this.availableCapacity,
    required this.utilizationPercentage,
    required this.isOverAllocated,
    required this.weekDate,
    this.teamMembers = const [],
    this.previousWeekUtilization,
    this.isEditable = false,
    this.notes,
  });

  /// Total capacity in hours for the period
  final double totalCapacity;

  /// Currently used capacity in hours
  final double usedCapacity;

  /// Available capacity in hours
  final double availableCapacity;

  /// Utilization percentage (0-100+)
  final double utilizationPercentage;

  /// Whether the capacity is over-allocated
  final bool isOverAllocated;

  /// The date this capacity data represents
  final DateTime weekDate;

  /// Team members contributing to this capacity
  final List<TeamMember> teamMembers;

  /// Previous week's utilization for trend analysis
  final double? previousWeekUtilization;

  /// Whether this capacity data can be edited
  final bool isEditable;

  /// Optional notes about capacity constraints
  final String? notes;

  /// Get capacity utilization level (normal, warning, critical)
  String get utilizationLevel {
    if (utilizationPercentage <= 75) return 'normal';
    if (utilizationPercentage <= 90) return 'warning';
    return 'critical';
  }

  /// Get trend direction compared to previous week
  String? get trendDirection {
    if (previousWeekUtilization == null) return null;
    final diff = utilizationPercentage - previousWeekUtilization!;
    if (diff > 5) return 'up';
    if (diff < -5) return 'down';
    return 'stable';
  }

  /// Get trend percentage change
  double? get trendPercentageChange {
    if (previousWeekUtilization == null || previousWeekUtilization == 0) return null;
    return utilizationPercentage - previousWeekUtilization!;
  }

  /// Get over-allocation amount in hours
  double get overAllocationHours {
    return isOverAllocated ? usedCapacity - totalCapacity : 0.0;
  }

  /// Check if capacity is near limit (within threshold)
  bool isNearCapacity({double threshold = 90.0}) {
    return utilizationPercentage >= threshold && !isOverAllocated;
  }

  /// Get capacity buffer in hours
  double get capacityBuffer {
    return isOverAllocated ? 0.0 : availableCapacity;
  }

  /// Calculate capacity with additional hours
  CapacityData withAdditionalHours(double additionalHours) {
    final newUsedCapacity = usedCapacity + additionalHours;
    final newAvailableCapacity = totalCapacity - newUsedCapacity;
    final newUtilizationPercentage = totalCapacity > 0 
        ? (newUsedCapacity / totalCapacity) * 100 
        : 0.0;
    final newIsOverAllocated = newUsedCapacity > totalCapacity;

    return copyWith(
      usedCapacity: newUsedCapacity,
      availableCapacity: newAvailableCapacity,
      utilizationPercentage: newUtilizationPercentage,
      isOverAllocated: newIsOverAllocated,
    );
  }

  /// Check if can accommodate additional hours
  bool canAccommodate(double additionalHours) {
    return (usedCapacity + additionalHours) <= totalCapacity;
  }

  /// Get formatted capacity string for display
  String get capacityDisplayString {
    return '${usedCapacity.toStringAsFixed(0)}/${totalCapacity.toStringAsFixed(0)} hours';
  }

  /// Get formatted utilization string
  String get utilizationDisplayString {
    return '${utilizationPercentage.toStringAsFixed(0)}%';
  }

  /// Create a copy with modified fields
  CapacityData copyWith({
    double? totalCapacity,
    double? usedCapacity,
    double? availableCapacity,
    double? utilizationPercentage,
    bool? isOverAllocated,
    DateTime? weekDate,
    List<TeamMember>? teamMembers,
    double? previousWeekUtilization,
    bool? isEditable,
    String? notes,
  }) {
    return CapacityData(
      totalCapacity: totalCapacity ?? this.totalCapacity,
      usedCapacity: usedCapacity ?? this.usedCapacity,
      availableCapacity: availableCapacity ?? this.availableCapacity,
      utilizationPercentage: utilizationPercentage ?? this.utilizationPercentage,
      isOverAllocated: isOverAllocated ?? this.isOverAllocated,
      weekDate: weekDate ?? this.weekDate,
      teamMembers: teamMembers ?? this.teamMembers,
      previousWeekUtilization: previousWeekUtilization ?? this.previousWeekUtilization,
      isEditable: isEditable ?? this.isEditable,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'totalCapacity': totalCapacity,
      'usedCapacity': usedCapacity,
      'availableCapacity': availableCapacity,
      'utilizationPercentage': utilizationPercentage,
      'isOverAllocated': isOverAllocated,
      'weekDate': weekDate.toIso8601String(),
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
      'previousWeekUtilization': previousWeekUtilization,
      'isEditable': isEditable,
      'notes': notes,
    };
  }

  /// Create from JSON map
  factory CapacityData.fromJson(Map<String, dynamic> json) {
    return CapacityData(
      totalCapacity: (json['totalCapacity'] as num).toDouble(),
      usedCapacity: (json['usedCapacity'] as num).toDouble(),
      availableCapacity: (json['availableCapacity'] as num).toDouble(),
      utilizationPercentage: (json['utilizationPercentage'] as num).toDouble(),
      isOverAllocated: json['isOverAllocated'] as bool,
      weekDate: DateTime.parse(json['weekDate'] as String),
      teamMembers: (json['teamMembers'] as List<dynamic>?)
          ?.map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
      previousWeekUtilization: json['previousWeekUtilization'] as double?,
      isEditable: json['isEditable'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  /// Factory for creating empty capacity data
  factory CapacityData.empty(DateTime weekDate) {
    return CapacityData(
      totalCapacity: 0.0,
      usedCapacity: 0.0,
      availableCapacity: 0.0,
      utilizationPercentage: 0.0,
      isOverAllocated: false,
      weekDate: weekDate,
    );
  }

  /// Factory for creating capacity data from team members
  factory CapacityData.fromTeamMembers({
    required List<TeamMember> teamMembers,
    required DateTime weekDate,
    double usedCapacity = 0.0,
    double? previousWeekUtilization,
    String? notes,
  }) {
    final totalCapacity = teamMembers
        .where((m) => m.isActive)
        .fold(0.0, (sum, member) => sum + member.weeklyCapacity);
    
    final availableCapacity = totalCapacity - usedCapacity;
    final utilizationPercentage = totalCapacity > 0 
        ? (usedCapacity / totalCapacity) * 100 
        : 0.0;
    final isOverAllocated = usedCapacity > totalCapacity;

    return CapacityData(
      totalCapacity: totalCapacity,
      usedCapacity: usedCapacity,
      availableCapacity: availableCapacity,
      utilizationPercentage: utilizationPercentage,
      isOverAllocated: isOverAllocated,
      weekDate: weekDate,
      teamMembers: teamMembers,
      previousWeekUtilization: previousWeekUtilization,
      notes: notes,
    );
  }

  /// Validate capacity data
  String? validate() {
    if (totalCapacity < 0) return 'Total capacity cannot be negative';
    if (usedCapacity < 0) return 'Used capacity cannot be negative';
    if (utilizationPercentage < 0) return 'Utilization percentage cannot be negative';
    if (totalCapacity > 0 && availableCapacity != totalCapacity - usedCapacity) {
      return 'Available capacity calculation is incorrect';
    }
    if (totalCapacity > 0) {
      final expectedUtilization = (usedCapacity / totalCapacity) * 100;
      if ((utilizationPercentage - expectedUtilization).abs() > 0.1) {
        return 'Utilization percentage calculation is incorrect';
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        totalCapacity,
        usedCapacity,
        availableCapacity,
        utilizationPercentage,
        isOverAllocated,
        weekDate,
        teamMembers,
        previousWeekUtilization,
        isEditable,
        notes,
      ];

  @override
  String toString() {
    return 'CapacityData(weekDate: $weekDate, utilization: ${utilizationPercentage.toStringAsFixed(1)}%, '
        'used: ${usedCapacity.toStringAsFixed(1)}/${totalCapacity.toStringAsFixed(1)} hours, '
        'overAllocated: $isOverAllocated)';
  }
}
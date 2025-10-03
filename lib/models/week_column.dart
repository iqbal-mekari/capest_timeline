import 'package:equatable/equatable.dart';
import 'initiative.dart';
import 'capacity_data.dart';

/// Represents a week column in the Kanban board
class WeekColumn extends Equatable {
  const WeekColumn({
    required this.weekNumber,
    required this.weekDate,
    required this.initiatives,
    required this.capacityData,
    this.isCurrentWeek = false,
    this.isEditable = true,
    this.notes,
  });

  /// Week number in the year (1-53)
  final int weekNumber;

  /// Start date of the week (Monday)
  final DateTime weekDate;

  /// Initiatives scheduled for this week
  final List<Initiative> initiatives;

  /// Capacity data for this week
  final CapacityData capacityData;

  /// Whether this is the current week
  final bool isCurrentWeek;

  /// Whether this week can be edited
  final bool isEditable;

  /// Optional notes for this week
  final String? notes;

  /// Get the end date of the week (Sunday)
  DateTime get weekEndDate {
    return weekDate.add(const Duration(days: 6));
  }

  /// Get formatted week range string
  String get weekRangeString {
    final startMonth = weekDate.month;
    final endMonth = weekEndDate.month;
    final startDay = weekDate.day;
    final endDay = weekEndDate.day;
    
    if (startMonth == endMonth) {
      return 'Week $weekNumber: ${_getMonthName(startMonth)} $startDay-$endDay';
    } else {
      return 'Week $weekNumber: ${_getMonthName(startMonth)} $startDay - ${_getMonthName(endMonth)} $endDay';
    }
  }

  /// Get display title for the week
  String get displayTitle {
    return 'Week $weekNumber';
  }

  /// Get short date range (e.g., "Mar 6-12")
  String get shortDateRange {
    final startMonth = _getMonthAbbr(weekDate.month);
    final endMonth = _getMonthAbbr(weekEndDate.month);
    final startDay = weekDate.day;
    final endDay = weekEndDate.day;
    
    if (weekDate.month == weekEndDate.month) {
      return '$startMonth $startDay-$endDay';
    } else {
      return '$startMonth $startDay - $endMonth $endDay';
    }
  }

  /// Get total hours scheduled for this week
  double get totalScheduledHours {
    return initiatives
        .where((i) => i.isActive)
        .fold(0.0, (sum, initiative) => sum + initiative.totalEffortHours);
  }

  /// Get initiatives by platform
  List<Initiative> getInitiativesByPlatform(String platformType) {
    return initiatives
        .where((i) => i.variants.any((v) => v.platformType == platformType))
        .toList();
  }

  /// Get overdue initiatives (past due date)
  List<Initiative> get overdueInitiatives {
    final now = DateTime.now();
    return initiatives
        .where((i) => i.dueDate != null && i.dueDate!.isBefore(now) && !i.isCompleted)
        .toList();
  }

  /// Get completed initiatives
  List<Initiative> get completedInitiatives {
    return initiatives.where((i) => i.isCompleted).toList();
  }

  /// Get in-progress initiatives
  List<Initiative> get inProgressInitiatives {
    return initiatives
        .where((i) => i.isInProgress && !i.isCompleted)
        .toList();
  }

  /// Get not started initiatives
  List<Initiative> get notStartedInitiatives {
    return initiatives
        .where((i) => !i.isInProgress && !i.isCompleted)
        .toList();
  }

  /// Check if week is overloaded
  bool get isOverloaded {
    return capacityData.isOverAllocated;
  }

  /// Get capacity utilization percentage
  double get utilizationPercentage {
    return capacityData.utilizationPercentage;
  }

  /// Get available hours
  double get availableHours {
    return capacityData.availableCapacity;
  }

  /// Check if can accommodate initiative
  bool canAccommodateInitiative(Initiative initiative) {
    return capacityData.canAccommodate(initiative.totalEffortHours);
  }

  /// Get visual indicator for capacity status
  String get capacityStatusIndicator {
    if (isOverloaded) return '🔴';
    if (capacityData.isNearCapacity()) return '🟡';
    return '🟢';
  }

  /// Get week status summary
  String get statusSummary {
    final completedCount = completedInitiatives.length;
    final totalCount = initiatives.length;
    final overdueCount = overdueInitiatives.length;
    
    String status = '$completedCount/$totalCount completed';
    if (overdueCount > 0) {
      status += ', $overdueCount overdue';
    }
    if (isOverloaded) {
      status += ', overloaded';
    }
    return status;
  }

  /// Check if week is in the past
  bool get isPastWeek {
    final now = DateTime.now();
    return weekEndDate.isBefore(now);
  }

  /// Check if week is in the future
  bool get isFutureWeek {
    final now = DateTime.now();
    return weekDate.isAfter(now);
  }

  /// Get completion percentage
  double get completionPercentage {
    if (initiatives.isEmpty) return 0.0;
    final completedCount = completedInitiatives.length;
    return (completedCount / initiatives.length) * 100;
  }

  /// Add initiative to this week
  WeekColumn addInitiative(Initiative initiative) {
    final updatedInitiatives = List<Initiative>.from(initiatives)
      ..add(initiative);
    
    final updatedCapacityData = capacityData.withAdditionalHours(
      initiative.totalEffortHours,
    );

    return copyWith(
      initiatives: updatedInitiatives,
      capacityData: updatedCapacityData,
    );
  }

  /// Remove initiative from this week
  WeekColumn removeInitiative(String initiativeId) {
    final initiativeToRemove = initiatives.firstWhere(
      (i) => i.id == initiativeId,
      orElse: () => throw ArgumentError('Initiative not found: $initiativeId'),
    );

    final updatedInitiatives = initiatives
        .where((i) => i.id != initiativeId)
        .toList();

    final updatedCapacityData = capacityData.withAdditionalHours(
      -initiativeToRemove.totalEffortHours,
    );

    return copyWith(
      initiatives: updatedInitiatives,
      capacityData: updatedCapacityData,
    );
  }

  /// Update initiative in this week
  WeekColumn updateInitiative(Initiative updatedInitiative) {
    final index = initiatives.indexWhere((i) => i.id == updatedInitiative.id);
    if (index == -1) {
      throw ArgumentError('Initiative not found: ${updatedInitiative.id}');
    }

    final oldInitiative = initiatives[index];
    final hoursDifference = updatedInitiative.totalEffortHours - oldInitiative.totalEffortHours;

    final updatedInitiatives = List<Initiative>.from(initiatives);
    updatedInitiatives[index] = updatedInitiative;

    final updatedCapacityData = capacityData.withAdditionalHours(hoursDifference);

    return copyWith(
      initiatives: updatedInitiatives,
      capacityData: updatedCapacityData,
    );
  }

  /// Create a copy with modified fields
  WeekColumn copyWith({
    int? weekNumber,
    DateTime? weekDate,
    List<Initiative>? initiatives,
    CapacityData? capacityData,
    bool? isCurrentWeek,
    bool? isEditable,
    String? notes,
  }) {
    return WeekColumn(
      weekNumber: weekNumber ?? this.weekNumber,
      weekDate: weekDate ?? this.weekDate,
      initiatives: initiatives ?? this.initiatives,
      capacityData: capacityData ?? this.capacityData,
      isCurrentWeek: isCurrentWeek ?? this.isCurrentWeek,
      isEditable: isEditable ?? this.isEditable,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'weekNumber': weekNumber,
      'weekDate': weekDate.toIso8601String(),
      'initiatives': initiatives.map((i) => i.toJson()).toList(),
      'capacityData': capacityData.toJson(),
      'isCurrentWeek': isCurrentWeek,
      'isEditable': isEditable,
      'notes': notes,
    };
  }

  /// Create from JSON map
  factory WeekColumn.fromJson(Map<String, dynamic> json) {
    return WeekColumn(
      weekNumber: json['weekNumber'] as int,
      weekDate: DateTime.parse(json['weekDate'] as String),
      initiatives: (json['initiatives'] as List<dynamic>)
          .map((i) => Initiative.fromJson(i as Map<String, dynamic>))
          .toList(),
      capacityData: CapacityData.fromJson(json['capacityData'] as Map<String, dynamic>),
      isCurrentWeek: json['isCurrentWeek'] as bool? ?? false,
      isEditable: json['isEditable'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  /// Factory for creating empty week column
  factory WeekColumn.empty({
    required int weekNumber,
    required DateTime weekDate,
    CapacityData? capacityData,
  }) {
    return WeekColumn(
      weekNumber: weekNumber,
      weekDate: weekDate,
      initiatives: [],
      capacityData: capacityData ?? CapacityData.empty(weekDate),
    );
  }

  /// Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  /// Helper method to get month abbreviation
  String _getMonthAbbr(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  /// Validate week column
  String? validate() {
    if (weekNumber < 1 || weekNumber > 53) {
      return 'Week number must be between 1 and 53';
    }
    
    if (weekDate.weekday != DateTime.monday) {
      return 'Week date must be a Monday';
    }

    final capacityValidation = capacityData.validate();
    if (capacityValidation != null) {
      return 'Capacity data validation failed: $capacityValidation';
    }

    for (final initiative in initiatives) {
      final validation = initiative.validate();
      if (validation != null) {
        return 'Initiative validation failed: $validation';
      }
    }

    return null;
  }

  @override
  List<Object?> get props => [
        weekNumber,
        weekDate,
        initiatives,
        capacityData,
        isCurrentWeek,
        isEditable,
        notes,
      ];

  @override
  String toString() {
    return 'WeekColumn(weekNumber: $weekNumber, weekDate: $weekDate, '
        'initiatives: ${initiatives.length}, utilization: ${utilizationPercentage.toStringAsFixed(1)}%)';
  }
}
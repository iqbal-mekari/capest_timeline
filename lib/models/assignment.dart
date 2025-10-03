import 'package:equatable/equatable.dart';
import 'platform_type.dart';

/// Represents an assignment of a team member to work on a specific platform initiative
class Assignment extends Equatable {
  Assignment({
    required this.id,
    required this.memberId,
    required this.platformType,
    required this.allocatedWeeks,
    required this.capacityPercentage,
    required this.startWeek,
    this.endWeek,
    this.initiativeId,
    this.variantId,
    this.notes,
    this.actualHours = 0.0,
    this.isCompleted = false,
    this.completionDate,
  }) {
    if (allocatedWeeks <= 0) {
      throw ArgumentError('Allocated weeks must be positive');
    }
    if (capacityPercentage <= 0.0) {
      throw ArgumentError('Capacity percentage must be greater than 0.0');
    }
    if (id.isEmpty) {
      throw ArgumentError('Assignment ID cannot be empty');
    }
    if (memberId.isEmpty) {
      throw ArgumentError('Member ID cannot be empty');
    }
    if (actualHours < 0) {
      throw ArgumentError('Actual hours cannot be negative');
    }
  }

  /// Unique identifier for the assignment
  final String id;

  /// ID of the team member assigned
  final String memberId;

  /// Platform type for this assignment
  final PlatformType platformType;

  /// Number of weeks allocated for this assignment
  final double allocatedWeeks;

  /// Percentage of member's weekly capacity allocated (0.0 to 1.0)
  final double capacityPercentage;

  /// Start week date for the assignment
  final DateTime startWeek;

  /// End week date for the assignment (calculated if not provided)
  final DateTime? endWeek;

  /// Optional initiative ID this assignment belongs to
  final String? initiativeId;

  /// Optional platform variant ID this assignment belongs to
  final String? variantId;

  /// Optional notes about the assignment
  final String? notes;

  /// Actual hours worked (for tracking purposes)
  final double actualHours;

  /// Whether the assignment is completed
  final bool isCompleted;

  /// Date when assignment was completed
  final DateTime? completionDate;

  /// Get the calculated end week if not explicitly set
  DateTime get calculatedEndWeek {
    if (endWeek != null) return endWeek!;
    return startWeek.add(Duration(days: (allocatedWeeks * 7).round()));
  }

  /// Get total allocated hours based on capacity percentage and weeks
  double get totalAllocatedHours {
    // Assuming 40 hours per week as standard capacity
    const standardWeeklyHours = 40.0;
    return allocatedWeeks * capacityPercentage * standardWeeklyHours;
  }

  /// Calculate total effort hours for this assignment (alias for test compatibility)
  double calculateTotalEffortHours({double hoursPerWeek = 40.0}) {
    return allocatedWeeks * capacityPercentage * hoursPerWeek;
  }

  /// Get hours per week for this assignment
  double get hoursPerWeek {
    const standardWeeklyHours = 40.0;
    return capacityPercentage * standardWeeklyHours;
  }

  /// Check if assignment is active for a given date
  bool isActiveOn(DateTime date) {
    final assignmentStart = startWeek;
    final assignmentEnd = calculatedEndWeek;
    return date.isAtSameMomentAs(assignmentStart) ||
        date.isAtSameMomentAs(assignmentEnd) ||
        (date.isAfter(assignmentStart) && date.isBefore(assignmentEnd));
  }

  /// Check if assignment overlaps with a date range
  bool overlapsWithRange(DateTime rangeStart, DateTime rangeEnd) {
    final assignmentStart = startWeek;
    final assignmentEnd = calculatedEndWeek;
    
    return assignmentStart.isBefore(rangeEnd) && assignmentEnd.isAfter(rangeStart);
  }

  /// Calculate end week (alias for calculatedEndWeek getter for test compatibility)
  DateTime calculateEndWeek() {
    return calculatedEndWeek;
  }

  /// Check if assignment overlaps with a date range (alias for overlapsWithRange)
  bool overlapsWith(DateTime rangeStart, DateTime rangeEnd) {
    return overlapsWithRange(rangeStart, rangeEnd);
  }

  /// Check if assignment is active during a specific date (alias for isActiveOn)
  bool isActiveDuring(DateTime date) {
    return isActiveOn(date);
  }

  /// Check if assignment is compatible with a team member based on platform specializations
  bool isMemberCompatible(dynamic member) {
    // Handle both old enum-based and new string-based specializations
    if (member.platformSpecializations is List<String>) {
      final memberSpecializations = member.platformSpecializations as List<String>;
      final platformString = platformType.name;
      return memberSpecializations.contains(platformString);
    }
    
    // For backward compatibility with enum-based tests
    if (member.platformSpecializations is List) {
      final memberSpecializations = member.platformSpecializations as List;
      return memberSpecializations.contains(platformType);
    }
    
    return false;
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalAllocatedHours == 0) return 0.0;
    return (actualHours / totalAllocatedHours).clamp(0.0, 1.0);
  }

  /// Check if assignment is overdue
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    return now.isAfter(calculatedEndWeek);
  }

  /// Get remaining hours
  double get remainingHours {
    return (totalAllocatedHours - actualHours).clamp(0.0, double.infinity);
  }

  /// Get status string
  String get status {
    if (isCompleted) return 'Completed';
    if (isOverdue) return 'Overdue';
    
    final now = DateTime.now();
    if (now.isBefore(startWeek)) return 'Scheduled';
    if (isActiveOn(now)) return 'In Progress';
    
    return 'Not Started';
  }

  /// Create a copy with modified fields
  Assignment copyWith({
    String? id,
    String? memberId,
    PlatformType? platformType,
    double? allocatedWeeks,
    double? capacityPercentage,
    DateTime? startWeek,
    DateTime? endWeek,
    String? initiativeId,
    String? variantId,
    String? notes,
    double? actualHours,
    bool? isCompleted,
    DateTime? completionDate,
  }) {
    return Assignment(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      platformType: platformType ?? this.platformType,
      allocatedWeeks: allocatedWeeks ?? this.allocatedWeeks,
      capacityPercentage: capacityPercentage ?? this.capacityPercentage,
      startWeek: startWeek ?? this.startWeek,
      endWeek: endWeek ?? this.endWeek,
      initiativeId: initiativeId ?? this.initiativeId,
      variantId: variantId ?? this.variantId,
      notes: notes ?? this.notes,
      actualHours: actualHours ?? this.actualHours,
      isCompleted: isCompleted ?? this.isCompleted,
      completionDate: completionDate ?? this.completionDate,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'platformType': platformType.name,
      'allocatedWeeks': allocatedWeeks,
      'capacityPercentage': capacityPercentage,
      'startWeek': startWeek.toIso8601String(),
      'endWeek': endWeek?.toIso8601String(),
      'initiativeId': initiativeId,
      'variantId': variantId,
      'notes': notes,
      'actualHours': actualHours,
      'isCompleted': isCompleted,
      'completionDate': completionDate?.toIso8601String(),
    };
  }

  /// Create from JSON map
  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'] as String,
      memberId: json['memberId'] as String,
      platformType: PlatformType.values.firstWhere(
        (e) => e.name == json['platformType'],
      ),
      allocatedWeeks: (json['allocatedWeeks'] as num).toDouble(),
      capacityPercentage: (json['capacityPercentage'] as num).toDouble(),
      startWeek: DateTime.parse(json['startWeek'] as String),
      endWeek: json['endWeek'] != null 
          ? DateTime.parse(json['endWeek'] as String) 
          : null,
      initiativeId: json['initiativeId'] as String?,
      variantId: json['variantId'] as String?,
      notes: json['notes'] as String?,
      actualHours: (json['actualHours'] as num?)?.toDouble() ?? 0.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completionDate: json['completionDate'] != null 
          ? DateTime.parse(json['completionDate'] as String) 
          : null,
    );
  }

  /// Validate assignment data
  String? validate() {
    if (id.isEmpty) return 'Assignment ID cannot be empty';
    if (memberId.isEmpty) return 'Member ID cannot be empty';
    if (allocatedWeeks <= 0) return 'Allocated weeks must be positive';
    if (capacityPercentage < 0 || capacityPercentage > 1) {
      return 'Capacity percentage must be between 0 and 1';
    }
    if (actualHours < 0) return 'Actual hours cannot be negative';
    if (endWeek != null && endWeek!.isBefore(startWeek)) {
      return 'End week cannot be before start week';
    }
    if (isCompleted && completionDate == null) {
      return 'Completion date required when assignment is completed';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        memberId,
        platformType,
        allocatedWeeks,
        capacityPercentage,
        startWeek,
        endWeek,
        initiativeId,
        variantId,
        notes,
        actualHours,
        isCompleted,
        completionDate,
      ];

  @override
  String toString() {
    return 'Assignment(id: $id, memberId: $memberId, platformType: $platformType, '
        'weeks: $allocatedWeeks, capacity: ${(capacityPercentage * 100).toStringAsFixed(0)}%, '
        'status: $status)';
  }
}
import 'package:equatable/equatable.dart';

import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Represents the allocation of a team member's capacity to an initiative.
/// 
/// A CapacityAllocation tracks:
/// - Which team member is allocated
/// - To which initiative
/// - In what role
/// - For how much capacity (effort weeks)
/// - During which time period
/// - Current status of the allocation
class CapacityAllocation extends Equatable {
  const CapacityAllocation({
    required this.id,
    required this.teamMemberId,
    required this.initiativeId,
    required this.role,
    required this.allocatedWeeks,
    required this.startDate,
    required this.endDate,
    this.status = AllocationStatus.planned,
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for this allocation
  final String id;

  /// ID of the team member being allocated
  final String teamMemberId;

  /// ID of the initiative receiving the allocation
  final String initiativeId;

  /// Role in which the team member is allocated
  final Role role;

  /// Amount of capacity allocated in person-weeks
  final double allocatedWeeks;

  /// When this allocation starts
  final DateTime startDate;

  /// When this allocation ends
  final DateTime endDate;

  /// Current status of this allocation
  final AllocationStatus status;

  /// Optional notes about this allocation
  final String notes;

  /// When this allocation was created
  final DateTime? createdAt;

  /// When this allocation was last updated
  final DateTime? updatedAt;

  /// Calculates the duration of this allocation in days
  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Calculates the duration of this allocation in weeks
  double get durationInWeeks => durationInDays / 7.0;

  /// Calculates weekly capacity utilization
  /// (allocated weeks divided by duration weeks)
  double get weeklyUtilization => allocatedWeeks / durationInWeeks;

  /// Determines if this allocation is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && 
           now.isBefore(endDate) && 
           status == AllocationStatus.inProgress;
  }

  /// Determines if this allocation is completed
  bool get isCompleted => status == AllocationStatus.completed;

  /// Determines if this allocation is planned (not started yet)
  bool get isPlanned => status == AllocationStatus.planned;

  /// Determines if this allocation has been cancelled
  bool get isCancelled => status == AllocationStatus.cancelled;

  /// Determines if this allocation is overcommitted (> 100% utilization)
  bool get isOvercommitted => weeklyUtilization > 1.0;

  /// Determines if this allocation spans multiple quarters
  bool get isMultiQuarter {
    // Simple quarter calculation based on calendar quarters
    final startQuarter = (startDate.month - 1) ~/ 3;
    final endQuarter = (endDate.month - 1) ~/ 3;
    return startQuarter != endQuarter || startDate.year != endDate.year;
  }

  /// Gets the capacity needed per week for this allocation
  double get weeklyCapacityNeeded => allocatedWeeks / durationInWeeks;

  /// Calculates progress percentage based on elapsed time and status
  double get progressPercentage {
    switch (status) {
      case AllocationStatus.planned:
        return 0.0;
      case AllocationStatus.completed:
        return 100.0;
      case AllocationStatus.cancelled:
        return 0.0;
      case AllocationStatus.inProgress:
        final now = DateTime.now();
        if (now.isBefore(startDate)) return 0.0;
        if (now.isAfter(endDate)) return 100.0;
        
        final totalDuration = endDate.difference(startDate).inDays;
        final elapsedDuration = now.difference(startDate).inDays;
        return (elapsedDuration / totalDuration * 100).clamp(0.0, 100.0);
    }
  }

  /// Validates the allocation data
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    // Basic field validation
    if (id.trim().isEmpty) {
      errors.add('Allocation ID cannot be empty');
    }

    if (teamMemberId.trim().isEmpty) {
      errors.add('Team member ID cannot be empty');
    }

    if (initiativeId.trim().isEmpty) {
      errors.add('Initiative ID cannot be empty');
    }

    // Date validation
    if (startDate.isAfter(endDate)) {
      errors.add('Start date must be before or equal to end date');
    }

    // Allocated weeks validation
    if (allocatedWeeks <= 0) {
      errors.add('Allocated weeks must be positive');
    }

    // Check for reasonable allocation limits
    if (allocatedWeeks > 52) {
      errors.add('Allocated weeks cannot exceed 52 (one year)');
    }

    // Weekly utilization check
    if (weeklyUtilization > 1.5) {
      errors.add(
        'Weekly utilization (${weeklyUtilization.toStringAsFixed(2)}) '
        'exceeds reasonable limits (>150%)',
      );
    }

    // Duration sanity check
    final maxReasonableDuration = 26 * 7; // 26 weeks in days
    if (durationInDays > maxReasonableDuration) {
      errors.add('Allocation duration cannot exceed 26 weeks');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Capacity allocation validation failed',
          ValidationErrorType.businessRuleViolation,
          {'capacityAllocation': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  /// Creates a copy of this allocation with updated fields
  CapacityAllocation copyWith({
    String? id,
    String? teamMemberId,
    String? initiativeId,
    Role? role,
    double? allocatedWeeks,
    DateTime? startDate,
    DateTime? endDate,
    AllocationStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CapacityAllocation(
      id: id ?? this.id,
      teamMemberId: teamMemberId ?? this.teamMemberId,
      initiativeId: initiativeId ?? this.initiativeId,
      role: role ?? this.role,
      allocatedWeeks: allocatedWeeks ?? this.allocatedWeeks,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a CapacityAllocation from a Map (for serialization)
  factory CapacityAllocation.fromMap(Map<String, dynamic> map) {
    return CapacityAllocation(
      id: map['id'] as String,
      teamMemberId: map['teamMemberId'] as String,
      initiativeId: map['initiativeId'] as String,
      role: Role.values.firstWhere((r) => r.name == map['role']),
      allocatedWeeks: (map['allocatedWeeks'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      status: AllocationStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => AllocationStatus.planned,
      ),
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this CapacityAllocation to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamMemberId': teamMemberId,
      'initiativeId': initiativeId,
      'role': role.name,
      'allocatedWeeks': allocatedWeeks,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        teamMemberId,
        initiativeId,
        role,
        allocatedWeeks,
        startDate,
        endDate,
        status,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'CapacityAllocation('
        'id: $id, '
        'member: $teamMemberId, '
        'initiative: $initiativeId, '
        'role: ${role.displayName}, '
        'weeks: $allocatedWeeks, '
        'status: ${status.displayName}'
        ')';
  }
}

/// Status of a capacity allocation
enum AllocationStatus {
  /// Allocation is planned but not yet started
  planned('Planned'),
  
  /// Allocation is currently in progress
  inProgress('In Progress'),
  
  /// Allocation has been completed
  completed('Completed'),
  
  /// Allocation has been cancelled
  cancelled('Cancelled');

  const AllocationStatus(this.displayName);

  /// Human-readable display name
  final String displayName;

  /// Check if this status represents an active allocation
  bool get isActive => this == AllocationStatus.inProgress;

  /// Check if this status represents a finished allocation
  bool get isFinished => 
      this == AllocationStatus.completed || 
      this == AllocationStatus.cancelled;

  /// Check if this allocation can be modified
  bool get canBeModified => 
      this == AllocationStatus.planned || 
      this == AllocationStatus.inProgress;

  /// Get color indicator for UI display
  String get colorIndicator {
    switch (this) {
      case AllocationStatus.planned:
        return 'blue';
      case AllocationStatus.inProgress:
        return 'green';
      case AllocationStatus.completed:
        return 'gray';
      case AllocationStatus.cancelled:
        return 'red';
    }
  }
}
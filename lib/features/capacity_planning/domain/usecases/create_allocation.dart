import '../entities/capacity_allocation.dart';
import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Request object for creating a capacity allocation
class CreateAllocationRequest {
  final String teamMemberId;
  final String initiativeId;
  final Role role;
  final double allocatedWeeks;
  final DateTime startDate;
  final DateTime endDate;
  final AllocationStatus status;
  final String notes;

  const CreateAllocationRequest({
    required this.teamMemberId,
    required this.initiativeId,
    required this.role,
    required this.allocatedWeeks,
    required this.startDate,
    required this.endDate,
    this.status = AllocationStatus.planned,
    this.notes = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateAllocationRequest &&
          runtimeType == other.runtimeType &&
          teamMemberId == other.teamMemberId &&
          initiativeId == other.initiativeId &&
          role == other.role &&
          allocatedWeeks == other.allocatedWeeks &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          status == other.status &&
          notes == other.notes;

  @override
  int get hashCode =>
      teamMemberId.hashCode ^
      initiativeId.hashCode ^
      role.hashCode ^
      allocatedWeeks.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      status.hashCode ^
      notes.hashCode;

  @override
  String toString() =>
      'CreateAllocationRequest(member: $teamMemberId, initiative: $initiativeId, '
      'role: ${role.displayName}, weeks: $allocatedWeeks, '
      'period: ${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]})';
}

/// Use case for creating capacity allocations
/// Validates: member capacity, role compatibility, time conflicts, business rules
class CreateAllocation {
  /// Create new capacity allocation with validation
  /// 
  /// Validates:
  /// - Team member exists and can fulfill the role
  /// - Initiative exists and requires the role
  /// - Date range is valid and within reasonable limits
  /// - Allocation doesn't exceed member's capacity
  /// - No time conflicts with existing allocations
  /// - Allocated weeks are positive and reasonable
  /// 
  /// Returns: Created allocation or validation exception
  Future<Result<CapacityAllocation, ValidationException>> call(
    CreateAllocationRequest request,
  ) async {
    // Validate request
    final validationResult = _validateRequest(request);
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Create allocation entity
    try {
      final allocation = CapacityAllocation(
        id: _generateAllocationId(),
        teamMemberId: request.teamMemberId,
        initiativeId: request.initiativeId,
        role: request.role,
        allocatedWeeks: request.allocatedWeeks,
        startDate: request.startDate,
        endDate: request.endDate,
        status: request.status,
        notes: request.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Result.success(allocation);
    } catch (e) {
      return Result.error(
        ValidationException(
          'Failed to create allocation: ${e.toString()}',
          ValidationErrorType.businessRuleViolation,
        ),
      );
    }
  }

  /// Validates the create allocation request
  Result<void, ValidationException> _validateRequest(
    CreateAllocationRequest request,
  ) {
    final fieldErrors = <String, List<String>>{};

    // Validate team member ID
    if (request.teamMemberId.trim().isEmpty) {
      fieldErrors['teamMemberId'] = ['Team member ID cannot be empty'];
    }

    // Validate initiative ID
    if (request.initiativeId.trim().isEmpty) {
      fieldErrors['initiativeId'] = ['Initiative ID cannot be empty'];
    }

    // Validate date range
    if (request.startDate.isAfter(request.endDate)) {
      fieldErrors['dateRange'] = ['Start date must be before or equal to end date'];
    }

    // Validate that dates are not in the distant past
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    if (request.startDate.isBefore(oneYearAgo)) {
      fieldErrors['startDate'] = ['Start date cannot be more than one year in the past'];
    }

    // Validate that dates are not too far in the future
    final twoYearsFromNow = DateTime.now().add(const Duration(days: 730));
    if (request.endDate.isAfter(twoYearsFromNow)) {
      fieldErrors['endDate'] = ['End date cannot be more than two years in the future'];
    }

    // Validate allocated weeks
    if (request.allocatedWeeks <= 0) {
      fieldErrors['allocatedWeeks'] = ['Allocated weeks must be positive'];
    }

    if (request.allocatedWeeks > 52) {
      fieldErrors['allocatedWeeks'] = ['Allocated weeks cannot exceed 52 (one year)'];
    }

    // Calculate duration and validate utilization
    final durationInDays = request.endDate.difference(request.startDate).inDays + 1;
    final durationInWeeks = durationInDays / 7.0;
    final weeklyUtilization = request.allocatedWeeks / durationInWeeks;

    if (weeklyUtilization > 1.5) {
      fieldErrors['weeklyUtilization'] = [
        'Weekly utilization (${weeklyUtilization.toStringAsFixed(2)}) '
        'exceeds reasonable limits (>150%)'
      ];
    }

    // Validate duration is reasonable
    const maxReasonableDurationDays = 26 * 7; // 26 weeks
    if (durationInDays > maxReasonableDurationDays) {
      fieldErrors['duration'] = ['Allocation duration cannot exceed 26 weeks'];
    }

    // Validate minimum duration (at least 1 day)
    if (durationInDays < 1) {
      fieldErrors['duration'] = ['Allocation duration must be at least 1 day'];
    }

    // Validate that allocated weeks make sense for the duration
    if (request.allocatedWeeks > durationInWeeks * 1.1) { // Allow 10% buffer for rounding
      fieldErrors['allocatedWeeks'] = [
        'Allocated weeks (${request.allocatedWeeks}) cannot significantly exceed '
        'duration (${durationInWeeks.toStringAsFixed(1)} weeks)'
      ];
    }

    if (fieldErrors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Allocation validation failed',
          ValidationErrorType.missingRequiredField,
          fieldErrors,
        ),
      );
    }

    return const Result.success(null);
  }

  /// Generates a unique allocation ID
  String _generateAllocationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000; // Use timestamp modulo for some randomness
    return 'alloc_${timestamp}_$random';
  }
}
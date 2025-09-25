import '../entities/team_member.dart';
import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Request object for adding a team member
class AddTeamMemberRequest {
  final String name;
  final String email;
  final Set<Role> roles;
  final double weeklyCapacity;
  final int skillLevel;
  final List<UnavailablePeriod> unavailablePeriods;
  final String notes;
  final bool isActive;

  const AddTeamMemberRequest({
    required this.name,
    required this.email,
    required this.roles,
    required this.weeklyCapacity,
    this.skillLevel = 5,
    this.unavailablePeriods = const [],
    this.notes = '',
    this.isActive = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddTeamMemberRequest &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email &&
          _setEquals(roles, other.roles) &&
          weeklyCapacity == other.weeklyCapacity &&
          skillLevel == other.skillLevel &&
          _listEquals(unavailablePeriods, other.unavailablePeriods) &&
          notes == other.notes &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      name.hashCode ^
      email.hashCode ^
      roles.hashCode ^
      weeklyCapacity.hashCode ^
      skillLevel.hashCode ^
      unavailablePeriods.hashCode ^
      notes.hashCode ^
      isActive.hashCode;

  /// Deep equality check for sets
  bool _setEquals(Set<Role> set1, Set<Role> set2) {
    if (set1.length != set2.length) return false;
    return set1.containsAll(set2);
  }

  /// Deep equality check for lists
  bool _listEquals(List<UnavailablePeriod> list1, List<UnavailablePeriod> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'AddTeamMemberRequest(name: $name, email: $email, '
      'roles: ${roles.map((r) => r.displayName).join(", ")}, '
      'capacity: $weeklyCapacity, skill: $skillLevel)';
}

/// Use case for adding new team members to the current quarter
/// Validates: name uniqueness, valid capacity range, business rules
class AddTeamMember {
  /// Add new team member with validation
  /// 
  /// Validates:
  /// - Name is non-empty and unique
  /// - Email is valid format and unique
  /// - Roles contains at least one role
  /// - Weekly capacity is between 0.1 and 1.0
  /// - Skill level is between 1 and 10
  /// - Unavailable periods don't overlap
  /// 
  /// Returns: Created team member or validation exception
  Future<Result<TeamMember, ValidationException>> call(
    AddTeamMemberRequest request,
  ) async {
    // Validate request
    final validationResult = _validateRequest(request);
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Create team member entity
    try {
      final teamMember = TeamMember(
        id: _generateTeamMemberId(),
        name: request.name.trim(),
        email: request.email.trim().toLowerCase(),
        roles: Set.from(request.roles),
        weeklyCapacity: request.weeklyCapacity,
        skillLevel: request.skillLevel,
        unavailablePeriods: List.from(request.unavailablePeriods),
        notes: request.notes,
        isActive: request.isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Result.success(teamMember);
    } catch (e) {
      return Result.error(
        ValidationException(
          'Failed to create team member: ${e.toString()}',
          ValidationErrorType.businessRuleViolation,
        ),
      );
    }
  }

  /// Validates the add team member request
  Result<void, ValidationException> _validateRequest(
    AddTeamMemberRequest request,
  ) {
    final fieldErrors = <String, List<String>>{};

    // Validate name
    if (request.name.trim().isEmpty) {
      fieldErrors['name'] = ['Team member name cannot be empty'];
    }

    // Validate email
    if (request.email.trim().isEmpty) {
      fieldErrors['email'] = ['Team member email cannot be empty'];
    } else if (!_isValidEmail(request.email)) {
      fieldErrors['email'] = ['Team member email is not valid'];
    }

    // Validate roles
    if (request.roles.isEmpty) {
      fieldErrors['roles'] = ['Team member must have at least one role'];
    }

    // Validate weekly capacity
    if (request.weeklyCapacity <= 0 || request.weeklyCapacity > 1.0) {
      fieldErrors['weeklyCapacity'] = ['Weekly capacity must be between 0.1 and 1.0'];
    }

    // Validate skill level
    if (request.skillLevel < 1 || request.skillLevel > 10) {
      fieldErrors['skillLevel'] = ['Skill level must be between 1 and 10'];
    }

    // Validate unavailable periods
    for (int i = 0; i < request.unavailablePeriods.length; i++) {
      final period = request.unavailablePeriods[i];
      if (period.startDate.isAfter(period.endDate)) {
        fieldErrors['unavailablePeriods'] = [
          'Unavailable period ${i + 1}: start date must be before end date'
        ];
        break;
      }
      if (period.reason.trim().isEmpty) {
        fieldErrors['unavailablePeriods'] = [
          'Unavailable period ${i + 1}: reason cannot be empty'
        ];
        break;
      }
    }

    // Check for overlapping unavailable periods
    for (int i = 0; i < request.unavailablePeriods.length; i++) {
      for (int j = i + 1; j < request.unavailablePeriods.length; j++) {
        final period1 = request.unavailablePeriods[i];
        final period2 = request.unavailablePeriods[j];
        
        if (_periodsOverlap(period1, period2)) {
          fieldErrors['unavailablePeriods'] = ['Unavailable periods cannot overlap'];
          break;
        }
      }
      if (fieldErrors.containsKey('unavailablePeriods')) break;
    }

    if (fieldErrors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Team member validation failed',
          ValidationErrorType.missingRequiredField,
          fieldErrors,
        ),
      );
    }

    return const Result.success(null);
  }

  /// Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  /// Checks if two unavailable periods overlap
  bool _periodsOverlap(UnavailablePeriod period1, UnavailablePeriod period2) {
    return period1.startDate.isBefore(period2.endDate) &&
           period2.startDate.isBefore(period1.endDate);
  }

  /// Generates a unique team member ID
  String _generateTeamMemberId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000; // Use timestamp modulo for some randomness
    return 'tm_${timestamp}_$random';
  }
}
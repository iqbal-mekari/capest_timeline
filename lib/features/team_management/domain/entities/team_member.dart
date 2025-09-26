import 'package:equatable/equatable.dart';

import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Represents a team member who can be allocated to initiatives.
/// 
/// A TeamMember is a person on the development team who:
/// - Has specific roles and skills
/// - Has a defined capacity per quarter
/// - Can be allocated to initiatives
/// - Has availability constraints
class TeamMember extends Equatable {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    required this.weeklyCapacity,
    this.skillLevel = 5,
    this.unavailablePeriods = const [],
    this.notes = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the team member
  final String id;

  /// Full name of the team member
  final String name;

  /// Email address for identification and communication
  final String email;

  /// Set of roles this team member can fulfill
  final Set<Role> roles;

  /// Available capacity per week (typically 5 days = 1.0)
  /// 
  /// Examples:
  /// - 1.0 = Full-time (5 days/week)
  /// - 0.5 = Part-time (2.5 days/week)
  /// - 0.8 = 80% allocation (4 days/week)
  final double weeklyCapacity;

  /// Overall skill/experience level (1-10, where 10 is most experienced)
  /// Used for allocation efficiency calculations
  final int skillLevel;

  /// Periods when this team member is unavailable
  /// (vacation, training, other commitments)
  final List<UnavailablePeriod> unavailablePeriods;

  /// Optional notes about the team member (specializations, preferences, etc.)
  final String notes;

  /// Whether this team member is currently active
  final bool isActive;

  /// When this team member record was created
  final DateTime? createdAt;

  /// When this team member record was last updated
  final DateTime? updatedAt;

  /// Gets the primary role (first role in the set, for display purposes)
  Role? get primaryRole => roles.isNotEmpty ? roles.first : null;

  /// Calculates quarterly capacity based on weekly capacity
  /// Assumes 13 weeks per quarter
  double get quarterlyCapacity => weeklyCapacity * 13.0;

  /// Determines if this is a senior team member (skill level > 7)
  bool get isSenior => skillLevel > 7;

  /// Determines if this is a junior team member (skill level < 4)
  bool get isJunior => skillLevel < 4;

  /// Gets role categories this team member can fulfill
  Set<String> get roleCategories {
    return roles.expand((role) {
      final categories = <String>[];
      if (role.isTechnical) categories.add('technical');
      if (role.isClientFacing) categories.add('client-facing');
      return categories;
    }).toSet();
  }

  /// Checks if team member can fulfill a specific role
  bool canFulfillRole(Role role) => roles.contains(role);

  /// Checks if team member has any technical roles
  bool get hasTechnicalRoles => roles.any((role) => role.isTechnical);

  /// Checks if team member has any coding roles
  bool get hasCodingRoles => roles.any((role) => role.isTechnical);

  /// Checks if team member has any client-facing roles
  bool get hasClientFacingRoles => roles.any((role) => role.isClientFacing);

  /// Calculates available capacity for a specific date range
  /// considering unavailable periods
  double calculateAvailableCapacity(DateTime startDate, DateTime endDate) {
    if (!isActive) return 0.0;

    final totalWeeks = endDate.difference(startDate).inDays / 7.0;
    var availableWeeks = totalWeeks;

    // Subtract unavailable periods that overlap with the date range
    for (final period in unavailablePeriods) {
      final overlapStart = startDate.isAfter(period.startDate) 
          ? startDate 
          : period.startDate;
      final overlapEnd = endDate.isBefore(period.endDate) 
          ? endDate 
          : period.endDate;

      if (overlapStart.isBefore(overlapEnd)) {
        final overlapWeeks = overlapEnd.difference(overlapStart).inDays / 7.0;
        availableWeeks -= overlapWeeks;
      }
    }

    return availableWeeks * weeklyCapacity;
  }

  /// Validates the team member data
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    // Basic field validation
    if (id.trim().isEmpty) {
      errors.add('Team member ID cannot be empty');
    }

    if (name.trim().isEmpty) {
      errors.add('Team member name cannot be empty');
    }

    if (email.trim().isEmpty) {
      errors.add('Team member email cannot be empty');
    } else if (!_isValidEmail(email)) {
      errors.add('Team member email is not valid');
    }

    // Roles validation
    if (roles.isEmpty) {
      errors.add('Team member must have at least one role');
    }

    // Capacity validation
    if (weeklyCapacity <= 0 || weeklyCapacity > 1.0) {
      errors.add('Weekly capacity must be between 0 and 1.0');
    }

    // Skill level validation
    if (skillLevel < 1 || skillLevel > 10) {
      errors.add('Skill level must be between 1 and 10');
    }

    // Unavailable periods validation
    for (int i = 0; i < unavailablePeriods.length; i++) {
      final period = unavailablePeriods[i];
      if (period.startDate.isAfter(period.endDate)) {
        errors.add('Unavailable period ${i + 1}: start date must be before end date');
      }
    }

    // Check for overlapping unavailable periods
    for (int i = 0; i < unavailablePeriods.length; i++) {
      for (int j = i + 1; j < unavailablePeriods.length; j++) {
        final period1 = unavailablePeriods[i];
        final period2 = unavailablePeriods[j];
        
        if (_periodsOverlap(period1, period2)) {
          errors.add('Unavailable periods cannot overlap');
          break;
        }
      }
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Team member validation failed',
          ValidationErrorType.businessRuleViolation,
          {'teamMember': errors},
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

  /// Creates a copy of this team member with updated fields
  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    Set<Role>? roles,
    double? weeklyCapacity,
    int? skillLevel,
    List<UnavailablePeriod>? unavailablePeriods,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      weeklyCapacity: weeklyCapacity ?? this.weeklyCapacity,
      skillLevel: skillLevel ?? this.skillLevel,
      unavailablePeriods: unavailablePeriods ?? this.unavailablePeriods,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a TeamMember from a Map (for serialization)
  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      roles: (map['roles'] as List<dynamic>)
          .map((roleString) => Role.values.firstWhere((r) => r.name == roleString))
          .toSet(),
      weeklyCapacity: (map['weeklyCapacity'] as num).toDouble(),
      skillLevel: map['skillLevel'] as int? ?? 5,
      unavailablePeriods: (map['unavailablePeriods'] as List<dynamic>? ?? [])
          .map((periodMap) => UnavailablePeriod.fromMap(periodMap as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this TeamMember to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'roles': roles.map((role) => role.name).toList(),
      'weeklyCapacity': weeklyCapacity,
      'skillLevel': skillLevel,
      'unavailablePeriods': unavailablePeriods.map((period) => period.toMap()).toList(),
      'notes': notes,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        roles,
        weeklyCapacity,
        skillLevel,
        unavailablePeriods,
        notes,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'TeamMember('
        'id: $id, '
        'name: $name, '
        'capacity: ${weeklyCapacity}w/week, '
        'skill: $skillLevel, '
        'roles: ${roles.map((r) => r.displayName).join(", ")}'
        ')';
  }
}

/// Represents a period when a team member is unavailable
class UnavailablePeriod extends Equatable {
  const UnavailablePeriod({
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.notes = '',
  });

  /// When the unavailable period starts
  final DateTime startDate;

  /// When the unavailable period ends
  final DateTime endDate;

  /// Reason for unavailability (vacation, training, sick leave, etc.)
  final String reason;

  /// Optional additional notes
  final String notes;

  /// Duration of this unavailable period in days
  int get durationInDays => endDate.difference(startDate).inDays + 1;

  /// Duration of this unavailable period in weeks
  double get durationInWeeks => durationInDays / 7.0;

  /// Creates a copy of this unavailable period with updated fields
  UnavailablePeriod copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? reason,
    String? notes,
  }) {
    return UnavailablePeriod(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
    );
  }

  /// Creates an UnavailablePeriod from a Map (for serialization)
  factory UnavailablePeriod.fromMap(Map<String, dynamic> map) {
    return UnavailablePeriod(
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      reason: map['reason'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }

  /// Converts this UnavailablePeriod to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'reason': reason,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [startDate, endDate, reason, notes];

  @override
  String toString() {
    return 'UnavailablePeriod('
        'start: ${startDate.toIso8601String().split('T')[0]}, '
        'end: ${endDate.toIso8601String().split('T')[0]}, '
        'reason: $reason'
        ')';
  }
}
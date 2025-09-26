import 'package:equatable/equatable.dart';

import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Represents a development initiative or project that requires capacity allocation.
/// 
/// An Initiative is a discrete piece of work that:
/// - Has a defined scope and requirements
/// - Requires specific roles and effort levels
/// - Can be scheduled across quarters
/// - Has business value and priority
class Initiative extends Equatable {
  const Initiative({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredRoles,
    required this.estimatedEffortWeeks,
    required this.priority,
    required this.businessValue,
    required this.dependencies,
    this.tags = const [],
    this.notes = '',
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for the initiative
  final String id;

  /// Human-readable name for the initiative
  final String name;

  /// Detailed description of what this initiative involves
  final String description;

  /// Map of roles to their required effort in person-weeks
  /// 
  /// Example: {Role.backend: 4.0, Role.frontend: 2.0, Role.qa: 1.0}
  /// This means 4 weeks of backend work, 2 weeks frontend, 1 week QA
  final Map<Role, double> requiredRoles;

  /// Total estimated effort across all roles in person-weeks
  final double estimatedEffortWeeks;

  /// Business priority level (1-10, where 10 is highest priority)
  final int priority;

  /// Expected business value or impact (1-10, where 10 is highest value)
  final int businessValue;

  /// List of initiative IDs that must be completed before this one
  final List<String> dependencies;

  /// Optional tags for categorization and filtering
  final List<String> tags;

  /// Optional additional notes or context
  final String notes;

  /// When this initiative was created
  final DateTime? createdAt;

  /// When this initiative was last updated
  final DateTime? updatedAt;

  /// Calculates the total effort across all required roles
  double get totalEffort => requiredRoles.values.fold(0.0, (sum, effort) => sum + effort);

  /// Gets all unique roles required for this initiative
  Set<Role> get roles => requiredRoles.keys.toSet();

  /// Calculates effort distribution as percentages
  Map<Role, double> get effortDistribution {
    if (totalEffort == 0) return {};
    
    return requiredRoles.map(
      (role, effort) => MapEntry(role, (effort / totalEffort) * 100),
    );
  }

  /// Determines if this initiative is complex (requires multiple roles)
  bool get isComplex => requiredRoles.length > 1;

  /// Determines if this initiative is large (more than 8 person-weeks)
  bool get isLarge => totalEffort > 8.0;

  /// Gets the primary role (role with most effort allocation)
  Role? get primaryRole {
    if (requiredRoles.isEmpty) return null;
    
    return requiredRoles.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Calculates priority score combining business priority and value
  double get priorityScore => (priority + businessValue) / 2.0;

  /// Validates the initiative data
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    // Basic field validation
    if (id.trim().isEmpty) {
      errors.add('Initiative ID cannot be empty');
    }

    if (name.trim().isEmpty) {
      errors.add('Initiative name cannot be empty');
    }

    if (description.trim().isEmpty) {
      errors.add('Initiative description cannot be empty');
    }

    // Priority validation
    if (priority < 1 || priority > 10) {
      errors.add('Priority must be between 1 and 10');
    }

    // Business value validation
    if (businessValue < 1 || businessValue > 10) {
      errors.add('Business value must be between 1 and 10');
    }

    // Required roles validation
    if (requiredRoles.isEmpty) {
      errors.add('Initiative must require at least one role');
    }

    for (final entry in requiredRoles.entries) {
      if (entry.value <= 0) {
        errors.add('Effort for ${entry.key.displayName} must be positive');
      }
    }

    // Effort validation
    if (estimatedEffortWeeks <= 0) {
      errors.add('Estimated effort must be positive');
    }

    // Check that estimated effort matches sum of role efforts
    final calculatedEffort = totalEffort;
    if ((estimatedEffortWeeks - calculatedEffort).abs() > 0.1) {
      errors.add(
        'Estimated effort ($estimatedEffortWeeks) does not match '
        'sum of role efforts ($calculatedEffort)',
      );
    }

    // Dependency validation (check for self-references)
    if (dependencies.contains(id)) {
      errors.add('Initiative cannot depend on itself');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Initiative validation failed',
          ValidationErrorType.businessRuleViolation,
          {'initiative': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  /// Creates a copy of this initiative with updated fields
  Initiative copyWith({
    String? id,
    String? name,
    String? description,
    Map<Role, double>? requiredRoles,
    double? estimatedEffortWeeks,
    int? priority,
    int? businessValue,
    List<String>? dependencies,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Initiative(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      requiredRoles: requiredRoles ?? this.requiredRoles,
      estimatedEffortWeeks: estimatedEffortWeeks ?? this.estimatedEffortWeeks,
      priority: priority ?? this.priority,
      businessValue: businessValue ?? this.businessValue,
      dependencies: dependencies ?? this.dependencies,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates an Initiative from a Map (for serialization)
  factory Initiative.fromMap(Map<String, dynamic> map) {
    return Initiative(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      requiredRoles: (map['requiredRoles'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          Role.values.firstWhere((r) => r.name == key),
          (value as num).toDouble(),
        ),
      ),
      estimatedEffortWeeks: (map['estimatedEffortWeeks'] as num).toDouble(),
      priority: map['priority'] as int,
      businessValue: map['businessValue'] as int,
      dependencies: List<String>.from(map['dependencies'] as List),
      tags: List<String>.from(map['tags'] as List? ?? []),
      notes: map['notes'] as String? ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this Initiative to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'requiredRoles': requiredRoles.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'estimatedEffortWeeks': estimatedEffortWeeks,
      'priority': priority,
      'businessValue': businessValue,
      'dependencies': dependencies,
      'tags': tags,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        requiredRoles,
        estimatedEffortWeeks,
        priority,
        businessValue,
        dependencies,
        tags,
        notes,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'Initiative('
        'id: $id, '
        'name: $name, '
        'effort: ${totalEffort}w, '
        'priority: $priority, '
        'roles: ${roles.map((r) => r.displayName).join(", ")}'
        ')';
  }
}
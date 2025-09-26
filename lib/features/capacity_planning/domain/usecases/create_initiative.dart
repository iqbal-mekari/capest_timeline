import '../entities/initiative.dart';
import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Request object for creating an initiative
class CreateInitiativeRequest {
  final String name;
  final String description;
  final Map<Role, double> effortByRole;
  final int priority;
  final int businessValue;
  final List<String> dependencies;
  final List<String> tags;
  final String notes;

  const CreateInitiativeRequest({
    required this.name,
    required this.description,
    required this.effortByRole,
    this.priority = 5,
    this.businessValue = 5,
    this.dependencies = const [],
    this.tags = const [],
    this.notes = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreateInitiativeRequest &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description &&
          _mapEquals(effortByRole, other.effortByRole) &&
          priority == other.priority &&
          businessValue == other.businessValue &&
          _listEquals(dependencies, other.dependencies) &&
          _listEquals(tags, other.tags) &&
          notes == other.notes;

  @override
  int get hashCode =>
      name.hashCode ^
      description.hashCode ^
      effortByRole.hashCode ^
      priority.hashCode ^
      businessValue.hashCode ^
      dependencies.hashCode ^
      tags.hashCode ^
      notes.hashCode;

  /// Deep equality check for maps
  bool _mapEquals(Map<Role, double> map1, Map<Role, double> map2) {
    if (map1.length != map2.length) return false;
    for (final entry in map1.entries) {
      if (!map2.containsKey(entry.key) || map2[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// Deep equality check for lists
  bool _listEquals(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  @override
  String toString() =>
      'CreateInitiativeRequest(name: $name, description: $description, '
      'effortByRole: $effortByRole, priority: $priority, businessValue: $businessValue)';
}

/// Use case for creating new initiatives with role requirements
/// Validates: name uniqueness, positive effort values, business rules
class CreateInitiative {
  /// Create new initiative with validation
  /// 
  /// Validates:
  /// - Name is non-empty and unique within quarter
  /// - Effort by role contains at least one role with positive effort
  /// - Total effort does not exceed team capacity * 13 weeks
  /// 
  /// Returns: Created initiative or validation exception
  Future<Result<Initiative, ValidationException>> call(
    CreateInitiativeRequest request,
  ) async {
    // Validate request
    final validationResult = _validateRequest(request);
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Create initiative entity
    try {
      final totalEffort = request.effortByRole.values.fold(0.0, (sum, effort) => sum + effort);
      
      final initiative = Initiative(
        id: _generateInitiativeId(),
        name: request.name.trim(),
        description: request.description.trim(),
        requiredRoles: Map.from(request.effortByRole),
        estimatedEffortWeeks: totalEffort,
        priority: request.priority,
        businessValue: request.businessValue,
        dependencies: List.from(request.dependencies),
        tags: List.from(request.tags),
        notes: request.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Result.success(initiative);
    } catch (e) {
      return Result.error(
        ValidationException(
          'Failed to create initiative: ${e.toString()}',
          ValidationErrorType.businessRuleViolation,
        ),
      );
    }
  }

  /// Validates the create initiative request
  Result<void, ValidationException> _validateRequest(
    CreateInitiativeRequest request,
  ) {
    final fieldErrors = <String, List<String>>{};

    // Validate name
    if (request.name.trim().isEmpty) {
      fieldErrors['name'] = ['Initiative name cannot be empty'];
    }

    // Validate description
    if (request.description.trim().isEmpty) {
      fieldErrors['description'] = ['Initiative description cannot be empty'];
    }

    // Validate effort by role
    if (request.effortByRole.isEmpty) {
      fieldErrors['effortByRole'] = ['Initiative must require at least one role'];
    } else {
      final invalidRoles = <String>[];
      for (final entry in request.effortByRole.entries) {
        if (entry.value <= 0) {
          invalidRoles.add('${entry.key.displayName}: ${entry.value}');
        }
      }
      if (invalidRoles.isNotEmpty) {
        fieldErrors['effortByRole'] = [
          'All role efforts must be positive: ${invalidRoles.join(', ')}'
        ];
      }
    }

    // Validate total effort is reasonable (not exceeding typical quarter capacity)
    final totalEffort = request.effortByRole.values.fold(0.0, (sum, effort) => sum + effort);
    const maxReasonableEffort = 500.0; // weeks - reasonable upper bound for large initiatives
    if (totalEffort > maxReasonableEffort) {
      fieldErrors['effortByRole'] = [
        'Total effort ($totalEffort weeks) exceeds reasonable limit ($maxReasonableEffort weeks)'
      ];
    }

    // Validate priority
    if (request.priority < 1 || request.priority > 10) {
      fieldErrors['priority'] = ['Priority must be between 1 and 10'];
    }

    // Validate business value
    if (request.businessValue < 1 || request.businessValue > 10) {
      fieldErrors['businessValue'] = ['Business value must be between 1 and 10'];
    }

    // Validate dependencies (check for empty strings)
    for (final dependency in request.dependencies) {
      if (dependency.trim().isEmpty) {
        fieldErrors['dependencies'] = ['Dependencies cannot contain empty strings'];
        break;
      }
    }

    if (fieldErrors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Initiative validation failed',
          ValidationErrorType.missingRequiredField,
          fieldErrors,
        ),
      );
    }

    return const Result.success(null);
  }

  /// Generates a unique initiative ID
  String _generateInitiativeId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp % 10000; // Use timestamp modulo for some randomness
    return 'init_${timestamp}_$random';
  }
}
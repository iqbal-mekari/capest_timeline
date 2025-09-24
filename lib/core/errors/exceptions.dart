/// Core exception types for the Capacity Estimation application.
/// These exceptions are used throughout the application to handle
/// various error scenarios with proper type safety and error messages.
library;

/// Base exception class for all application-specific exceptions
abstract class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Exception? cause;

  @override
  String toString() => 'AppException: $message';
}

/// Exception thrown when local storage operations fail
class StorageException extends AppException {
  const StorageException(super.message, this.type, [super.cause]);

  final StorageErrorType type;

  @override
  String toString() => 'StorageException: $message (Type: ${type.name})';
}

/// Types of storage errors that can occur
enum StorageErrorType {
  /// Local storage is not available or supported
  notAvailable('Local storage is not available'),
  
  /// Storage quota has been exceeded
  quotaExceeded('Storage quota exceeded'),
  
  /// Stored data is corrupted or invalid
  dataCorrupted('Stored data is corrupted'),
  
  /// Permission denied to access storage
  permissionDenied('Permission denied to storage'),
  
  /// Network error (for future cloud sync)
  networkError('Network error occurred'),
  
  /// Unknown storage error
  unknown('Unknown storage error');

  const StorageErrorType(this.description);
  final String description;
}

/// Exception thrown when validation rules are violated
class ValidationException extends AppException {
  const ValidationException(
    super.message,
    this.type, [
    this.fieldErrors = const {},
    super.cause,
  ]);

  final ValidationErrorType type;
  final Map<String, List<String>> fieldErrors;

  /// Check if there are any field-specific errors
  bool get hasFieldErrors => fieldErrors.isNotEmpty;

  /// Get errors for a specific field
  List<String> getFieldErrors(String field) => fieldErrors[field] ?? [];

  /// Get all error messages as a single list
  List<String> get allErrors {
    final List<String> errors = [message];
    for (final fieldErrorList in fieldErrors.values) {
      errors.addAll(fieldErrorList);
    }
    return errors;
  }

  @override
  String toString() {
    final buffer = StringBuffer('ValidationException: $message (Type: ${type.name})');
    if (hasFieldErrors) {
      buffer.write('\nField errors:');
      fieldErrors.forEach((field, errors) {
        buffer.write('\n  $field: ${errors.join(', ')}');
      });
    }
    return buffer.toString();
  }
}

/// Types of validation errors that can occur
enum ValidationErrorType {
  /// Team member capacity has been over-allocated
  capacityOverallocation('Capacity over-allocation detected'),
  
  /// Invalid time range specified (end before start, etc.)
  invalidTimeRange('Invalid time range'),
  
  /// Duplicate name or identifier
  duplicateName('Duplicate name'),
  
  /// Required field is missing or empty
  missingRequiredField('Missing required field'),
  
  /// Business rule has been violated
  businessRuleViolation('Business rule violation'),
  
  /// Referential integrity constraint violated
  referentialIntegrityViolation('Referential integrity violation'),
  
  /// Invalid format or data type
  invalidFormat('Invalid format'),
  
  /// Value is out of acceptable range
  outOfRange('Value out of range');

  const ValidationErrorType(this.description);
  final String description;
}

/// Exception thrown when domain business rules are violated
class BusinessRuleException extends AppException {
  const BusinessRuleException(
    super.message,
    this.ruleType, [
    this.context = const {},
    super.cause,
  ]);

  final BusinessRuleType ruleType;
  final Map<String, dynamic> context;

  @override
  String toString() {
    final buffer = StringBuffer('BusinessRuleException: $message (Rule: ${ruleType.name})');
    if (context.isNotEmpty) {
      buffer.write('\nContext: $context');
    }
    return buffer.toString();
  }
}

/// Types of business rules that can be violated
enum BusinessRuleType {
  /// Cannot allocate member to role they don't possess
  invalidRoleAllocation('Invalid role allocation'),
  
  /// Cannot exceed quarter planning boundaries
  quarterBoundaryViolation('Quarter boundary violation'),
  
  /// Cannot modify allocation that is in progress or completed
  immutableAllocation('Immutable allocation'),
  
  /// Cannot delete entity with dependent relationships
  dependentEntitiesExist('Dependent entities exist'),
  
  /// Maximum limit exceeded (team size, initiatives, etc.)
  limitExceeded('Limit exceeded'),
  
  /// Operation not allowed in current state
  invalidStateTransition('Invalid state transition');

  const BusinessRuleType(this.description);
  final String description;
}

/// Exception thrown when network operations fail (future use)
class NetworkException extends AppException {
  const NetworkException(
    super.message,
    this.statusCode, [
    this.responseBody,
    super.cause,
  ]);

  final int? statusCode;
  final String? responseBody;

  @override
  String toString() {
    final buffer = StringBuffer('NetworkException: $message');
    if (statusCode != null) {
      buffer.write(' (Status: $statusCode)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when concurrent modification is detected
class ConcurrencyException extends AppException {
  const ConcurrencyException(
    super.message, [
    this.conflictingEntity,
    super.cause,
  ]);

  final String? conflictingEntity;

  @override
  String toString() {
    final buffer = StringBuffer('ConcurrencyException: $message');
    if (conflictingEntity != null) {
      buffer.write(' (Entity: $conflictingEntity)');
    }
    return buffer.toString();
  }
}

/// Exception thrown when configuration is invalid or missing
class ConfigurationException extends AppException {
  const ConfigurationException(
    super.message,
    this.configKey, [
    super.cause,
  ]);

  final String configKey;

  @override
  String toString() => 'ConfigurationException: $message (Key: $configKey)';
}

/// Factory methods for creating common exceptions with standardized messages
class ExceptionFactory {
  /// Create a storage exception for quota exceeded
  static StorageException storageQuotaExceeded([String? details]) {
    final message = details != null
        ? 'Storage quota exceeded: $details'
        : 'Local storage quota has been exceeded. Please clear some data.';
    return StorageException(message, StorageErrorType.quotaExceeded);
  }

  /// Create a validation exception for capacity overallocation
  static ValidationException capacityOverallocated(
    String memberName,
    double allocatedCapacity,
    double availableCapacity,
  ) {
    final message = 'Team member $memberName is over-allocated: '
        '${allocatedCapacity.toStringAsFixed(1)} weeks allocated, '
        'but only ${availableCapacity.toStringAsFixed(1)} weeks available.';
    return ValidationException(
      message,
      ValidationErrorType.capacityOverallocation,
    );
  }

  /// Create a business rule exception for invalid role allocation
  static BusinessRuleException invalidRoleAllocation(
    String memberName,
    String role,
  ) {
    final message = 'Cannot allocate $memberName to $role role: '
        'team member does not have this role capability.';
    return BusinessRuleException(
      message,
      BusinessRuleType.invalidRoleAllocation,
      {'memberName': memberName, 'role': role},
    );
  }

  /// Create a validation exception for duplicate names
  static ValidationException duplicateName(String entityType, String name) {
    final message = '$entityType with name "$name" already exists. '
        'Please choose a different name.';
    return ValidationException(
      message,
      ValidationErrorType.duplicateName,
      {'name': ['Name must be unique']},
    );
  }

  /// Create a business rule exception for dependent entities
  static BusinessRuleException dependentEntitiesExist(
    String entityType,
    String entityName,
    List<String> dependentTypes,
  ) {
    final dependentList = dependentTypes.join(', ');
    final message = 'Cannot delete $entityType "$entityName" because it has '
        'dependent $dependentList. Please remove dependencies first.';
    return BusinessRuleException(
      message,
      BusinessRuleType.dependentEntitiesExist,
      {
        'entityType': entityType,
        'entityName': entityName,
        'dependentTypes': dependentTypes,
      },
    );
  }
}
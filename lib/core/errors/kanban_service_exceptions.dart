/// Custom exceptions for KanbanService error handling

/// Base exception class for all Kanban service errors
abstract class KanbanServiceException implements Exception {
  const KanbanServiceException(this.message);
  final String message;
  
  @override
  String toString() => 'KanbanServiceException: $message';
}

/// Thrown when storage operations fail
class StorageException extends KanbanServiceException {
  const StorageException(super.message);
  
  @override
  String toString() => 'StorageException: $message';
}

/// Thrown when data is corrupted or malformed
class DataCorruptionException extends KanbanServiceException {
  const DataCorruptionException(super.message);
  
  @override
  String toString() => 'DataCorruptionException: $message';
}

/// Thrown when data validation fails
class ValidationException extends KanbanServiceException {
  const ValidationException(super.message);
  
  @override
  String toString() => 'ValidationException: $message';
}

/// Thrown when attempting to create duplicate entities
class DuplicateIdException extends KanbanServiceException {
  const DuplicateIdException(super.message);
  
  @override
  String toString() => 'DuplicateIdException: $message';
}

/// Thrown when capacity calculations fail
class CapacityCalculationException extends KanbanServiceException {
  const CapacityCalculationException(super.message);
  
  @override
  String toString() => 'CapacityCalculationException: $message';
}

/// Thrown when capacity constraints are violated
class CapacityConstraintException extends KanbanServiceException {
  const CapacityConstraintException(super.message);
  
  @override
  String toString() => 'CapacityConstraintException: $message';
}

/// Thrown when required data is missing
class MissingDataException extends KanbanServiceException {
  const MissingDataException(super.message);
  
  @override
  String toString() => 'MissingDataException: $message';
}

/// Thrown when operations timeout
class TimeoutException extends KanbanServiceException {
  const TimeoutException(super.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

/// Thrown when concurrent modifications conflict
class ConcurrentModificationException extends KanbanServiceException {
  const ConcurrentModificationException(super.message);
  
  @override
  String toString() => 'ConcurrentModificationException: $message';
}

/// Thrown when resource locks cannot be acquired
class ResourceLockException extends KanbanServiceException {
  const ResourceLockException(super.message);
  
  @override
  String toString() => 'ResourceLockException: $message';
}

/// Result wrapper for operations that may fail gracefully
class ServiceResult<T> {
  const ServiceResult.success(this.data) : 
    isSuccess = true, 
    errorMessage = null;
    
  const ServiceResult.failure(this.errorMessage) : 
    isSuccess = false, 
    data = null;

  final bool isSuccess;
  final T? data;
  final String? errorMessage;
}
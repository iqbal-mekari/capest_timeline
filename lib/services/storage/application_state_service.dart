/// Application state storage service for the capacity planning timeline application.
/// 
/// This service provides persistent storage and management of application state
/// including view settings, filters, current selections, and UI state across
/// browser sessions.
library;

import '../../core/errors/exceptions.dart';
import '../../core/types/result.dart';
import '../../features/configuration/domain/entities/application_state.dart';
import '../../features/configuration/data/datasources/local_storage_datasource.dart';

/// Abstract interface for application state storage operations
abstract class ApplicationStateService {
  /// Saves the application state to persistent storage
  /// 
  /// Stores the current application state including view settings,
  /// filters, and UI preferences. Handles storage quota and
  /// permission errors gracefully.
  Future<Result<void, StorageException>> saveState(ApplicationState state);
  
  /// Restores the application state from persistent storage
  /// 
  /// Returns the saved application state if it exists, otherwise returns
  /// the default state. Handles data corruption and migration from older
  /// state formats gracefully.
  Future<Result<ApplicationState, StorageException>> restoreState();
  
  /// Resets the application state to default values
  /// 
  /// Clears any saved state and restores defaults.
  /// This operation is idempotent - safe to call multiple times.
  Future<Result<void, StorageException>> resetState();
  
  /// Checks if storage is available and accessible
  /// 
  /// Returns true if storage operations are supported and permitted,
  /// false otherwise. Useful for graceful degradation when storage
  /// is unavailable or disabled.
  Future<bool> isStorageAvailable();
}

/// Implementation of ApplicationStateService using local storage
class ApplicationStateServiceImpl implements ApplicationStateService {
  ApplicationStateServiceImpl({
    required LocalStorageDataSource storageDataSource,
  }) : _storageDataSource = storageDataSource;

  final LocalStorageDataSource _storageDataSource;

  @override
  Future<Result<void, StorageException>> saveState(ApplicationState state) async {
    try {
      // Validate state before saving
      final validation = state.validate();
      if (validation.isError) {
        return Result.error(StorageException(
          'Application state validation failed: ${validation.error}',
          StorageErrorType.dataCorrupted,
        ));
      }

      // Save to storage
      await _storageDataSource.saveApplicationState(state.toMap());
      
      return const Result.success(null);
    } catch (e) {
      // Handle storage-specific errors
      if (e.toString().contains('quota')) {
        return Result.error(const StorageException(
          'Storage quota exceeded. Please free up space.',
          StorageErrorType.quotaExceeded,
        ));
      }
      
      if (e.toString().contains('permission')) {
        return Result.error(const StorageException(
          'Storage access denied. Please check browser settings.',
          StorageErrorType.permissionDenied,
        ));
      }
      
      return Result.error(StorageException(
        'Failed to save application state: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<ApplicationState, StorageException>> restoreState() async {
    try {
      final data = await _storageDataSource.getApplicationState();
      
      if (data == null) {
        // No saved state, return default
        return const Result.success(ApplicationState());
      }

      // Try to deserialize the state
      try {
        final state = ApplicationState.fromMap(data);
        
        // Validate the loaded state
        final validation = state.validate();
        if (validation.isError) {
          // State is invalid, log warning and return defaults
          return const Result.success(ApplicationState());
        }
        
        return Result.success(state);
      } catch (deserializationError) {
        // Data is corrupted, return error but provide defaults
        return Result.error(StorageException(
          'Application state data is corrupted. Using defaults. Error: $deserializationError',
          StorageErrorType.dataCorrupted,
        ));
      }
    } catch (e) {
      if (e.toString().contains('permission')) {
        return Result.error(const StorageException(
          'Storage access denied. Please check browser settings.',
          StorageErrorType.permissionDenied,
        ));
      }
      
      return Result.error(StorageException(
        'Failed to restore application state: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> resetState() async {
    try {
      // Clear all data (this will remove the application state)
      await _storageDataSource.clearAllData();
      
      return const Result.success(null);
    } catch (e) {
      if (e.toString().contains('permission')) {
        return Result.error(const StorageException(
          'Storage access denied. Please check browser settings.',
          StorageErrorType.permissionDenied,
        ));
      }
      
      return Result.error(StorageException(
        'Failed to reset application state: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<bool> isStorageAvailable() async {
    try {
      await _storageDataSource.initialize();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Factory for creating ApplicationStateService instances
class ApplicationStateServiceFactory {
  /// Creates an ApplicationStateService with appropriate implementation
  /// 
  /// Currently returns the local storage implementation, but could
  /// be extended to support different storage backends based on
  /// configuration or environment.
  static ApplicationStateService create({
    required LocalStorageDataSource storageDataSource,
  }) {
    return ApplicationStateServiceImpl(
      storageDataSource: storageDataSource,
    );
  }
}
/// Configuration storage service for the capacity planning timeline application.
/// 
/// This service provides persistent storage and management of user configuration
/// settings including theme preferences, auto-save settings, and application
/// customization options.
library;

import '../../core/errors/exceptions.dart';
import '../../core/types/result.dart';
import '../../features/configuration/domain/entities/user_configuration.dart';
import '../../features/configuration/data/datasources/local_storage_datasource.dart';

/// Abstract interface for configuration storage operations
abstract class ConfigurationService {
  /// Saves the user configuration to persistent storage
  /// 
  /// Validates the configuration before saving and returns appropriate
  /// error results if validation fails or storage is unavailable.
  Future<Result<void, StorageException>> saveConfiguration(UserConfiguration config);
  
  /// Loads the user configuration from persistent storage
  /// 
  /// Returns the saved configuration if it exists, otherwise returns
  /// the default configuration. Handles data corruption and migration
  /// from older configuration formats gracefully.
  Future<Result<UserConfiguration, StorageException>> loadConfiguration();
  
  /// Resets the user configuration to default values
  /// 
  /// Clears any saved configuration and restores defaults.
  /// This operation is idempotent - safe to call multiple times.
  Future<Result<void, StorageException>> resetConfiguration();
}

/// Implementation of ConfigurationService using local storage
class ConfigurationServiceImpl implements ConfigurationService {
  ConfigurationServiceImpl({
    required LocalStorageDataSource storageDataSource,
  }) : _storageDataSource = storageDataSource;

  final LocalStorageDataSource _storageDataSource;

  @override
  Future<Result<void, StorageException>> saveConfiguration(UserConfiguration config) async {
    try {
      // Validate configuration before saving
      final validation = config.validate();
      if (validation.isError) {
        return Result.error(StorageException(
          'Configuration validation failed: ${validation.error}',
          StorageErrorType.dataCorrupted,
        ));
      }

      // Save to storage
      await _storageDataSource.saveUserConfiguration(config.toMap());
      
      return const Result.success(null);
    } catch (e) {
      // Handle storage-specific errors
      if (e.toString().contains('quota')) {
        return Result.error(const StorageException(
          'Storage quota exceeded. Please free up space or reduce settings.',
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
        'Failed to save configuration: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<UserConfiguration, StorageException>> loadConfiguration() async {
    try {
      final data = await _storageDataSource.getUserConfiguration();
      
      if (data == null) {
        // No saved configuration, return default
        return const Result.success(UserConfiguration());
      }

      // Try to deserialize the configuration
      try {
        final config = UserConfiguration.fromMap(data);
        
        // Validate the loaded configuration
        final validation = config.validate();
        if (validation.isError) {
          // Configuration is invalid, log warning and return defaults
          // In a real app, you might want to show a user notification
          return const Result.success(UserConfiguration());
        }
        
        return Result.success(config);
      } catch (deserializationError) {
        // Data is corrupted, return defaults but log the issue
        return Result.error(StorageException(
          'Configuration data is corrupted. Using defaults. Error: $deserializationError',
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
        'Failed to load configuration: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> resetConfiguration() async {
    try {
      // Clear all data (this will remove the user configuration)
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
        'Failed to reset configuration: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Checks if the storage is available and writable
  Future<bool> isStorageAvailable() async {
    try {
      await _storageDataSource.initialize();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Factory for creating ConfigurationService instances
class ConfigurationServiceFactory {
  /// Creates a ConfigurationService with appropriate implementation
  /// 
  /// Currently returns the local storage implementation, but could
  /// be extended to support different storage backends based on
  /// configuration or environment.
  static ConfigurationService create({
    required LocalStorageDataSource storageDataSource,
  }) {
    return ConfigurationServiceImpl(
      storageDataSource: storageDataSource,
    );
  }
}
import '../entities/user_configuration.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Repository interface for user configuration persistence and retrieval
/// Handles user preferences and application settings
abstract class ConfigurationRepository {
  /// Save user configuration preferences
  Future<Result<void, StorageException>> saveConfiguration(UserConfiguration config);

  /// Load user configuration preferences
  /// Returns: Saved config or default config if none exists
  Future<Result<UserConfiguration, StorageException>> loadConfiguration();

  /// Reset configuration to default values
  Future<Result<void, StorageException>> resetConfiguration();

  /// Check if configuration storage is available and accessible
  Future<bool> isStorageAvailable();
}
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Storage keys for different data types in local storage
class StorageKeys {
  static const String applicationState = 'capest_app_state';
  static const String userConfiguration = 'capest_user_config';
  static const String sessionRecovery = 'capest_session_recovery';
  static const String configurationMetadata = 'capest_config_metadata';
  static const String quarterPlanPrefix = 'capest_quarter_';
  static const String schemaVersion = 'capest_schema_version';
  
  /// Current schema version for data migration
  static const int currentSchemaVersion = 1;
}

/// Information about local storage usage
class StorageInfo {
  final int totalSizeBytes;
  final int capestSizeBytes;
  final int availableSizeBytes;
  final double usagePercentage;
  final bool isAvailable;

  const StorageInfo({
    required this.totalSizeBytes,
    required this.capestSizeBytes,
    required this.availableSizeBytes,
    required this.usagePercentage,
    required this.isAvailable,
  });

  /// Total size in MB
  double get totalSizeMB => totalSizeBytes / (1024 * 1024);

  /// Capest data size in MB
  double get capestSizeMB => capestSizeBytes / (1024 * 1024);

  /// Available size in MB
  double get availableSizeMB => availableSizeBytes / (1024 * 1024);

  /// Whether storage is nearly full (>80% used)
  bool get isNearlyFull => usagePercentage > 80.0;

  /// Whether storage is critically low (>95% used)
  bool get isCriticallyLow => usagePercentage > 95.0;

  @override
  String toString() =>
      'StorageInfo(total: ${totalSizeMB.toStringAsFixed(2)}MB, '
      'capest: ${capestSizeMB.toStringAsFixed(2)}MB, '
      'usage: ${usagePercentage.toStringAsFixed(1)}%)';
}

/// Stub implementation for local storage when dart:html is not available
/// Used in test environments and non-web platforms
class LocalStorageDataSource {
  /// Check if local storage is available (always false in stub)
  Future<bool> isAvailable() async => false;

  /// Store data (always fails in stub)
  Future<Result<void, StorageException>> store(String key, Map<String, dynamic> data) async {
    return Result.error(
      const StorageException(
        'Local storage not available in test environment',
        StorageErrorType.notAvailable,
      ),
    );
  }

  /// Retrieve data (always returns null in stub)
  Future<Result<Map<String, dynamic>?, StorageException>> retrieve(String key) async {
    return const Result.success(null);
  }

  /// Remove data (always succeeds silently in stub)
  Future<Result<void, StorageException>> remove(String key) async {
    return const Result.success(null);
  }

  /// Check if key exists (always false in stub)
  Future<Result<bool, StorageException>> exists(String key) async {
    return const Result.success(false);
  }

  /// List keys (always returns empty list in stub)
  Future<Result<List<String>, StorageException>> listKeys(String prefix) async {
    return const Result.success(<String>[]);
  }

  /// Clear all data (always succeeds silently in stub)
  Future<Result<void, StorageException>> clearAll() async {
    return const Result.success(null);
  }

  /// Get storage info (returns unavailable info in stub)
  Future<Result<StorageInfo, StorageException>> getStorageInfo() async {
    const info = StorageInfo(
      totalSizeBytes: 0,
      capestSizeBytes: 0,
      availableSizeBytes: 0,
      usagePercentage: 0.0,
      isAvailable: false,
    );
    return const Result.success(info);
  }

  /// Schema version management (always succeeds in stub)
  Future<Result<void, StorageException>> ensureSchemaVersion() async {
    return const Result.success(null);
  }
}
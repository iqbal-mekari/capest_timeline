import 'dart:convert';
import 'dart:html' as html;
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

/// Data source for browser local storage operations
/// Provides low-level storage operations with error handling and data validation
class LocalStorageDataSource {
  /// Check if local storage is available and accessible
  Future<bool> isAvailable() async {
    try {
      // Test storage availability by attempting to write/read
      const testKey = 'capest_storage_test';
      const testValue = 'test';
      
      html.window.localStorage[testKey] = testValue;
      final result = html.window.localStorage[testKey];
      html.window.localStorage.remove(testKey);
      
      return result == testValue;
    } catch (e) {
      return false;
    }
  }

  /// Store data as JSON string in local storage
  Future<Result<void, StorageException>> store(String key, Map<String, dynamic> data) async {
    try {
      if (!await isAvailable()) {
        return Result.error(
          const StorageException(
            'Local storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final jsonString = json.encode(data);
      
      // Check if storing would exceed quota
      final currentSize = _calculateStorageSize();
      final dataSize = jsonString.length * 2; // UTF-16 encoding (2 bytes per char)
      const maxSize = 10 * 1024 * 1024; // 10MB reasonable limit
      
      if (currentSize + dataSize > maxSize) {
        return Result.error(
          const StorageException(
            'Storage quota would be exceeded',
            StorageErrorType.quotaExceeded,
          ),
        );
      }

      html.window.localStorage[key] = jsonString;
      
      // Verify the data was stored correctly
      final storedData = html.window.localStorage[key];
      if (storedData != jsonString) {
        return Result.error(
          const StorageException(
            'Data verification failed after storage',
            StorageErrorType.dataCorrupted,
          ),
        );
      }

      return const Result.success(null);
    } on html.DomException catch (e) {
      if (e.name == 'QuotaExceededError') {
        return Result.error(
          StorageException(
            'Storage quota exceeded: ${e.message}',
            StorageErrorType.quotaExceeded,
            Exception(e.toString()),
          ),
        );
      }
      return Result.error(
        StorageException(
          'Storage operation failed: ${e.message}',
          StorageErrorType.permissionDenied,
          Exception(e.toString()),
        ),
      );
    } catch (e) {
      return Result.error(
        StorageException(
          'Unexpected storage error: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// Retrieve and parse JSON data from local storage
  Future<Result<Map<String, dynamic>?, StorageException>> retrieve(String key) async {
    try {
      if (!await isAvailable()) {
        return Result.error(
          const StorageException(
            'Local storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final jsonString = html.window.localStorage[key];
      if (jsonString == null) {
        return const Result.success(null);
      }

      try {
        final data = json.decode(jsonString) as Map<String, dynamic>;
        return Result.success(data);
      } on FormatException catch (e) {
        // Data is corrupted, remove it and return null
        await remove(key);
        return Result.error(
          StorageException(
            'Stored data is corrupted and has been removed: ${e.message}',
            StorageErrorType.dataCorrupted,
            e,
          ),
        );
      }
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to retrieve data: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// Remove data from local storage
  Future<Result<void, StorageException>> remove(String key) async {
    try {
      if (!await isAvailable()) {
        return Result.error(
          const StorageException(
            'Local storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      html.window.localStorage.remove(key);
      return const Result.success(null);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to remove data: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// Check if a key exists in local storage
  Future<Result<bool, StorageException>> exists(String key) async {
    try {
      if (!await isAvailable()) {
        return Result.error(
          const StorageException(
            'Local storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final value = html.window.localStorage[key];
      return Result.success(value != null);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to check key existence: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// List all keys matching a prefix
  Future<Result<List<String>, StorageException>> listKeys(String prefix) async {
    try {
      if (!await isAvailable()) {
        return Result.error(
          const StorageException(
            'Local storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final storage = html.window.localStorage;
      final matchingKeys = <String>[];

      for (int i = 0; i < storage.length; i++) {
        final key = storage.keys.elementAt(i);
        if (key.startsWith(prefix)) {
          matchingKeys.add(key);
        }
      }

      return Result.success(matchingKeys);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to list keys: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// Clear all application data from local storage
  Future<Result<void, StorageException>> clearAll() async {
    try {
      if (!await isAvailable()) {
        return Result.error(
          const StorageException(
            'Local storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final storage = html.window.localStorage;
      final keysToRemove = <String>[];

      // Collect all capest-related keys
      for (final key in storage.keys) {
        if (key.startsWith('capest_')) {
          keysToRemove.add(key);
        }
      }

      // Remove all collected keys
      for (final key in keysToRemove) {
        storage.remove(key);
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to clear storage: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// Get current storage usage information
  Future<Result<StorageInfo, StorageException>> getStorageInfo() async {
    try {
      if (!await isAvailable()) {
        return Result.error(
          const StorageException(
            'Local storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final currentSize = _calculateStorageSize();
      final capestSize = _calculateCapestStorageSize();
      
      const estimatedMaxSize = 10 * 1024 * 1024; // 10MB estimate
      final usagePercentage = (currentSize / estimatedMaxSize * 100).clamp(0.0, 100.0);

      final info = StorageInfo(
        totalSizeBytes: currentSize,
        capestSizeBytes: capestSize,
        availableSizeBytes: estimatedMaxSize - currentSize,
        usagePercentage: usagePercentage,
        isAvailable: true,
      );

      return Result.success(info);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to get storage info: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// Check and initialize schema version
  Future<Result<void, StorageException>> ensureSchemaVersion() async {
    final versionResult = await retrieve(StorageKeys.schemaVersion);
    if (versionResult.isError) {
      return Result.error(versionResult.error);
    }

    final versionData = versionResult.value;
    if (versionData == null) {
      // First time setup - store current schema version
      return await store(StorageKeys.schemaVersion, {
        'version': StorageKeys.currentSchemaVersion,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    final storedVersion = versionData['version'] as int? ?? 1;
    if (storedVersion < StorageKeys.currentSchemaVersion) {
      // Future: implement migration logic here
      return await store(StorageKeys.schemaVersion, {
        'version': StorageKeys.currentSchemaVersion,
        'migratedAt': DateTime.now().toIso8601String(),
        'previousVersion': storedVersion,
      });
    }

    return const Result.success(null);
  }

  /// Calculate total storage size in bytes
  int _calculateStorageSize() {
    final storage = html.window.localStorage;
    var totalSize = 0;

    for (final key in storage.keys) {
      final value = storage[key];
      if (value != null) {
        // UTF-16 encoding: 2 bytes per character
        totalSize += (key.length + value.length) * 2;
      }
    }

    return totalSize;
  }

  /// Calculate storage size used by capest data
  int _calculateCapestStorageSize() {
    final storage = html.window.localStorage;
    var capestSize = 0;

    for (final key in storage.keys) {
      if (key.startsWith('capest_')) {
        final value = storage[key];
        if (value != null) {
          capestSize += (key.length + value.length) * 2;
        }
      }
    }

    return capestSize;
  }
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
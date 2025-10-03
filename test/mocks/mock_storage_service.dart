
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capest_timeline/services/storage_service.dart';
import 'package:capest_timeline/models/models.dart';
import 'package:capest_timeline/core/errors/kanban_service_exceptions.dart';

/// Mock implementation of StorageService for testing error scenarios
class MockStorageService extends StorageService {
  // Error simulation flags
  bool shouldFailRead = false;
  bool shouldFailWrite = false;
  bool shouldReturnCorruptedData = false;
  bool shouldFailPartialWrite = false;
  bool shouldTimeoutOnSync = false;
  bool isNetworkAvailable = true;
  bool shouldSimulateConcurrentModification = false;
  bool shouldTimeoutOnLock = false;
  bool shouldFailTemporarily = false;
  bool shouldUseFallbackData = false;
  bool shouldFailPartialOperations = false;

  // Error messages
  String readFailureMessage = 'Mock storage read failure';
  String writeFailureMessage = 'Mock storage write failure';
  String calculationFailureMessage = 'Mock calculation failure';

  // Logging flags
  bool partialFailureLogged = false;

  // Temporary failure simulation
  int failureCount = 0;
  int maxFailuresBeforeRecovery = 3;

  // Fallback data
  List<Initiative> fallbackInitiatives = [];

  // Lock simulation
  final Map<String, DateTime> _lockTimestamps = {};

  // Mock SharedPreferences
  late MockSharedPreferences _mockSharedPreferences;

  MockStorageService() : super(sharedPreferences: MockSharedPreferences()) {
    _mockSharedPreferences = super.sharedPreferences as MockSharedPreferences;
    _mockSharedPreferences._mockStorageService = this;
  }

  /// Simulate remote sync operation
  Future<ServiceResult<bool>> syncWithRemote() async {
    if (shouldTimeoutOnSync) {
      throw const TimeoutException('Remote sync operation timed out');
    }

    if (!isNetworkAvailable) {
      return const ServiceResult.failure('Sync failed: network unavailable');
    }

    return const ServiceResult.success(true);
  }

  /// Reset all error simulation flags
  void resetErrorFlags() {
    shouldFailRead = false;
    shouldFailWrite = false;
    shouldReturnCorruptedData = false;
    shouldFailPartialWrite = false;
    shouldTimeoutOnSync = false;
    isNetworkAvailable = true;
    shouldSimulateConcurrentModification = false;
    shouldTimeoutOnLock = false;
    shouldFailTemporarily = false;
    shouldUseFallbackData = false;
    shouldFailPartialOperations = false;
    partialFailureLogged = false;
    failureCount = 0;
    _lockTimestamps.clear();
  }

  // Helper method to check and trigger errors
  void _checkErrorConditions() {
    if (shouldTimeoutOnLock) {
      throw const ResourceLockException('Could not acquire lock within timeout');
    }

    if (shouldSimulateConcurrentModification && _lockTimestamps.isNotEmpty) {
      throw const ConcurrentModificationException('Data was modified by another process');
    }

    if (shouldFailWrite) {
      throw StorageException(writeFailureMessage);
    }

    if (shouldFailTemporarily && failureCount < maxFailuresBeforeRecovery) {
      failureCount++;
      throw StorageException('Temporary storage failure #$failureCount');
    }

    if (shouldFailPartialWrite) {
      partialFailureLogged = true;
    }
  }
}

/// Mock SharedPreferences for testing
class MockSharedPreferences implements SharedPreferences {
  MockStorageService? _mockStorageService;
  final Map<String, String> _stringStorage = {};

  @override
  Future<bool> setString(String key, String value) async {
    _mockStorageService?._checkErrorConditions();
    _stringStorage[key] = value;
    return true;
  }

  @override
  String? getString(String key) {
    if (_mockStorageService?.shouldFailRead == true) {
      throw StorageException(_mockStorageService?.readFailureMessage ?? 'Read failed');
    }

    if (_mockStorageService?.shouldReturnCorruptedData == true) {
      return 'corrupted-json-data-{invalid}';
    }

    if (_mockStorageService?.shouldFailTemporarily == true && 
        (_mockStorageService?.failureCount ?? 0) < (_mockStorageService?.maxFailuresBeforeRecovery ?? 0)) {
      _mockStorageService?.failureCount = (_mockStorageService?.failureCount ?? 0) + 1;
      throw StorageException('Temporary storage failure #${_mockStorageService?.failureCount}');
    }

    return _stringStorage[key];
  }

  @override
  Future<bool> remove(String key) async {
    _mockStorageService?._checkErrorConditions();
    _stringStorage.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _mockStorageService?._checkErrorConditions();
    _stringStorage.clear();
    return true;
  }

  @override
  Set<String> getKeys() => _stringStorage.keys.toSet();

  // Unused SharedPreferences methods for this mock
  @override
  bool? getBool(String key) => null;
  @override
  double? getDouble(String key) => null;
  @override
  int? getInt(String key) => null;
  @override
  List<String>? getStringList(String key) => null;
  @override
  Future<bool> setBool(String key, bool value) async => true;
  @override
  Future<bool> setDouble(String key, double value) async => true;
  @override
  Future<bool> setInt(String key, int value) async => true;
  @override
  Future<bool> setStringList(String key, List<String> value) async => true;
  @override
  bool containsKey(String key) => _stringStorage.containsKey(key);
  @override
  Object? get(String key) => _stringStorage[key];
  @override
  Future<void> reload() async {}
  @override
  Future<bool> commit() async => true;
}
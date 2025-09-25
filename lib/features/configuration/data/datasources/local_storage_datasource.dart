import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Local storage data source using SharedPreferences for web persistence.
/// 
/// This data source handles:
/// - Application state persistence
/// - User configuration storage
/// - Quarter plan data management
/// - Data validation and migration
/// - Storage quota management
class LocalStorageDataSource {
  LocalStorageDataSource({SharedPreferences? preferences})
      : _preferences = preferences;

  SharedPreferences? _preferences;
  
  // Storage keys
  static const String _applicationStateKey = 'capest_application_state';
  static const String _userConfigurationKey = 'capest_user_configuration';
  static const String _quarterPlansPrefix = 'capest_quarter_plan_';
  static const String _quarterPlanSummariesKey = 'capest_quarter_plan_summaries';
  static const String _dataVersionKey = 'capest_data_version';
  
  // Current data version for migration support
  static const int _currentDataVersion = 1;

  /// Initializes the data source
  Future<Result<void, StorageException>> initialize() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      
      // Check and perform data migration if needed
      await _performDataMigrationIfNeeded();
      
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to initialize local storage: $e',
        StorageErrorType.notAvailable,
      ));
    }
  }

  /// Performs data migration if the stored version is older than current
  Future<void> _performDataMigrationIfNeeded() async {
    final prefs = _preferences!;
    final storedVersion = prefs.getInt(_dataVersionKey) ?? 0;
    
    if (storedVersion < _currentDataVersion) {
      // Perform migration steps here
      // For now, we'll just update the version
      await prefs.setInt(_dataVersionKey, _currentDataVersion);
    }
  }

  /// Gets the application state from storage
  Future<Map<String, dynamic>?> getApplicationState() async {
    try {
      await _ensureInitialized();
      final jsonString = _preferences!.getString(_applicationStateKey);
      
      if (jsonString == null) return null;
      
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return data;
    } catch (e) {
      throw StorageException(
        'Failed to get application state: $e',
        StorageErrorType.dataCorrupted,
      );
    }
  }

  /// Saves the application state to storage
  Future<void> saveApplicationState(Map<String, dynamic> state) async {
    try {
      await _ensureInitialized();
      final jsonString = json.encode(state);
      
      final success = await _preferences!.setString(_applicationStateKey, jsonString);
      if (!success) {
        throw StorageException(
          'Failed to save application state',
          StorageErrorType.quotaExceeded,
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to save application state: $e',
        StorageErrorType.unknown,
      );
    }
  }

  /// Gets the user configuration from storage
  Future<Map<String, dynamic>?> getUserConfiguration() async {
    try {
      await _ensureInitialized();
      final jsonString = _preferences!.getString(_userConfigurationKey);
      
      if (jsonString == null) return null;
      
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return data;
    } catch (e) {
      throw StorageException(
        'Failed to get user configuration: $e',
        StorageErrorType.dataCorrupted,
      );
    }
  }

  /// Saves the user configuration to storage
  Future<void> saveUserConfiguration(Map<String, dynamic> config) async {
    try {
      await _ensureInitialized();
      final jsonString = json.encode(config);
      
      final success = await _preferences!.setString(_userConfigurationKey, jsonString);
      if (!success) {
        throw StorageException(
          'Failed to save user configuration',
          StorageErrorType.quotaExceeded,
        );
      }
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to save user configuration: $e',
        StorageErrorType.unknown,
      );
    }
  }

  /// Gets a quarter plan from storage
  Future<Map<String, dynamic>?> getQuarterPlan(String planId) async {
    try {
      await _ensureInitialized();
      final key = '$_quarterPlansPrefix$planId';
      final jsonString = _preferences!.getString(key);
      
      if (jsonString == null) return null;
      
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return data;
    } catch (e) {
      throw StorageException(
        'Failed to get quarter plan: $e',
        StorageErrorType.dataCorrupted,
      );
    }
  }

  /// Saves a quarter plan to storage
  Future<void> saveQuarterPlan(String planId, Map<String, dynamic> plan) async {
    try {
      await _ensureInitialized();
      final key = '$_quarterPlansPrefix$planId';
      final jsonString = json.encode(plan);
      
      final success = await _preferences!.setString(key, jsonString);
      if (!success) {
        throw StorageException(
          'Failed to save quarter plan',
          StorageErrorType.quotaExceeded,
        );
      }
      
      // Update summaries
      await _updateQuarterPlanSummary(planId, plan);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to save quarter plan: $e',
        StorageErrorType.unknown,
      );
    }
  }

  /// Updates the quarter plan summary list
  Future<void> _updateQuarterPlanSummary(String planId, Map<String, dynamic> plan) async {
    try {
      final summaries = await getQuarterPlanSummaries();
      
      // Remove existing summary if it exists
      summaries.removeWhere((summary) => summary['id'] == planId);
      
      // Create new summary
      final newSummary = {
        'id': planId,
        'displayName': plan['name'] ?? 'Q${plan['quarter']} ${plan['year']}',
        'quarter': plan['quarter'],
        'year': plan['year'],
        'totalInitiatives': (plan['initiatives'] as List?)?.length ?? 0,
        'totalTeamMembers': (plan['teamMembers'] as List?)?.length ?? 0,
        'capacityUtilization': _calculateCapacityUtilization(plan),
        'lastModified': DateTime.now().toIso8601String(),
      };
      
      summaries.add(newSummary);
      
      // Save updated summaries
      final jsonString = json.encode(summaries);
      await _preferences!.setString(_quarterPlanSummariesKey, jsonString);
    } catch (e) {
      // Don't fail the main operation if summary update fails
      // Just log the error (in a real app, you'd use proper logging)
      print('Warning: Failed to update quarter plan summary: $e');
    }
  }

  /// Calculates capacity utilization for a plan (simplified)
  double _calculateCapacityUtilization(Map<String, dynamic> plan) {
    try {
      final allocations = plan['allocations'] as List? ?? [];
      final teamMembers = plan['teamMembers'] as List? ?? [];
      
      if (teamMembers.isEmpty) return 0.0;
      
      double totalAllocated = 0.0;
      double totalAvailable = 0.0;
      
      for (final member in teamMembers) {
        final memberMap = member as Map<String, dynamic>;
        final weeklyCapacity = (memberMap['weeklyCapacity'] as num?)?.toDouble() ?? 1.0;
        totalAvailable += weeklyCapacity * 13; // 13 weeks per quarter
      }
      
      for (final allocation in allocations) {
        final allocationMap = allocation as Map<String, dynamic>;
        final allocatedWeeks = (allocationMap['allocatedWeeks'] as num?)?.toDouble() ?? 0.0;
        totalAllocated += allocatedWeeks;
      }
      
      return totalAvailable > 0 ? (totalAllocated / totalAvailable) * 100 : 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Gets all quarter plan summaries
  Future<List<Map<String, dynamic>>> getQuarterPlanSummaries() async {
    try {
      await _ensureInitialized();
      final jsonString = _preferences!.getString(_quarterPlanSummariesKey);
      
      if (jsonString == null) return [];
      
      final data = json.decode(jsonString) as List<dynamic>;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      throw StorageException(
        'Failed to get quarter plan summaries: $e',
        StorageErrorType.dataCorrupted,
      );
    }
  }

  /// Deletes a quarter plan from storage
  Future<void> deleteQuarterPlan(String planId) async {
    try {
      await _ensureInitialized();
      final key = '$_quarterPlansPrefix$planId';
      
      final success = await _preferences!.remove(key);
      if (!success) {
        throw StorageException(
          'Failed to delete quarter plan',
          StorageErrorType.unknown,
        );
      }
      
      // Remove from summaries
      await _removeFromSummaries(planId);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to delete quarter plan: $e',
        StorageErrorType.unknown,
      );
    }
  }

  /// Removes a plan from the summaries list
  Future<void> _removeFromSummaries(String planId) async {
    try {
      final summaries = await getQuarterPlanSummaries();
      summaries.removeWhere((summary) => summary['id'] == planId);
      
      final jsonString = json.encode(summaries);
      await _preferences!.setString(_quarterPlanSummariesKey, jsonString);
    } catch (e) {
      // Don't fail the main operation if summary update fails
      print('Warning: Failed to remove from summaries: $e');
    }
  }

  /// Exports all data for backup purposes
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      await _ensureInitialized();
      final prefs = _preferences!;
      
      final exportData = <String, dynamic>{
        'version': _currentDataVersion,
        'exportDate': DateTime.now().toIso8601String(),
        'applicationState': await getApplicationState(),
        'userConfiguration': await getUserConfiguration(),
        'quarterPlans': <String, dynamic>{},
        'quarterPlanSummaries': await getQuarterPlanSummaries(),
      };
      
      // Export all quarter plans
      final summaries = await getQuarterPlanSummaries();
      for (final summary in summaries) {
        final planId = summary['id'] as String;
        final planData = await getQuarterPlan(planId);
        if (planData != null) {
          exportData['quarterPlans'][planId] = planData;
        }
      }
      
      return exportData;
    } catch (e) {
      throw StorageException(
        'Failed to export data: $e',
        StorageErrorType.unknown,
      );
    }
  }

  /// Imports data from backup
  Future<void> importAllData(Map<String, dynamic> data) async {
    try {
      await _ensureInitialized();
      
      // Validate import data version
      final importVersion = data['version'] as int? ?? 0;
      if (importVersion > _currentDataVersion) {
        throw StorageException(
          'Import data is from a newer version and cannot be imported',
          StorageErrorType.dataCorrupted,
        );
      }
      
      // Clear existing data
      await clearAllData();
      
      // Import application state
      if (data['applicationState'] != null) {
        await saveApplicationState(data['applicationState'] as Map<String, dynamic>);
      }
      
      // Import user configuration
      if (data['userConfiguration'] != null) {
        await saveUserConfiguration(data['userConfiguration'] as Map<String, dynamic>);
      }
      
      // Import quarter plans
      final quarterPlans = data['quarterPlans'] as Map<String, dynamic>? ?? {};
      for (final entry in quarterPlans.entries) {
        await saveQuarterPlan(entry.key, entry.value as Map<String, dynamic>);
      }
      
      // Set data version
      await _preferences!.setInt(_dataVersionKey, _currentDataVersion);
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException(
        'Failed to import data: $e',
        StorageErrorType.dataCorrupted,
      );
    }
  }

  /// Clears all stored data
  Future<void> clearAllData() async {
    try {
      await _ensureInitialized();
      final prefs = _preferences!;
      
      // Get all keys and filter for our data
      final keys = prefs.getKeys();
      final ourKeys = keys.where((key) => 
          key.startsWith('capest_') || 
          key == _applicationStateKey ||
          key == _userConfigurationKey ||
          key == _quarterPlanSummariesKey ||
          key == _dataVersionKey
      ).toList();
      
      // Remove all our keys
      for (final key in ourKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      throw StorageException(
        'Failed to clear data: $e',
        StorageErrorType.unknown,
      );
    }
  }

  /// Gets storage usage information
  Future<StorageInfo> getStorageInfo() async {
    try {
      await _ensureInitialized();
      final prefs = _preferences!;
      
      final keys = prefs.getKeys();
      final ourKeys = keys.where((key) => key.startsWith('capest_')).toList();
      
      int totalSize = 0;
      int planCount = 0;
      
      for (final key in ourKeys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length;
          if (key.startsWith(_quarterPlansPrefix)) {
            planCount++;
          }
        }
      }
      
      return StorageInfo(
        totalSizeBytes: totalSize,
        planCount: planCount,
        keyCount: ourKeys.length,
      );
    } catch (e) {
      throw StorageException(
        'Failed to get storage info: $e',
        StorageErrorType.unknown,
      );
    }
  }

  /// Ensures the data source is initialized
  Future<void> _ensureInitialized() async {
    if (_preferences == null) {
      final result = await initialize();
      if (result.isError) {
        throw result.error;
      }
    }
  }

  /// Disposes the data source
  void dispose() {
    // SharedPreferences doesn't need explicit disposal
    _preferences = null;
  }
}

/// Information about storage usage
class StorageInfo {
  const StorageInfo({
    required this.totalSizeBytes,
    required this.planCount,
    required this.keyCount,
  });

  final int totalSizeBytes;
  final int planCount;
  final int keyCount;

  double get totalSizeKB => totalSizeBytes / 1024.0;
  double get totalSizeMB => totalSizeKB / 1024.0;

  @override
  String toString() {
    return 'StorageInfo('
        'size: ${totalSizeKB.toStringAsFixed(1)}KB, '
        'plans: $planCount, '
        'keys: $keyCount'
        ')';
  }
}
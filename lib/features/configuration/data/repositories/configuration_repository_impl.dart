import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/themes/app_theme.dart';
import '../../domain/entities/application_state.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/repositories/configuration_repository.dart';

class ConfigurationRepositoryImpl implements ConfigurationRepository {
  final SharedPreferences _prefs;
  
  // Storage keys
  static const String _appStateKey = 'application_state';
  static const String _userConfigKey = 'user_configuration';
  static const String _sessionRecoveryKey = 'session_recovery';
  static const String _metadataKey = 'configuration_metadata';
  
  const ConfigurationRepositoryImpl(this._prefs);

  // Application State Operations
  
  @override
  Future<Result<void, StorageException>> saveApplicationState(ApplicationState state) async {
    try {
      final success = await _prefs.setString(_appStateKey, jsonEncode(state.toMap()));
      if (!success) {
        return Result.error(StorageException(
          'Failed to save application state',
          StorageErrorType.unknown,
        ));
      }

      // Update metadata
      await _updateMetadata();

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save application state: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<ApplicationState?, StorageException>> loadApplicationState() async {
    try {
      final jsonString = _prefs.getString(_appStateKey);
      if (jsonString == null) {
        return const Result.success(null);
      }

      final Map<String, dynamic> stateData = jsonDecode(jsonString);
      final state = ApplicationState.fromMap(stateData);
      return Result.success(state);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load application state: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateCurrentPlan(String? planId) async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      final currentState = stateResult.value ?? ApplicationState();
      final updatedState = currentState.withCurrentPlan(planId);

      return await saveApplicationState(updatedState);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update current plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateViewSettings({
    ViewMode? viewMode,
    int? quarter,
    int? year,
  }) async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      final currentState = stateResult.value ?? ApplicationState();
      final updatedState = currentState.withViewSettings(
        viewMode: viewMode,
        quarter: quarter,
        year: year,
      );

      return await saveApplicationState(updatedState);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update view settings: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateFilters(ApplicationFilters filters) async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      final currentState = stateResult.value ?? ApplicationState();
      final updatedState = currentState.copyWith(
        filters: filters,
        hasUnsavedChanges: true,
        updatedAt: DateTime.now(),
      );

      return await saveApplicationState(updatedState);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update filters: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> addToRecentPlans(String planId) async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      final currentState = stateResult.value ?? ApplicationState();
      final updatedState = currentState.withCurrentPlan(planId);

      return await saveApplicationState(updatedState);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to add plan to recent plans: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> clearRecentPlans() async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      final currentState = stateResult.value ?? ApplicationState();
      final updatedState = currentState.copyWith(
        lastAccessedPlanIds: [],
        hasUnsavedChanges: true,
        updatedAt: DateTime.now(),
      );

      return await saveApplicationState(updatedState);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to clear recent plans: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> markAsChanged() async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      final currentState = stateResult.value ?? ApplicationState();
      final updatedState = currentState.markAsChanged();

      return await saveApplicationState(updatedState);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to mark as changed: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> markAsSaved() async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      final currentState = stateResult.value ?? ApplicationState();
      final updatedState = currentState.markAsSaved();

      return await saveApplicationState(updatedState);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to mark as saved: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  // User Configuration Operations

  @override
  Future<Result<void, StorageException>> saveUserConfiguration(UserConfiguration config) async {
    try {
      final success = await _prefs.setString(_userConfigKey, jsonEncode(config.toMap()));
      if (!success) {
        return Result.error(StorageException(
          'Failed to save user configuration',
          StorageErrorType.unknown,
        ));
      }

      // Update metadata
      await _updateMetadata();

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save user configuration: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<UserConfiguration?, StorageException>> loadUserConfiguration() async {
    try {
      final jsonString = _prefs.getString(_userConfigKey);
      if (jsonString == null) {
        return const Result.success(null);
      }

      final Map<String, dynamic> configData = jsonDecode(jsonString);
      final config = UserConfiguration.fromMap(configData);
      return Result.success(config);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load user configuration: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateTheme(AppThemeMode theme) async {
    try {
      final configResult = await loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }

      final currentConfig = configResult.value ?? UserConfiguration();
      final updatedConfig = currentConfig.copyWith(
        theme: theme,
        updatedAt: DateTime.now(),
      );

      return await saveUserConfiguration(updatedConfig);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update theme: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateNotificationSettings(bool enableNotifications) async {
    try {
      final configResult = await loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }

      final currentConfig = configResult.value ?? UserConfiguration();
      final updatedConfig = currentConfig.copyWith(
        enableNotifications: enableNotifications,
        updatedAt: DateTime.now(),
      );

      return await saveUserConfiguration(updatedConfig);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update notification settings: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateAutoSaveSettings(int intervalSeconds) async {
    try {
      final configResult = await loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }

      final currentConfig = configResult.value ?? UserConfiguration();
      final updatedConfig = currentConfig.copyWith(
        autoSaveInterval: intervalSeconds,
        updatedAt: DateTime.now(),
      );

      return await saveUserConfiguration(updatedConfig);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update auto-save settings: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateInitiativeDefaults(InitiativeDefaults defaults) async {
    try {
      final configResult = await loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }

      final currentConfig = configResult.value ?? UserConfiguration();
      final updatedConfig = currentConfig.copyWith(
        initiativeDefaults: defaults,
        updatedAt: DateTime.now(),
      );

      return await saveUserConfiguration(updatedConfig);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update initiative defaults: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateTeamMemberDefaults(TeamMemberDefaults defaults) async {
    try {
      final configResult = await loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }

      final currentConfig = configResult.value ?? UserConfiguration();
      final updatedConfig = currentConfig.copyWith(
        teamMemberDefaults: defaults,
        updatedAt: DateTime.now(),
      );

      return await saveUserConfiguration(updatedConfig);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update team member defaults: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateDisplayPreferences({
    String? defaultViewMode,
    String? dateFormat,
    CapacityDisplayMode? capacityDisplayMode,
  }) async {
    try {
      final configResult = await loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }

      final currentConfig = configResult.value ?? UserConfiguration();
      final updatedConfig = currentConfig.copyWith(
        defaultViewMode: defaultViewMode ?? currentConfig.defaultViewMode,
        dateFormat: dateFormat ?? currentConfig.dateFormat,
        capacityDisplayMode: capacityDisplayMode ?? currentConfig.capacityDisplayMode,
        updatedAt: DateTime.now(),
      );

      return await saveUserConfiguration(updatedConfig);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update display preferences: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  // Session and Recovery Operations

  @override
  Future<Result<void, StorageException>> saveSessionRecovery(SessionRecoveryData data) async {
    try {
      final success = await _prefs.setString(_sessionRecoveryKey, jsonEncode(data.toMap()));
      if (!success) {
        return Result.error(StorageException(
          'Failed to save session recovery data',
          StorageErrorType.unknown,
        ));
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save session recovery data: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<SessionRecoveryData?, StorageException>> loadSessionRecovery() async {
    try {
      final jsonString = _prefs.getString(_sessionRecoveryKey);
      if (jsonString == null) {
        return const Result.success(null);
      }

      final Map<String, dynamic> recoveryData = jsonDecode(jsonString);
      final data = SessionRecoveryData.fromMap(recoveryData);
      return Result.success(data);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load session recovery data: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> clearSessionRecovery() async {
    try {
      await _prefs.remove(_sessionRecoveryKey);
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to clear session recovery data: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<bool, StorageException>> hasRecoverableSession() async {
    try {
      final recoveryResult = await loadSessionRecovery();
      if (recoveryResult.isError) {
        return Result.error(recoveryResult.error);
      }

      final data = recoveryResult.value;
      return Result.success(data != null && data.isRecent && data.hasUnsavedWork);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to check recoverable session: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  // Backup and Restore Operations

  @override
  Future<Result<String, StorageException>> createFullBackup() async {
    try {
      final stateResult = await loadApplicationState();
      final configResult = await loadUserConfiguration();
      final recoveryResult = await loadSessionRecovery();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'applicationState': stateResult.valueOrNull?.toMap(),
        'userConfiguration': configResult.valueOrNull?.toMap(),
        'sessionRecovery': recoveryResult.valueOrNull?.toMap(),
      };

      final jsonString = jsonEncode(backupData);
      return Result.success(jsonString);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to create full backup: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> restoreFromBackup(String backupData) async {
    try {
      final Map<String, dynamic> backup = jsonDecode(backupData);

      // Restore application state if present
      if (backup['applicationState'] != null) {
        final stateData = backup['applicationState'] as Map<String, dynamic>;
        final state = ApplicationState.fromMap(stateData);
        final stateResult = await saveApplicationState(state);
        if (stateResult.isError) {
          return Result.error(stateResult.error);
        }
      }

      // Restore user configuration if present
      if (backup['userConfiguration'] != null) {
        final configData = backup['userConfiguration'] as Map<String, dynamic>;
        final config = UserConfiguration.fromMap(configData);
        final configResult = await saveUserConfiguration(config);
        if (configResult.isError) {
          return Result.error(configResult.error);
        }
      }

      // Restore session recovery if present
      if (backup['sessionRecovery'] != null) {
        final recoveryData = backup['sessionRecovery'] as Map<String, dynamic>;
        final data = SessionRecoveryData.fromMap(recoveryData);
        final recoveryResult = await saveSessionRecovery(data);
        if (recoveryResult.isError) {
          return Result.error(recoveryResult.error);
        }
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to restore from backup: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<ConfigurationMetadata, StorageException>> getConfigurationMetadata() async {
    try {
      final jsonString = _prefs.getString(_metadataKey);
      if (jsonString != null) {
        final Map<String, dynamic> metadataData = jsonDecode(jsonString);
        final metadata = ConfigurationMetadata.fromMap(metadataData);
        return Result.success(metadata);
      }

      // Generate metadata if not exists
      final now = DateTime.now();
      final hasAppState = _prefs.containsKey(_appStateKey);
      final hasUserConfig = _prefs.containsKey(_userConfigKey);
      final hasSessionRecovery = _prefs.containsKey(_sessionRecoveryKey);

      final metadata = ConfigurationMetadata(
        version: 1,
        createdAt: now,
        lastModified: now,
        hasApplicationState: hasAppState,
        hasUserConfiguration: hasUserConfig,
        hasSessionRecovery: hasSessionRecovery,
        dataSize: _calculateDataSize(),
      );

      // Save the generated metadata
      await _prefs.setString(_metadataKey, jsonEncode(metadata.toMap()));

      return Result.success(metadata);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get configuration metadata: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  // Utility Operations

  @override
  Future<Result<void, ValidationException>> validateConfiguration(UserConfiguration config) async {
    return config.validate();
  }

  @override
  Future<Result<void, StorageException>> resetToDefaults() async {
    try {
      // Clear all existing data
      await _prefs.remove(_appStateKey);
      await _prefs.remove(_userConfigKey);
      await _prefs.remove(_sessionRecoveryKey);
      await _prefs.remove(_metadataKey);

      // Save default configuration
      final defaultConfig = UserConfiguration();
      await saveUserConfiguration(defaultConfig);

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to reset to defaults: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> migrateConfiguration(int fromVersion, int toVersion) async {
    try {
      // For now, just update metadata version
      // In the future, implement actual migration logic
      await _updateMetadata(version: toVersion);
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to migrate configuration: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<DateTime?, StorageException>> getApplicationStateLastModified() async {
    try {
      final stateResult = await loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }

      return Result.success(stateResult.value?.updatedAt);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get application state last modified: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<DateTime?, StorageException>> getUserConfigurationLastModified() async {
    try {
      final configResult = await loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }

      return Result.success(configResult.value?.updatedAt);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get user configuration last modified: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> clearAllConfiguration() async {
    try {
      await _prefs.remove(_appStateKey);
      await _prefs.remove(_userConfigKey);
      await _prefs.remove(_sessionRecoveryKey);
      await _prefs.remove(_metadataKey);
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to clear all configuration: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  // Private helper methods

  Future<void> _updateMetadata({int? version}) async {
    try {
      final now = DateTime.now();
      final hasAppState = _prefs.containsKey(_appStateKey);
      final hasUserConfig = _prefs.containsKey(_userConfigKey);
      final hasSessionRecovery = _prefs.containsKey(_sessionRecoveryKey);

      // Try to load existing metadata to preserve creation date
      DateTime createdAt = now;
      try {
        final existingJsonString = _prefs.getString(_metadataKey);
        if (existingJsonString != null) {
          final existingData = jsonDecode(existingJsonString) as Map<String, dynamic>;
          createdAt = DateTime.parse(existingData['createdAt'] as String);
        }
      } catch (_) {
        // Use current time if can't load existing
      }

      final metadata = ConfigurationMetadata(
        version: version ?? 1,
        createdAt: createdAt,
        lastModified: now,
        hasApplicationState: hasAppState,
        hasUserConfiguration: hasUserConfig,
        hasSessionRecovery: hasSessionRecovery,
        dataSize: _calculateDataSize(),
      );

      await _prefs.setString(_metadataKey, jsonEncode(metadata.toMap()));
    } catch (_) {
      // Ignore metadata update failures - not critical
    }
  }

  int _calculateDataSize() {
    int size = 0;
    
    final appStateData = _prefs.getString(_appStateKey);
    if (appStateData != null) {
      size += appStateData.length;
    }
    
    final userConfigData = _prefs.getString(_userConfigKey);
    if (userConfigData != null) {
      size += userConfigData.length;
    }
    
    final sessionRecoveryData = _prefs.getString(_sessionRecoveryKey);
    if (sessionRecoveryData != null) {
      size += sessionRecoveryData.length;
    }
    
    return size;
  }
}
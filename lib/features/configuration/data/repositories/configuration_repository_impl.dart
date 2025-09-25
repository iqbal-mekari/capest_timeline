import 'dart:convert';
import 'dart:async';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/themes/app_theme.dart';
import '../../domain/entities/application_state.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/repositories/configuration_repository.dart';
import '../datasources/local_storage_data_source.dart';

class ConfigurationRepositoryImpl implements ConfigurationRepository {
  final LocalStorageDataSource _dataSource;
  
  const ConfigurationRepositoryImpl(this._dataSource);

  // Application State Operations
  
  @override
  Future<Result<void, StorageException>> saveApplicationState(ApplicationState state) async {
    try {
      final result = await _dataSource.store(
        StorageKeys.applicationState,
        state.toMap(),
      );

      if (result.isError) {
        return Result.error(result.error);
      }

      // Update metadata after save
      await _updateMetadata();

      return const Result.success(null);
    } catch (e) {      return Result.error(StorageException(
        'Failed to save application state: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<ApplicationState?, StorageException>> loadApplicationState() async {
    try {
      final result = await _dataSource.retrieve(StorageKeys.applicationState);
      
      if (result.isError) {
        return Result.error(result.error);
      }

      final stateData = result.value;
      if (stateData == null) {
        return const Result.success(null);
      }

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
    try {      final stateResult = await loadApplicationState();
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
    } catch (e) {      return Result.error(StorageException(
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
      }      final currentState = stateResult.value ?? ApplicationState();
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
  Future<Result<void, StorageException>> markAsChanged() async {    try {
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

  @override  Future<Result<void, StorageException>> saveUserConfiguration(UserConfiguration config) async {
    try {
      final result = await _dataSource.store(
        StorageKeys.userConfiguration,
        config.toMap(),
      );

      if (result.isError) {
        return Result.error(result.error);
      }

      // Update metadata after save
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
      final result = await _dataSource.retrieve(StorageKeys.userConfiguration);
      
      if (result.isError) {
        return Result.error(result.error);
      }

      final configData = result.value;
      if (configData == null) {
        return const Result.success(null);
      }

      final config = UserConfiguration.fromMap(configData);
      return Result.success(config);
    } catch (e) {      return Result.error(StorageException(
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
      final updatedConfig = currentConfig.copyWith(        enableNotifications: enableNotifications,
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
  Future<Result<void, StorageException>> updateInitiativeDefaults(InitiativeDefaults defaults) async {    try {
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
  }) async {    try {
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
      final result = await _dataSource.store(
        StorageKeys.sessionRecovery,
        data.toMap(),
      );

      if (result.isError) {
        return Result.error(result.error);
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
  Future<Result<SessionRecoveryData?, StorageException>> loadSessionRecovery() async {    try {
      final result = await _dataSource.retrieve(StorageKeys.sessionRecovery);
      
      if (result.isError) {
        return Result.error(result.error);
      }

      final recoveryData = result.value;
      if (recoveryData == null) {
        return const Result.success(null);
      }

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
      final result = await _dataSource.remove(StorageKeys.sessionRecovery);
      
      if (result.isError) {
        return Result.error(result.error);
      }

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
    } catch (e) {      return Result.error(StorageException(
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
      final Map<String, dynamic> backup = jsonDecode(backupData);      // Restore application state if present
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

  @override  Future<Result<ConfigurationMetadata, StorageException>> getConfigurationMetadata() async {
    try {
      final result = await _dataSource.retrieve(StorageKeys.configurationMetadata);
      
      if (result.isSuccess && result.value != null) {
        final metadataData = result.value!;
        final metadata = ConfigurationMetadata.fromMap(metadataData);
        return Result.success(metadata);
      }

      // Generate metadata if not exists
      final now = DateTime.now();
      final hasAppState = await _dataSource.exists(StorageKeys.applicationState);
      final hasUserConfig = await _dataSource.exists(StorageKeys.userConfiguration);
      final hasSessionRecovery = await _dataSource.exists(StorageKeys.sessionRecovery);

      final metadata = ConfigurationMetadata(
        version: 1,
        createdAt: now,
        lastModified: now,
        hasApplicationState: hasAppState.valueOrNull ?? false,
        hasUserConfiguration: hasUserConfig.valueOrNull ?? false,
        hasSessionRecovery: hasSessionRecovery.valueOrNull ?? false,
        dataSize: await _calculateDataSize(),
      );

      // Save the generated metadata
      await _dataSource.store(StorageKeys.configurationMetadata, metadata.toMap());

      return Result.success(metadata);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get configuration metadata: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  // Utility Operations

  @override  Future<Result<void, ValidationException>> validateConfiguration(UserConfiguration config) async {
    return config.validate();
  }

  @override
  Future<Result<void, StorageException>> resetToDefaults() async {
    try {
      // Clear all existing data
      await _dataSource.remove(StorageKeys.applicationState);
      await _dataSource.remove(StorageKeys.userConfiguration);
      await _dataSource.remove(StorageKeys.sessionRecovery);
      await _dataSource.remove(StorageKeys.configurationMetadata);

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
    } catch (e) {      return Result.error(StorageException(
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
  Future<Result<void, StorageException>> clearAllConfiguration() async {    try {
      await _dataSource.remove(StorageKeys.applicationState);
      await _dataSource.remove(StorageKeys.userConfiguration);
      await _dataSource.remove(StorageKeys.sessionRecovery);
      await _dataSource.remove(StorageKeys.configurationMetadata);
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
      final hasAppState = await _dataSource.exists(StorageKeys.applicationState);
      final hasUserConfig = await _dataSource.exists(StorageKeys.userConfiguration);
      final hasSessionRecovery = await _dataSource.exists(StorageKeys.sessionRecovery);

      // Try to load existing metadata to preserve creation date
      DateTime createdAt = now;
      final existingResult = await _dataSource.retrieve(StorageKeys.configurationMetadata);
      if (existingResult.isSuccess && existingResult.value != null) {
        try {
          final existingData = existingResult.value!;
          createdAt = DateTime.parse(existingData['createdAt'] as String);
        } catch (_) {
          // Use current time if can't parse existing
        }
      }

      final metadata = ConfigurationMetadata(
        version: version ?? 1,
        createdAt: createdAt,
        lastModified: now,        hasApplicationState: hasAppState.valueOrNull ?? false,
        hasUserConfiguration: hasUserConfig.valueOrNull ?? false,
        hasSessionRecovery: hasSessionRecovery.valueOrNull ?? false,
        dataSize: await _calculateDataSize(),
      );

      await _dataSource.store(StorageKeys.configurationMetadata, metadata.toMap());
    } catch (_) {
      // Ignore metadata update failures - not critical
    }
  }

  Future<int> _calculateDataSize() async {
    int size = 0;
    
    final appStateResult = await _dataSource.retrieve(StorageKeys.applicationState);
    if (appStateResult.isSuccess && appStateResult.value != null) {
      size += jsonEncode(appStateResult.value!).length;
    }
    
    final userConfigResult = await _dataSource.retrieve(StorageKeys.userConfiguration);
    if (userConfigResult.isSuccess && userConfigResult.value != null) {
      size += jsonEncode(userConfigResult.value!).length;
    }
    
    final sessionRecoveryResult = await _dataSource.retrieve(StorageKeys.sessionRecovery);
    if (sessionRecoveryResult.isSuccess && sessionRecoveryResult.value != null) {
      size += jsonEncode(sessionRecoveryResult.value!).length;
    }
    
    return size;
  }
}
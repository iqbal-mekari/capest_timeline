import '../entities/application_state.dart';
import '../entities/user_configuration.dart';
import '../repositories/configuration_repository.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/themes/app_theme.dart';

/// Use case for managing application state and view settings
class ManageApplicationState {
  const ManageApplicationState({
    required this.configRepository,
  });

  final ConfigurationRepository configRepository;

  /// Loads the current application state
  Future<Result<ApplicationState, Exception>> loadApplicationState() async {
    final result = await configRepository.loadApplicationState();
    if (result.isError) {
      return Result.error(result.error);
    }

    // Return default state if none exists
    return Result.success(result.value ?? const ApplicationState());
  }

  /// Updates the current view mode
  Future<Result<void, Exception>> updateViewMode(ViewMode newMode) async {
    final stateResult = await loadApplicationState();
    if (stateResult.isError) {
      return Result.error(stateResult.error);
    }

    final currentState = stateResult.value;
    final updatedState = currentState.withViewSettings(viewMode: newMode);

    final saveResult = await configRepository.saveApplicationState(updatedState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Sets the active quarter plan
  Future<Result<void, Exception>> setActiveQuarterPlan(String planId) async {
    final stateResult = await loadApplicationState();
    if (stateResult.isError) {
      return Result.error(stateResult.error);
    }

    final currentState = stateResult.value;
    final updatedState = currentState.withCurrentPlan(planId);

    final saveResult = await configRepository.saveApplicationState(updatedState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Updates filter settings
  Future<Result<void, Exception>> updateFilters({
    bool? showCompletedInitiatives,
    bool? showInactiveMembers,
    Set<String>? roleFilter,
    String? searchQuery,
    (int, int)? priorityRange,
    (double, double)? capacityUtilizationRange,
  }) async {
    final stateResult = await loadApplicationState();
    if (stateResult.isError) {
      return Result.error(stateResult.error);
    }

    final currentState = stateResult.value;
    final currentFilters = currentState.filters;

    // Create updated filters
    final updatedFilters = currentFilters.copyWith(
      showCompletedInitiatives: showCompletedInitiatives,
      showInactiveMembers: showInactiveMembers,
      roleFilter: roleFilter,
      searchQuery: searchQuery,
      priorityRange: priorityRange,
      capacityUtilizationRange: capacityUtilizationRange,
    );

    final updatedState = currentState.copyWith(
      filters: updatedFilters,
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );

    final saveResult = await configRepository.saveApplicationState(updatedState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Clears all filters
  Future<Result<void, Exception>> clearAllFilters() async {
    final stateResult = await loadApplicationState();
    if (stateResult.isError) {
      return Result.error(stateResult.error);
    }

    final currentState = stateResult.value;
    final clearedFilters = const ApplicationFilters();

    final updatedState = currentState.copyWith(
      filters: clearedFilters,
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );

    final saveResult = await configRepository.saveApplicationState(updatedState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Updates selected quarter and year
  Future<Result<void, Exception>> updateQuarterYear({
    int? quarter,
    int? year,
  }) async {
    final stateResult = await loadApplicationState();
    if (stateResult.isError) {
      return Result.error(stateResult.error);
    }

    final currentState = stateResult.value;
    final updatedState = currentState.withViewSettings(
      quarter: quarter,
      year: year,
    );

    final saveResult = await configRepository.saveApplicationState(updatedState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Toggles auto-save feature
  Future<Result<void, Exception>> toggleAutoSave(bool enabled) async {
    final stateResult = await loadApplicationState();
    if (stateResult.isError) {
      return Result.error(stateResult.error);
    }

    final currentState = stateResult.value;
    final updatedState = currentState.copyWith(
      isAutoSaveEnabled: enabled,
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );

    final saveResult = await configRepository.saveApplicationState(updatedState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Marks the application state as saved
  Future<Result<void, Exception>> markAsSaved() async {
    final stateResult = await loadApplicationState();
    if (stateResult.isError) {
      return Result.error(stateResult.error);
    }

    final currentState = stateResult.value;
    final updatedState = currentState.markAsSaved();

    final saveResult = await configRepository.saveApplicationState(updatedState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Resets application state to defaults
  Future<Result<void, Exception>> resetToDefaults() async {
    final defaultState = ApplicationState(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final saveResult = await configRepository.saveApplicationState(defaultState);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }
}

/// Use case for managing user configuration and preferences
class ManageUserConfiguration {
  const ManageUserConfiguration({
    required this.configRepository,
  });

  final ConfigurationRepository configRepository;

  /// Loads user configuration
  Future<Result<UserConfiguration, Exception>> loadUserConfiguration() async {
    final result = await configRepository.loadUserConfiguration();
    if (result.isError) {
      return Result.error(result.error);
    }

    // Return default configuration if none exists
    return Result.success(result.value ?? const UserConfiguration());
  }

  /// Updates theme mode
  Future<Result<void, Exception>> updateTheme(AppThemeMode themeMode) async {
    final configResult = await loadUserConfiguration();
    if (configResult.isError) {
      return Result.error(configResult.error);
    }

    final currentConfig = configResult.value;
    final updatedConfig = currentConfig.copyWith(
      theme: themeMode,
      updatedAt: DateTime.now(),
    );

    final saveResult = await configRepository.saveUserConfiguration(updatedConfig);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Updates default preferences
  Future<Result<void, Exception>> updateDefaultPreferences({
    double? defaultWeeklyCapacity,
    int? defaultQuarterWeeks,
    bool? enableNotifications,
    int? autoSaveInterval,
    String? defaultViewMode,
    CapacityDisplayMode? capacityDisplayMode,
  }) async {
    final configResult = await loadUserConfiguration();
    if (configResult.isError) {
      return Result.error(configResult.error);
    }

    final currentConfig = configResult.value;

    // Validate inputs
    if (defaultWeeklyCapacity != null && (defaultWeeklyCapacity <= 0 || defaultWeeklyCapacity > 1.0)) {
      return Result.error(
        ValidationException(
          'Default weekly capacity must be between 0 and 1.0',
          ValidationErrorType.businessRuleViolation,
          {'defaultWeeklyCapacity': ['Must be between 0 and 1.0']},
        ),
      );
    }

    if (defaultQuarterWeeks != null && (defaultQuarterWeeks < 10 || defaultQuarterWeeks > 16)) {
      return Result.error(
        ValidationException(
          'Default quarter weeks must be between 10 and 16',
          ValidationErrorType.businessRuleViolation,
          {'defaultQuarterWeeks': ['Must be between 10 and 16']},
        ),
      );
    }

    if (autoSaveInterval != null && (autoSaveInterval < 5 || autoSaveInterval > 300)) {
      return Result.error(
        ValidationException(
          'Auto-save interval must be between 5 and 300 seconds',
          ValidationErrorType.businessRuleViolation,
          {'autoSaveInterval': ['Must be between 5 and 300 seconds']},
        ),
      );
    }

    // Create updated configuration
    final updatedConfig = currentConfig.copyWith(
      defaultWeeklyCapacity: defaultWeeklyCapacity,
      defaultQuarterWeeks: defaultQuarterWeeks,
      enableNotifications: enableNotifications,
      autoSaveInterval: autoSaveInterval,
      defaultViewMode: defaultViewMode,
      capacityDisplayMode: capacityDisplayMode,
      updatedAt: DateTime.now(),
    );

    final saveResult = await configRepository.saveUserConfiguration(updatedConfig);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Toggles the welcome guide display
  Future<Result<void, Exception>> toggleWelcomeGuide(bool show) async {
    final configResult = await loadUserConfiguration();
    if (configResult.isError) {
      return Result.error(configResult.error);
    }

    final currentConfig = configResult.value;
    final updatedConfig = currentConfig.copyWith(
      showWelcomeGuide: show,
      updatedAt: DateTime.now(),
    );

    final saveResult = await configRepository.saveUserConfiguration(updatedConfig);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Resets user configuration to defaults
  Future<Result<void, Exception>> resetToDefaults() async {
    final defaultConfig = UserConfiguration(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final saveResult = await configRepository.saveUserConfiguration(defaultConfig);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return const Result.success(null);
  }

  /// Exports user configuration for backup
  Future<Result<Map<String, dynamic>, Exception>> exportConfiguration() async {
    final configResult = await loadUserConfiguration();
    if (configResult.isError) {
      return Result.error(configResult.error);
    }

    final config = configResult.value;
    final exportData = {
      'userConfiguration': config.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    return Result.success(exportData);
  }

  /// Imports user configuration from backup
  Future<Result<void, Exception>> importConfiguration(Map<String, dynamic> data) async {
    try {
      // Validate import data structure
      if (!data.containsKey('userConfiguration')) {
        return Result.error(
          ValidationException(
            'Invalid import data: missing userConfiguration',
            ValidationErrorType.businessRuleViolation,
            {'data': ['Missing required field: userConfiguration']},
          ),
        );
      }

      // Parse configuration
      final configData = data['userConfiguration'] as Map<String, dynamic>;
      final config = UserConfiguration.fromMap(configData);

      // Validate configuration
      final validationResult = config.validate();
      if (validationResult.isError) {
        return Result.error(validationResult.error);
      }

      // Save imported configuration
      final saveResult = await configRepository.saveUserConfiguration(config);
      if (saveResult.isError) {
        return Result.error(saveResult.error);
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        ValidationException(
          'Failed to import configuration: ${e.toString()}',
          ValidationErrorType.businessRuleViolation,
          {'error': [e.toString()]},
        ),
      );
    }
  }
}

/// Use case for managing application-wide settings and initialization
class InitializeApplication {
  const InitializeApplication({
    required this.configRepository,
  });

  final ConfigurationRepository configRepository;

  /// Initializes the application with default settings
  Future<Result<InitializationResult, Exception>> execute() async {
    try {
      // Load or create application state
      final stateResult = await configRepository.loadApplicationState();
      ApplicationState appState;
      
      if (stateResult.isError) {
        // Create default state if loading fails
        appState = ApplicationState(createdAt: DateTime.now(), updatedAt: DateTime.now());
        final saveStateResult = await configRepository.saveApplicationState(appState);
        if (saveStateResult.isError) {
          return Result.error(saveStateResult.error);
        }
      } else {
        appState = stateResult.value ?? ApplicationState(createdAt: DateTime.now(), updatedAt: DateTime.now());
      }

      // Load or create user configuration
      final configResult = await configRepository.loadUserConfiguration();
      UserConfiguration userConfig;
      
      if (configResult.isError) {
        // Create default configuration if loading fails
        userConfig = UserConfiguration(createdAt: DateTime.now(), updatedAt: DateTime.now());
        final saveConfigResult = await configRepository.saveUserConfiguration(userConfig);
        if (saveConfigResult.isError) {
          return Result.error(saveConfigResult.error);
        }
      } else {
        userConfig = configResult.value ?? UserConfiguration(createdAt: DateTime.now(), updatedAt: DateTime.now());
      }

      // Check if this is first-time setup
      final isFirstTime = appState.createdAt?.isAfter(DateTime.now().subtract(const Duration(minutes: 1))) ?? true;

      // Create initialization result
      final result = InitializationResult(
        applicationState: appState,
        userConfiguration: userConfig,
        isFirstTimeSetup: isFirstTime,
        initializationTime: DateTime.now(),
      );

      return Result.success(result);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to initialize application: ${e.toString()}',
          StorageErrorType.unknown,
          e is Exception ? e : null,
        ),
      );
    }
  }

  /// Performs cleanup operations
  Future<Result<void, Exception>> cleanup() async {
    // Currently no cleanup operations needed
    return const Result.success(null);
  }
}

/// Result of application initialization
class InitializationResult {
  const InitializationResult({
    required this.applicationState,
    required this.userConfiguration,
    required this.isFirstTimeSetup,
    required this.initializationTime,
  });

  final ApplicationState applicationState;
  final UserConfiguration userConfiguration;
  final bool isFirstTimeSetup;
  final DateTime initializationTime;

  /// Whether the application needs to show onboarding
  bool get needsOnboarding => isFirstTimeSetup;

  /// Current theme mode from user configuration
  AppThemeMode get themeMode => userConfiguration.theme;

  /// Current view mode from application state
  ViewMode get viewMode => applicationState.viewMode;
}
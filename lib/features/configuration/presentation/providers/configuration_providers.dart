/// UI state management using ChangeNotifier for configuration features.
/// 
/// This file contains ChangeNotifier classes that manage UI state for
/// application configuration and user preferences.
library;

import 'package:flutter/foundation.dart';

// Domain entities
import '../../domain/entities/application_state.dart';
import '../../domain/entities/user_configuration.dart';

// Use cases
import '../../domain/usecases/configuration_usecases.dart';

// Shared
import '../../../../shared/themes/app_theme.dart';



/// State management for application state operations
class ApplicationStateProvider extends ChangeNotifier {
  ApplicationStateProvider({
    required ManageApplicationState manageApplicationState,
    required InitializeApplication initializeApplication,
  }) : _manageApplicationState = manageApplicationState,
       _initializeApplication = initializeApplication;

  final ManageApplicationState _manageApplicationState;
  final InitializeApplication _initializeApplication;

  // State variables
  ApplicationState? _applicationState;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  ApplicationState? get applicationState => _applicationState;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isInitialized => _isInitialized;
  ViewMode get currentViewMode => _applicationState?.viewMode ?? ViewMode.timeline;
  String? get currentPlanId => _applicationState?.currentPlanId;
  ApplicationFilters get filters => _applicationState?.filters ?? const ApplicationFilters();
  bool get hasUnsavedChanges => _applicationState?.hasUnsavedChanges ?? false;

  /// Initializes the application
  Future<bool> initialize() async {
    _setLoading(true);
    _clearError();

    final result = await _initializeApplication.execute();
    
    if (result.isSuccess) {
      _applicationState = result.value.applicationState;
      _isInitialized = true;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Loads the current application state
  Future<bool> loadApplicationState() async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.loadApplicationState();
    
    if (result.isSuccess) {
      _applicationState = result.value;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Updates the view mode
  Future<bool> updateViewMode(ViewMode newMode) async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.updateViewMode(newMode);
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sets the active quarter plan
  Future<bool> setActiveQuarterPlan(String planId) async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.setActiveQuarterPlan(planId);
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Updates filter settings
  Future<bool> updateFilters({
    bool? showCompletedInitiatives,
    bool? showInactiveMembers,
    Set<String>? roleFilter,
    String? searchQuery,
    (int, int)? priorityRange,
    (double, double)? capacityUtilizationRange,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.updateFilters(
      showCompletedInitiatives: showCompletedInitiatives,
      showInactiveMembers: showInactiveMembers,
      roleFilter: roleFilter,
      searchQuery: searchQuery,
      priorityRange: priorityRange,
      capacityUtilizationRange: capacityUtilizationRange,
    );
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Clears all filters
  Future<bool> clearAllFilters() async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.clearAllFilters();
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());       
      _setLoading(false);
      return false;
    }
  }

  /// Updates selected quarter and year
  Future<bool> updateQuarterYear({
    int? quarter,
    int? year,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.updateQuarterYear(
      quarter: quarter,
      year: year,
    );
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Toggles auto-save feature
  Future<bool> toggleAutoSave(bool enabled) async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.toggleAutoSave(enabled);
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Marks the application state as saved
  Future<bool> markAsSaved() async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.markAsSaved();
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Resets application state to defaults
  Future<bool> resetToDefaults() async {
    _setLoading(true);
    _clearError();

    final result = await _manageApplicationState.resetToDefaults();
    
    if (result.isSuccess) {
      await loadApplicationState(); // Refresh state
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

/// State management for user configuration operations
class UserConfigurationProvider extends ChangeNotifier {
  UserConfigurationProvider({
    required ManageUserConfiguration manageUserConfiguration,
  }) : _manageUserConfiguration = manageUserConfiguration;

  final ManageUserConfiguration _manageUserConfiguration;

  // State variables
  UserConfiguration? _userConfiguration;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserConfiguration? get userConfiguration => _userConfiguration;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  AppThemeMode get currentTheme => _userConfiguration?.theme ?? AppThemeMode.system;
  bool get showWelcomeGuide => _userConfiguration?.showWelcomeGuide ?? true;
  double get defaultWeeklyCapacity => _userConfiguration?.defaultWeeklyCapacity ?? 0.8;
  int get defaultQuarterWeeks => _userConfiguration?.defaultQuarterWeeks ?? 13;
  bool get enableNotifications => _userConfiguration?.enableNotifications ?? true;
  int get autoSaveInterval => _userConfiguration?.autoSaveInterval ?? 30;

  /// Loads user configuration
  Future<bool> loadUserConfiguration() async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.loadUserConfiguration();
    
    if (result.isSuccess) {
      _userConfiguration = result.value;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Updates theme mode
  Future<bool> updateTheme(AppThemeMode themeMode) async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.updateTheme(themeMode);
    
    if (result.isSuccess) {
      await loadUserConfiguration(); // Refresh configuration
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Updates default preferences
  Future<bool> updateDefaultPreferences({
    double? defaultWeeklyCapacity,
    int? defaultQuarterWeeks,
    bool? enableNotifications,
    int? autoSaveInterval,
    String? defaultViewMode,
    CapacityDisplayMode? capacityDisplayMode,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.updateDefaultPreferences(
      defaultWeeklyCapacity: defaultWeeklyCapacity,
      defaultQuarterWeeks: defaultQuarterWeeks,
      enableNotifications: enableNotifications,
      autoSaveInterval: autoSaveInterval,
      defaultViewMode: defaultViewMode,
      capacityDisplayMode: capacityDisplayMode,
    );
    
    if (result.isSuccess) {
      await loadUserConfiguration(); // Refresh configuration
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Toggles the welcome guide display
  Future<bool> toggleWelcomeGuide(bool show) async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.toggleWelcomeGuide(show);
    
    if (result.isSuccess) {
      await loadUserConfiguration(); // Refresh configuration
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Resets user configuration to defaults
  Future<bool> resetToDefaults() async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.resetToDefaults();
    
    if (result.isSuccess) {
      await loadUserConfiguration(); // Refresh configuration
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Exports user configuration for backup
  Future<Map<String, dynamic>?> exportConfiguration() async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.exportConfiguration();
    
    if (result.isSuccess) {
      _setLoading(false);
      return result.value;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return null;
    }
  }

  /// Imports user configuration from backup
  Future<bool> importConfiguration(Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.importConfiguration(data);
    
    if (result.isSuccess) {
      await loadUserConfiguration(); // Refresh configuration
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
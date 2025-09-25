import 'package:flutter/foundation.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../shared/themes/app_theme.dart';
import '../../domain/entities/user_configuration.dart';
import '../../domain/usecases/configuration_usecases.dart';

/// Provider for application configuration management.
/// 
/// This provider handles:
/// - Loading and saving configuration settings
/// - Theme management
/// - Auto-save settings
/// - Form state for configuration dialogs
class ConfigurationProvider extends ChangeNotifier {
  ConfigurationProvider({
    required ManageUserConfiguration manageUserConfiguration,
  }) : _manageUserConfiguration = manageUserConfiguration;

  final ManageUserConfiguration _manageUserConfiguration;

  // State variables
  UserConfiguration? _configuration;
  bool _isLoading = false;
  String? _error;
  bool _hasUnsavedChanges = false;

  // Form state
  bool _isFormLoading = false;
  Map<String, String> _formErrors = {};

  // Getters
  UserConfiguration? get configuration => _configuration;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  
  // Form state getters
  bool get isFormLoading => _isFormLoading;
  Map<String, String> get formErrors => Map.unmodifiable(_formErrors);
  bool get hasFormErrors => _formErrors.isNotEmpty;

  // Convenience getters for configuration values
  AppThemeMode get theme => _configuration?.theme ?? AppThemeMode.system;
  int get autoSaveInterval => _configuration?.autoSaveInterval ?? 30;
  bool get enableNotifications => _configuration?.enableNotifications ?? true;
  String get timeZone => _configuration?.timeZone ?? 'UTC';
  String get dateFormat => _configuration?.dateFormat ?? 'yyyy-MM-dd';

  /// Loads the application configuration
  Future<void> loadConfiguration() async {
    _setLoading(true);
    _clearError();

    final result = await _manageUserConfiguration.loadUserConfiguration();

    if (result.isSuccess) {
      _configuration = result.value;
      _hasUnsavedChanges = false;
      _setLoading(false);
    } else {
      _setError(result.error.toString());
      _setLoading(false);
    }
  }

  /// Saves the current configuration
  Future<bool> saveConfiguration() async {
    if (_configuration == null) {
      _setError('No configuration to save');
      return false;
    }

    _setFormLoading(true);
    _clearFormErrors();

    // Use the update methods since we don't have a direct save method
    final result = await _manageUserConfiguration.updateDefaultPreferences();

    if (result.isSuccess) {
      _hasUnsavedChanges = false;
      _setFormLoading(false);
      return true;
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
      return false;
    }
  }

  /// Updates the theme setting
  Future<void> updateTheme(AppThemeMode theme) async {
    _setFormLoading(true);
    _clearFormErrors();

    final result = await _manageUserConfiguration.updateTheme(theme);

    if (result.isSuccess) {
      await loadConfiguration(); // Refresh configuration
      _setFormLoading(false);
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
    }
  }

  /// Updates the auto-save interval
  Future<void> updateAutoSaveInterval(int intervalSeconds) async {
    _setFormLoading(true);
    _clearFormErrors();

    final result = await _manageUserConfiguration.updateDefaultPreferences(
      autoSaveInterval: intervalSeconds,
    );

    if (result.isSuccess) {
      await loadConfiguration(); // Refresh configuration
      _setFormLoading(false);
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
    }
  }

  /// Updates the notifications setting
  Future<void> updateNotifications(bool enableNotifications) async {
    _setFormLoading(true);
    _clearFormErrors();

    final result = await _manageUserConfiguration.updateDefaultPreferences(
      enableNotifications: enableNotifications,
    );

    if (result.isSuccess) {
      await loadConfiguration(); // Refresh configuration  
      _setFormLoading(false);
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
    }
  }

  /// Updates default preferences
  Future<void> updateDefaultPreferences({
    double? defaultWeeklyCapacity,
    int? defaultQuarterWeeks,
    CapacityDisplayMode? capacityDisplayMode,
  }) async {
    _setFormLoading(true);
    _clearFormErrors();

    final result = await _manageUserConfiguration.updateDefaultPreferences(
      defaultWeeklyCapacity: defaultWeeklyCapacity,
      defaultQuarterWeeks: defaultQuarterWeeks,
      capacityDisplayMode: capacityDisplayMode,
    );

    if (result.isSuccess) {
      await loadConfiguration(); // Refresh configuration
      _setFormLoading(false);
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
    }
  }

  /// Validates the current configuration
  Future<bool> validateConfiguration() async {
    if (_configuration == null) {
      _setError('No configuration to validate');
      return false;
    }

    _clearFormErrors();

    final result = _configuration!.validate();

    if (result.isSuccess) {
      return true;
    } else {
      _handleFormValidationError(result.error);
      return false;
    }
  }

  /// Resets configuration to defaults
  Future<void> resetToDefaults() async {
    _setFormLoading(true);
    _clearFormErrors();

    final result = await _manageUserConfiguration.resetToDefaults();

    if (result.isSuccess) {
      await loadConfiguration(); // Refresh configuration
      _setFormLoading(false);
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
    }
  }

  /// Discards unsaved changes
  Future<void> discardChanges() async {
    if (_hasUnsavedChanges) {
      await loadConfiguration();
    }
  }



  /// Handles form validation errors
  void _handleFormValidationError(Exception error) {
    _formErrors.clear();
    
    if (error is ValidationException) {
      if (error.fieldErrors.isNotEmpty) {
        _formErrors.addAll(error.fieldErrors.map(
          (key, value) => MapEntry(key, value.join(', '))
        ));
      } else {
        _formErrors['general'] = error.message;
      }
    } else {
      _formErrors['general'] = error.toString();
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setFormLoading(bool loading) {
    _isFormLoading = loading;
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

  void _clearFormErrors() {
    _formErrors.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _formErrors.clear();
    super.dispose();
  }
}
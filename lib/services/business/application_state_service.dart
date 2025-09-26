import 'dart:async';

import '../../features/configuration/domain/entities/application_state.dart';
import '../../features/configuration/domain/entities/user_configuration.dart';
import '../../features/capacity_planning/domain/entities/quarter_plan.dart';
import '../../core/types/result.dart';
import '../../core/errors/exceptions.dart';
import '../../features/configuration/data/datasources/local_storage_datasource.dart';

/// Service for managing application state with persistence and auto-save functionality.
/// 
/// This service handles:
/// - Loading and saving application state
/// - Managing current quarter plan state
/// - Auto-save functionality with configurable intervals
/// - State validation and migration
/// - Recent plans tracking
class ApplicationStateService {
  ApplicationStateService({
    required LocalStorageDataSource storageDataSource,
    UserConfiguration? userConfiguration,
  }) : _storageDataSource = storageDataSource,
       _userConfiguration = userConfiguration ?? const UserConfiguration();

  final LocalStorageDataSource _storageDataSource;
  UserConfiguration _userConfiguration; 
  ApplicationState? _currentState;
  Timer? _autoSaveTimer;
  
  // Stream controllers for reactive updates
  final StreamController<ApplicationState> _stateController = StreamController<ApplicationState>.broadcast();
  final StreamController<UserConfiguration> _configController = StreamController<UserConfiguration>.broadcast();
  
  // Auto-save tracking
  DateTime? _lastAutoSave;
  bool _hasUnsavedChanges = false;

  // Getters
  ApplicationState? get currentState => _currentState;
  UserConfiguration get userConfiguration => _userConfiguration;
  Stream<ApplicationState> get stateStream => _stateController.stream;
  Stream<UserConfiguration> get configurationStream => _configController.stream;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  DateTime? get lastAutoSave => _lastAutoSave;
  
  /// Initializes the service by loading saved state
  Future<Result<void, StorageException>> initialize() async {
    try {
      // Load user configuration first
      final configResult = await _loadUserConfiguration();
      if (configResult.isError) {
        // Use default configuration if loading fails
        _userConfiguration = const UserConfiguration();
      } else {
        _userConfiguration = configResult.value;
      }

      // Load application state
      final stateResult = await _loadApplicationState();
      if (stateResult.isSuccess) {
        _currentState = stateResult.value;
      } else {
        // Create default state if loading fails
        _currentState = ApplicationState(
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Start auto-save timer if enabled
      _startAutoSaveTimer();

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to initialize application state service: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Loads user configuration from storage
  Future<Result<UserConfiguration, StorageException>> _loadUserConfiguration() async {
    try {
      final data = await _storageDataSource.getUserConfiguration();
      return data != null 
          ? Result.success(UserConfiguration.fromMap(data))
          : Result.error(const StorageException(
              'No user configuration found',
              StorageErrorType.notAvailable,
            ));
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load user configuration: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  /// Loads application state from storage
  Future<Result<ApplicationState, StorageException>> _loadApplicationState() async {
    try {
      final data = await _storageDataSource.getApplicationState();
      return data != null 
          ? Result.success(ApplicationState.fromMap(data))
          : Result.error(const StorageException(
              'No application state found',
              StorageErrorType.notAvailable,
            ));
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load application state: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  /// Updates the current application state
  Future<Result<void, ValidationException>> updateState(ApplicationState newState) async {
    final validation = newState.validate();
    if (validation.isError) {
      return validation;
    }

    _currentState = newState.copyWith(
      updatedAt: DateTime.now(),
      hasUnsavedChanges: true,
    );
    
    _hasUnsavedChanges = true;
    _stateController.add(_currentState!);
    
    // Trigger auto-save if conditions are met
    if (_shouldAutoSave()) {
      await _performAutoSave();
    }

    return const Result.success(null);
  }

  /// Sets the current quarter plan
  Future<Result<void, ValidationException>> setCurrentPlan(String? planId) async {
    if (_currentState == null) {
      return Result.error(const ValidationException(
        'Application state not initialized',
        ValidationErrorType.missingRequiredField,
      ));
    }

    final updatedState = _currentState!.withCurrentPlan(planId);
    return await updateState(updatedState);
  }

  /// Updates view settings
  Future<Result<void, ValidationException>> updateViewSettings({
    ViewMode? viewMode,
    int? quarter,
    int? year,
  }) async {
    if (_currentState == null) {
      return Result.error(const ValidationException(
        'Application state not initialized',
        ValidationErrorType.missingRequiredField,
      ));
    }

    final updatedState = _currentState!.withViewSettings(
      viewMode: viewMode,
      quarter: quarter,
      year: year,
    );
    
    return await updateState(updatedState);
  }

  /// Updates user configuration
  Future<Result<void, ValidationException>> updateUserConfiguration(UserConfiguration config) async {
    final validation = config.validate();
    if (validation.isError) {
      return validation;
    }

    _userConfiguration = config.copyWith(updatedAt: DateTime.now());
    _configController.add(_userConfiguration);
    
    // Update auto-save timer if interval changed
    if (config.autoSaveInterval != _userConfiguration.autoSaveInterval) {
      _startAutoSaveTimer();
    }

    // Save configuration immediately
    await _saveUserConfiguration();
    
    return const Result.success(null);
  }

  /// Saves the current state to storage
  Future<Result<void, StorageException>> saveState() async {
    if (_currentState == null) {
      return Result.error(const StorageException(
        'No application state to save',
        StorageErrorType.notAvailable,
      ));
    }

    try {
      final stateToSave = _currentState!.markAsSaved();
      await _storageDataSource.saveApplicationState(stateToSave.toMap());
      
      _currentState = stateToSave;
      _hasUnsavedChanges = false;
      _lastAutoSave = DateTime.now();
      
      _stateController.add(_currentState!);
      
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save application state: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Saves user configuration to storage
  Future<Result<void, StorageException>> _saveUserConfiguration() async {
    try {
      await _storageDataSource.saveUserConfiguration(_userConfiguration.toMap());
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save user configuration: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Saves a quarter plan to storage
  Future<Result<void, StorageException>> saveQuarterPlan(QuarterPlan plan) async {
    final validation = plan.validate();
    if (validation.isError) {
      return Result.error(StorageException(
        'Invalid quarter plan: ${validation.error}',
        StorageErrorType.dataCorrupted,
      ));
    }

    try {
      await _storageDataSource.saveQuarterPlan(plan.id, plan.toMap());
      
      // Update current plan if it's the same
      if (_currentState?.currentPlanId == plan.id) {
        await setCurrentPlan(plan.id);
      }
      
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save quarter plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Loads a quarter plan from storage
  Future<Result<QuarterPlan, StorageException>> loadQuarterPlan(String planId) async {
    try {
      final data = await _storageDataSource.getQuarterPlan(planId);
      if (data == null) {
        return Result.error(StorageException(
          'Quarter plan not found: $planId',
          StorageErrorType.notAvailable,
        ));
      }
      
      final plan = QuarterPlan.fromMap(data);
      return Result.success(plan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load quarter plan: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  /// Gets a list of all saved quarter plans
  Future<Result<List<QuarterPlanSummary>, StorageException>> getQuarterPlanSummaries() async {
    try {
      final summaries = await _storageDataSource.getQuarterPlanSummaries();
      return Result.success(summaries.map((data) => QuarterPlanSummary.fromMap(data)).toList());
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load quarter plan summaries: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Deletes a quarter plan from storage
  Future<Result<void, StorageException>> deleteQuarterPlan(String planId) async {
    try {
      await _storageDataSource.deleteQuarterPlan(planId);
      
      // Clear current plan if it was deleted
      if (_currentState?.currentPlanId == planId) {
        await setCurrentPlan(null);
      }
      
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to delete quarter plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Starts the auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    
    if (_userConfiguration.enableNotifications && _userConfiguration.autoSaveInterval > 0) {
      _autoSaveTimer = Timer.periodic(
        _userConfiguration.autoSaveIntervalDuration,
        (_) => _performAutoSave(),
      );
    }
  }

  /// Checks if auto-save should be performed
  bool _shouldAutoSave() {
    if (!_userConfiguration.enableNotifications || !_hasUnsavedChanges) {
      return false;
    }

    if (_lastAutoSave == null) return true;
    
    final timeSinceLastSave = DateTime.now().difference(_lastAutoSave!);
    return timeSinceLastSave >= _userConfiguration.autoSaveIntervalDuration;
  }

  /// Performs auto-save operation
  Future<void> _performAutoSave() async {
    if (_currentState != null && _hasUnsavedChanges) {
      await saveState();
    }
  }

  /// Exports application data for backup
  Future<Result<Map<String, dynamic>, StorageException>> exportData() async {
    try {
      final data = await _storageDataSource.exportAllData();
      return Result.success(data);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to export data: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Imports application data from backup
  Future<Result<void, StorageException>> importData(Map<String, dynamic> data) async {
    try {
      await _storageDataSource.importAllData(data);
      
      // Reload state after import
      await initialize();
      
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to import data: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  /// Clears all stored data
  Future<Result<void, StorageException>> clearAllData() async {
    try {
      await _storageDataSource.clearAllData();
      
      // Reset to default state
      _currentState = ApplicationState(
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _userConfiguration = const UserConfiguration();
      _hasUnsavedChanges = false;
      _lastAutoSave = null;
      
      _stateController.add(_currentState!);
      _configController.add(_userConfiguration);
      
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to clear data: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  /// Disposes the service and cleans up resources
  void dispose() {
    _autoSaveTimer?.cancel();
    _stateController.close();
    _configController.close();
  }
}

/// Summary information about a quarter plan for listing purposes
class QuarterPlanSummary {
  const QuarterPlanSummary({
    required this.id,
    required this.displayName,
    required this.quarter,
    required this.year,
    required this.totalInitiatives,
    required this.totalTeamMembers,
    required this.capacityUtilization,
    required this.lastModified,
  });

  final String id;
  final String displayName;
  final int quarter;
  final int year;
  final int totalInitiatives;
  final int totalTeamMembers;
  final double capacityUtilization;
  final DateTime lastModified;

  factory QuarterPlanSummary.fromMap(Map<String, dynamic> map) {
    return QuarterPlanSummary(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      quarter: map['quarter'] as int,
      year: map['year'] as int,
      totalInitiatives: map['totalInitiatives'] as int,
      totalTeamMembers: map['totalTeamMembers'] as int,
      capacityUtilization: (map['capacityUtilization'] as num).toDouble(),
      lastModified: DateTime.parse(map['lastModified'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'quarter': quarter,
      'year': year,
      'totalInitiatives': totalInitiatives,
      'totalTeamMembers': totalTeamMembers,
      'capacityUtilization': capacityUtilization,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}
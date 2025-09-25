import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/types/result.dart';
import '../../../../services/business/application_state_service.dart';
import '../../domain/entities/user_configuration.dart';

/// Provider for auto-save functionality with configurable intervals and change detection.
/// 
/// This provider handles:
/// - Automatic saving of changes at configurable intervals
/// - Change detection and dirty state tracking
/// - Manual save operations
/// - Save status notifications
/// - Error handling and retry logic
class AutoSaveProvider extends ChangeNotifier {
  AutoSaveProvider({
    required ApplicationStateService applicationStateService,
    UserConfiguration? userConfiguration,
  }) : _applicationStateService = applicationStateService,
       _userConfiguration = userConfiguration ?? const UserConfiguration();

  final ApplicationStateService _applicationStateService;
  UserConfiguration _userConfiguration;
  
  // Auto-save state
  Timer? _autoSaveTimer;
  bool _isDirty = false;
  bool _isSaving = false;
  DateTime? _lastSaveTime;
  DateTime? _lastChangeTime;
  
  // Error handling
  Exception? _lastSaveError;
  int _consecutiveFailures = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  
  // Getters
  bool get isDirty => _isDirty;
  bool get isSaving => _isSaving;
  bool get isAutoSaveEnabled => _userConfiguration.enableNotifications;
  DateTime? get lastSaveTime => _lastSaveTime;
  DateTime? get lastChangeTime => _lastChangeTime;
  Exception? get lastSaveError => _lastSaveError;
  bool get hasSaveError => _lastSaveError != null;
  int get autoSaveIntervalSeconds => _userConfiguration.autoSaveInterval;
  Duration get autoSaveInterval => _userConfiguration.autoSaveIntervalDuration;

  /// Initializes the auto-save provider
  Future<void> initialize() async {
    // Start listening to application state changes
    _applicationStateService.stateStream.listen(_onStateChanged);
    _applicationStateService.configurationStream.listen(_onConfigurationChanged);
    
    // Start auto-save timer
    _startAutoSaveTimer();
  }

  /// Handles application state changes
  void _onStateChanged(dynamic state) {
    markDirty();
  }

  /// Handles user configuration changes
  void _onConfigurationChanged(UserConfiguration config) {
    _userConfiguration = config;
    _restartAutoSaveTimer();
    notifyListeners();
  }

  /// Marks the state as dirty (having unsaved changes)
  void markDirty() {
    if (!_isDirty) {
      _isDirty = true;
      _lastChangeTime = DateTime.now();
      _clearSaveError();
      notifyListeners();
    }
  }

  /// Marks the state as clean (no unsaved changes)
  void markClean() {
    if (_isDirty) {
      _isDirty = false;
      _lastSaveTime = DateTime.now();
      notifyListeners();
    }
  }

  /// Performs a manual save operation
  Future<Result<void, Exception>> saveNow() async {
    if (_isSaving) {
      return Result.error(Exception('Save operation already in progress'));
    }

    return await _performSave(isManual: true);
  }

  /// Performs the actual save operation
  Future<Result<void, Exception>> _performSave({bool isManual = false}) async {
    if (!_isDirty && !isManual) {
      return const Result.success(null);
    }

    _isSaving = true;
    _clearSaveError();
    notifyListeners();

    try {
      // Save application state
      final result = await _applicationStateService.saveState();
      
      if (result.isSuccess) {
        markClean();
        _consecutiveFailures = 0;
        
        // If this was an auto-save, schedule the next one
        if (!isManual && isAutoSaveEnabled) {
          _scheduleNextAutoSave();
        }
        
        return const Result.success(null);
      } else {
        _handleSaveError(result.error);
        return Result.error(result.error);
      }
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      _handleSaveError(exception);
      return Result.error(exception);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Handles save errors with retry logic
  void _handleSaveError(Exception error) {
    _lastSaveError = error;
    _consecutiveFailures++;
    
    // If we haven't exceeded max retries, schedule a retry
    if (_consecutiveFailures < _maxRetries) {
      Timer(_retryDelay, () => _performSave());
    }
  }

  /// Clears the last save error
  void _clearSaveError() {
    if (_lastSaveError != null) {
      _lastSaveError = null;
      notifyListeners();
    }
  }

  /// Starts the auto-save timer
  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    
    if (isAutoSaveEnabled && autoSaveIntervalSeconds > 0) {
      _autoSaveTimer = Timer.periodic(autoSaveInterval, (_) => _onAutoSaveTimer());
    }
  }

  /// Restarts the auto-save timer (when configuration changes)
  void _restartAutoSaveTimer() {
    _startAutoSaveTimer();
  }

  /// Handles auto-save timer events
  void _onAutoSaveTimer() {
    if (_isDirty && !_isSaving) {
      _performSave();
    }
  }

  /// Schedules the next auto-save (used after successful saves)
  void _scheduleNextAutoSave() {
    // This could implement more sophisticated scheduling logic
    // For now, we just rely on the periodic timer
  }

  /// Forces a save regardless of dirty state (for shutdown scenarios)
  Future<Result<void, Exception>> forceSave() async {
    return await _performSave(isManual: true);
  }

  /// Gets the time until the next auto-save
  Duration? getTimeUntilNextAutoSave() {
    if (!isAutoSaveEnabled || !_isDirty || _lastChangeTime == null) {
      return null;
    }

    final nextSaveTime = _lastChangeTime!.add(autoSaveInterval);
    final now = DateTime.now();
    
    if (nextSaveTime.isBefore(now)) {
      return Duration.zero;
    }
    
    return nextSaveTime.difference(now);
  }

  /// Gets save status information
  AutoSaveStatus getStatus() {
    return AutoSaveStatus(
      isDirty: _isDirty,
      isSaving: _isSaving,
      isEnabled: isAutoSaveEnabled,
      lastSaveTime: _lastSaveTime,
      lastChangeTime: _lastChangeTime,
      lastError: _lastSaveError,
      consecutiveFailures: _consecutiveFailures,
      timeUntilNextSave: getTimeUntilNextAutoSave(),
    );
  }

  /// Pauses auto-save (useful during batch operations)
  void pauseAutoSave() {
    _autoSaveTimer?.cancel();
  }

  /// Resumes auto-save
  void resumeAutoSave() {
    _startAutoSaveTimer();
  }

  /// Updates the auto-save configuration
  void updateConfiguration(UserConfiguration config) {
    _userConfiguration = config;
    _restartAutoSaveTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}

/// Status information for auto-save operations
class AutoSaveStatus {
  const AutoSaveStatus({
    required this.isDirty,
    required this.isSaving,
    required this.isEnabled,
    this.lastSaveTime,
    this.lastChangeTime,
    this.lastError,
    this.consecutiveFailures = 0,
    this.timeUntilNextSave,
  });

  final bool isDirty;
  final bool isSaving;
  final bool isEnabled;
  final DateTime? lastSaveTime;
  final DateTime? lastChangeTime;
  final Exception? lastError;
  final int consecutiveFailures;
  final Duration? timeUntilNextSave;

  bool get hasError => lastError != null;
  bool get isRetrying => consecutiveFailures > 0 && consecutiveFailures < 3;

  /// Gets a human-readable status message
  String get statusMessage {
    if (isSaving) {
      return 'Saving...';
    }
    
    if (hasError) {
      return isRetrying ? 'Save failed, retrying...' : 'Save failed';
    }
    
    if (!isEnabled) {
      return 'Auto-save disabled';
    }
    
    if (!isDirty) {
      return lastSaveTime != null ? 'All changes saved' : 'No changes';
    }
    
    if (timeUntilNextSave != null) {
      final seconds = timeUntilNextSave!.inSeconds;
      if (seconds <= 0) {
        return 'Saving soon...';
      } else if (seconds < 60) {
        return 'Auto-save in ${seconds}s';
      } else {
        final minutes = seconds ~/ 60;
        return 'Auto-save in ${minutes}m';
      }
    }
    
    return 'Unsaved changes';
  }

  /// Gets the appropriate icon for the current status
  String get statusIcon {
    if (isSaving) return '⏳';
    if (hasError) return '❌';
    if (!isEnabled) return '⏸️';
    if (!isDirty) return '✅';
    return '📝';
  }

  @override
  String toString() {
    return 'AutoSaveStatus('
        'dirty: $isDirty, '
        'saving: $isSaving, '
        'enabled: $isEnabled, '
        'error: $hasError, '
        'message: "$statusMessage"'
        ')';
  }
}


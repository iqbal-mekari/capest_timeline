import '../../domain/entities/application_state.dart';
import '../../domain/entities/user_configuration.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/themes/app_theme.dart';

/// Repository interface for configuration and application state operations.
/// 
/// This repository handles persistence and retrieval of:
/// - Application state (current plan, view settings, etc.)
/// - User configuration and preferences
/// - Session state and recovery data
abstract class ConfigurationRepository {
  /// Application State Operations
  
  /// Saves the current application state
  Future<Result<void, StorageException>> saveApplicationState(
    ApplicationState state,
  );

  /// Loads the application state
  Future<Result<ApplicationState?, StorageException>> loadApplicationState();

  /// Updates specific application state fields
  Future<Result<void, StorageException>> updateCurrentPlan(String? planId);

  /// Updates view settings
  Future<Result<void, StorageException>> updateViewSettings({
    ViewMode? viewMode,
    int? quarter,
    int? year,
  });

  /// Updates filters
  Future<Result<void, StorageException>> updateFilters(
    ApplicationFilters filters,
  );

  /// Adds a plan to recent plans list
  Future<Result<void, StorageException>> addToRecentPlans(String planId);

  /// Clears the recent plans list
  Future<Result<void, StorageException>> clearRecentPlans();

  /// Marks application state as having unsaved changes
  Future<Result<void, StorageException>> markAsChanged();

  /// Marks application state as saved
  Future<Result<void, StorageException>> markAsSaved();

  /// User Configuration Operations
  
  /// Saves user configuration
  Future<Result<void, StorageException>> saveUserConfiguration(
    UserConfiguration config,
  );

  /// Loads user configuration
  Future<Result<UserConfiguration?, StorageException>> loadUserConfiguration();

  /// Updates theme preference
  Future<Result<void, StorageException>> updateTheme(AppThemeMode theme);

  /// Updates notification settings
  Future<Result<void, StorageException>> updateNotificationSettings(
    bool enableNotifications,
  );

  /// Updates auto-save settings
  Future<Result<void, StorageException>> updateAutoSaveSettings(
    int intervalSeconds,
  );

  /// Updates default values for new initiatives
  Future<Result<void, StorageException>> updateInitiativeDefaults(
    InitiativeDefaults defaults,
  );

  /// Updates default values for new team members
  Future<Result<void, StorageException>> updateTeamMemberDefaults(
    TeamMemberDefaults defaults,
  );

  /// Updates display preferences
  Future<Result<void, StorageException>> updateDisplayPreferences({
    String? defaultViewMode,
    String? dateFormat,
    CapacityDisplayMode? capacityDisplayMode,
  });

  /// Session and Recovery Operations
  
  /// Saves session recovery data
  Future<Result<void, StorageException>> saveSessionRecovery(
    SessionRecoveryData data,
  );

  /// Loads session recovery data
  Future<Result<SessionRecoveryData?, StorageException>> loadSessionRecovery();

  /// Clears session recovery data
  Future<Result<void, StorageException>> clearSessionRecovery();

  /// Checks if there's unsaved work that can be recovered
  Future<Result<bool, StorageException>> hasRecoverableSession();

  /// Backup and Restore Operations
  
  /// Creates a full backup of all configuration data
  Future<Result<String, StorageException>> createFullBackup();

  /// Restores configuration from a backup
  Future<Result<void, StorageException>> restoreFromBackup(String backupData);

  /// Gets configuration metadata
  Future<Result<ConfigurationMetadata, StorageException>> getConfigurationMetadata();

  /// Utility Operations
  
  /// Validates configuration data
  Future<Result<void, ValidationException>> validateConfiguration(
    UserConfiguration config,
  );

  /// Resets configuration to defaults
  Future<Result<void, StorageException>> resetToDefaults();

  /// Migrates configuration from older versions
  Future<Result<void, StorageException>> migrateConfiguration(
    int fromVersion,
    int toVersion,
  );

  /// Gets the last modified timestamps
  Future<Result<DateTime?, StorageException>> getApplicationStateLastModified();
  Future<Result<DateTime?, StorageException>> getUserConfigurationLastModified();

  /// Clears all configuration data (for testing/reset)
  Future<Result<void, StorageException>> clearAllConfiguration();
}

/// Data for session recovery
class SessionRecoveryData {
  const SessionRecoveryData({
    required this.timestamp,
    required this.currentPlanId,
    required this.hasUnsavedChanges,
    required this.lastAction,
    required this.viewMode,
    required this.selectedQuarter,
    required this.selectedYear,
    this.unsavedData,
    this.errorContext,
  });

  final DateTime timestamp;
  final String? currentPlanId;
  final bool hasUnsavedChanges;
  final String lastAction;
  final ViewMode viewMode;
  final int? selectedQuarter;
  final int? selectedYear;
  final Map<String, dynamic>? unsavedData;
  final String? errorContext;

  bool get isRecent {
    final now = DateTime.now();
    const maxAge = Duration(hours: 24); // Recovery data expires after 24 hours
    return now.difference(timestamp) < maxAge;
  }

  bool get hasUnsavedWork => hasUnsavedChanges && unsavedData != null;

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'currentPlanId': currentPlanId,
      'hasUnsavedChanges': hasUnsavedChanges,
      'lastAction': lastAction,
      'viewMode': viewMode.name,
      'selectedQuarter': selectedQuarter,
      'selectedYear': selectedYear,
      'unsavedData': unsavedData,
      'errorContext': errorContext,
    };
  }

  factory SessionRecoveryData.fromMap(Map<String, dynamic> map) {
    return SessionRecoveryData(
      timestamp: DateTime.parse(map['timestamp'] as String),
      currentPlanId: map['currentPlanId'] as String?,
      hasUnsavedChanges: map['hasUnsavedChanges'] as bool,
      lastAction: map['lastAction'] as String,
      viewMode: ViewMode.values.firstWhere(
        (mode) => mode.name == map['viewMode'],
        orElse: () => ViewMode.timeline,
      ),
      selectedQuarter: map['selectedQuarter'] as int?,
      selectedYear: map['selectedYear'] as int?,
      unsavedData: map['unsavedData'] as Map<String, dynamic>?,
      errorContext: map['errorContext'] as String?,
    );
  }
}

/// Metadata about configuration
class ConfigurationMetadata {
  const ConfigurationMetadata({
    required this.version,
    required this.createdAt,
    required this.lastModified,
    required this.hasApplicationState,
    required this.hasUserConfiguration,
    required this.hasSessionRecovery,
    required this.dataSize,
  });

  final int version;
  final DateTime createdAt;
  final DateTime lastModified;
  final bool hasApplicationState;
  final bool hasUserConfiguration;
  final bool hasSessionRecovery;
  final int dataSize; // in bytes

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'hasApplicationState': hasApplicationState,
      'hasUserConfiguration': hasUserConfiguration,
      'hasSessionRecovery': hasSessionRecovery,
      'dataSize': dataSize,
    };
  }

  factory ConfigurationMetadata.fromMap(Map<String, dynamic> map) {
    return ConfigurationMetadata(
      version: map['version'] as int,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastModified: DateTime.parse(map['lastModified'] as String),
      hasApplicationState: map['hasApplicationState'] as bool,
      hasUserConfiguration: map['hasUserConfiguration'] as bool,
      hasSessionRecovery: map['hasSessionRecovery'] as bool,
      dataSize: map['dataSize'] as int,
    );
  }
}
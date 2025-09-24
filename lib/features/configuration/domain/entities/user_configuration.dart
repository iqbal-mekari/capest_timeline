import 'package:equatable/equatable.dart';

import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../shared/themes/app_theme.dart';

/// Represents user-specific configuration and preferences.
/// 
/// UserConfiguration stores:
/// - UI preferences and settings
/// - Default values for new plans
/// - Notification preferences
/// - Display customizations
class UserConfiguration extends Equatable {
  const UserConfiguration({
    this.theme = AppThemeMode.system,
    this.defaultQuarterWeeks = 13,
    this.defaultWeeklyCapacity = 1.0,
    this.enableNotifications = true,
    this.autoSaveInterval = 30,
    this.showWelcomeGuide = true,
    this.defaultViewMode = 'timeline',
    this.timeZone = 'UTC',
    this.dateFormat = 'yyyy-MM-dd',
    this.capacityDisplayMode = CapacityDisplayMode.weeks,
    this.initiativeDefaults = const InitiativeDefaults(),
    this.teamMemberDefaults = const TeamMemberDefaults(),
    this.createdAt,
    this.updatedAt,
  });

  /// Theme preference for the application
  final AppThemeMode theme;

  /// Default number of weeks in a quarter for calculations
  final int defaultQuarterWeeks;

  /// Default weekly capacity for new team members
  final double defaultWeeklyCapacity;

  /// Whether to show notifications
  final bool enableNotifications;

  /// Auto-save interval in seconds
  final int autoSaveInterval;

  /// Whether to show the welcome guide to new users
  final bool showWelcomeGuide;

  /// Default view mode when opening the application
  final String defaultViewMode;

  /// User's timezone for date calculations
  final String timeZone;

  /// Preferred date format for display
  final String dateFormat;

  /// How to display capacity values
  final CapacityDisplayMode capacityDisplayMode;

  /// Default values when creating new initiatives
  final InitiativeDefaults initiativeDefaults;

  /// Default values when creating new team members
  final TeamMemberDefaults teamMemberDefaults;

  /// When this configuration was created
  final DateTime? createdAt;

  /// When this configuration was last updated
  final DateTime? updatedAt;

  /// Checks if dark theme should be used (when theme is system)
  bool isDarkModePreferred(bool systemDarkMode) {
    switch (theme) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return systemDarkMode;
    }
  }

  /// Gets auto-save interval as Duration
  Duration get autoSaveIntervalDuration => Duration(seconds: autoSaveInterval);

  /// Checks if notifications are enabled and allowed
  bool get shouldShowNotifications => enableNotifications;

  /// Validates the user configuration
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    // Quarter weeks validation
    if (defaultQuarterWeeks < 10 || defaultQuarterWeeks > 16) {
      errors.add('Default quarter weeks must be between 10 and 16');
    }

    // Weekly capacity validation
    if (defaultWeeklyCapacity <= 0 || defaultWeeklyCapacity > 1.0) {
      errors.add('Default weekly capacity must be between 0 and 1.0');
    }

    // Auto-save interval validation
    if (autoSaveInterval < 5 || autoSaveInterval > 300) {
      errors.add('Auto-save interval must be between 5 and 300 seconds');
    }

    // View mode validation
    final validViewModes = ['timeline', 'capacity', 'table', 'kanban'];
    if (!validViewModes.contains(defaultViewMode)) {
      errors.add('Default view mode must be one of: ${validViewModes.join(", ")}');
    }

    // Date format validation (basic check)
    if (!_isValidDateFormat(dateFormat)) {
      errors.add('Invalid date format: $dateFormat');
    }

    // Validate nested objects
    final initiativeValidation = initiativeDefaults.validate();
    if (initiativeValidation.isError) {
      errors.add('Initiative defaults validation failed: ${initiativeValidation.error}');
    }

    final teamMemberValidation = teamMemberDefaults.validate();
    if (teamMemberValidation.isError) {
      errors.add('Team member defaults validation failed: ${teamMemberValidation.error}');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'User configuration validation failed',
          ValidationErrorType.businessRuleViolation,
          {'userConfiguration': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  /// Basic date format validation
  bool _isValidDateFormat(String format) {
    // Allow common date format patterns
    final validPatterns = [
      'yyyy-MM-dd',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'dd-MM-yyyy',
      'MM-dd-yyyy',
      'yyyy/MM/dd',
    ];
    return validPatterns.contains(format);
  }

  /// Creates a copy of this configuration with updated fields
  UserConfiguration copyWith({
    AppThemeMode? theme,
    int? defaultQuarterWeeks,
    double? defaultWeeklyCapacity,
    bool? enableNotifications,
    int? autoSaveInterval,
    bool? showWelcomeGuide,
    String? defaultViewMode,
    String? timeZone,
    String? dateFormat,
    CapacityDisplayMode? capacityDisplayMode,
    InitiativeDefaults? initiativeDefaults,
    TeamMemberDefaults? teamMemberDefaults,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserConfiguration(
      theme: theme ?? this.theme,
      defaultQuarterWeeks: defaultQuarterWeeks ?? this.defaultQuarterWeeks,
      defaultWeeklyCapacity: defaultWeeklyCapacity ?? this.defaultWeeklyCapacity,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoSaveInterval: autoSaveInterval ?? this.autoSaveInterval,
      showWelcomeGuide: showWelcomeGuide ?? this.showWelcomeGuide,
      defaultViewMode: defaultViewMode ?? this.defaultViewMode,
      timeZone: timeZone ?? this.timeZone,
      dateFormat: dateFormat ?? this.dateFormat,
      capacityDisplayMode: capacityDisplayMode ?? this.capacityDisplayMode,
      initiativeDefaults: initiativeDefaults ?? this.initiativeDefaults,
      teamMemberDefaults: teamMemberDefaults ?? this.teamMemberDefaults,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a UserConfiguration from a Map (for serialization)
  factory UserConfiguration.fromMap(Map<String, dynamic> map) {
    return UserConfiguration(
      theme: AppThemeMode.values.firstWhere(
        (mode) => mode.name == map['theme'],
        orElse: () => AppThemeMode.system,
      ),
      defaultQuarterWeeks: map['defaultQuarterWeeks'] as int? ?? 13,
      defaultWeeklyCapacity: (map['defaultWeeklyCapacity'] as num?)?.toDouble() ?? 1.0,
      enableNotifications: map['enableNotifications'] as bool? ?? true,
      autoSaveInterval: map['autoSaveInterval'] as int? ?? 30,
      showWelcomeGuide: map['showWelcomeGuide'] as bool? ?? true,
      defaultViewMode: map['defaultViewMode'] as String? ?? 'timeline',
      timeZone: map['timeZone'] as String? ?? 'UTC',
      dateFormat: map['dateFormat'] as String? ?? 'yyyy-MM-dd',
      capacityDisplayMode: CapacityDisplayMode.values.firstWhere(
        (mode) => mode.name == map['capacityDisplayMode'],
        orElse: () => CapacityDisplayMode.weeks,
      ),
      initiativeDefaults: map['initiativeDefaults'] != null
          ? InitiativeDefaults.fromMap(map['initiativeDefaults'] as Map<String, dynamic>)
          : const InitiativeDefaults(),
      teamMemberDefaults: map['teamMemberDefaults'] != null
          ? TeamMemberDefaults.fromMap(map['teamMemberDefaults'] as Map<String, dynamic>)
          : const TeamMemberDefaults(),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this UserConfiguration to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'theme': theme.name,
      'defaultQuarterWeeks': defaultQuarterWeeks,
      'defaultWeeklyCapacity': defaultWeeklyCapacity,
      'enableNotifications': enableNotifications,
      'autoSaveInterval': autoSaveInterval,
      'showWelcomeGuide': showWelcomeGuide,
      'defaultViewMode': defaultViewMode,
      'timeZone': timeZone,
      'dateFormat': dateFormat,
      'capacityDisplayMode': capacityDisplayMode.name,
      'initiativeDefaults': initiativeDefaults.toMap(),
      'teamMemberDefaults': teamMemberDefaults.toMap(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        theme,
        defaultQuarterWeeks,
        defaultWeeklyCapacity,
        enableNotifications,
        autoSaveInterval,
        showWelcomeGuide,
        defaultViewMode,
        timeZone,
        dateFormat,
        capacityDisplayMode,
        initiativeDefaults,
        teamMemberDefaults,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'UserConfiguration('
        'theme: ${theme.displayName}, '
        'quarterWeeks: $defaultQuarterWeeks, '
        'weeklyCapacity: $defaultWeeklyCapacity, '
        'notifications: $enableNotifications, '
        'autoSave: ${autoSaveInterval}s'
        ')';
  }
}



/// How to display capacity values
enum CapacityDisplayMode {
  /// Display as person-weeks
  weeks('Weeks'),
  
  /// Display as person-days
  days('Days'),
  
  /// Display as percentage
  percentage('Percentage'),
  
  /// Display as FTE (Full-Time Equivalent)
  fte('FTE');

  const CapacityDisplayMode(this.displayName);

  /// Human-readable display name
  final String displayName;

  /// Convert weeks to this display mode
  double convertFromWeeks(double weeks) {
    switch (this) {
      case CapacityDisplayMode.weeks:
        return weeks;
      case CapacityDisplayMode.days:
        return weeks * 5; // 5 days per week
      case CapacityDisplayMode.percentage:
        return weeks * 100; // Assume 1 week = 100%
      case CapacityDisplayMode.fte:
        return weeks; // 1 week = 1 FTE
    }
  }

  /// Get the unit suffix for display
  String get unitSuffix {
    switch (this) {
      case CapacityDisplayMode.weeks:
        return 'w';
      case CapacityDisplayMode.days:
        return 'd';
      case CapacityDisplayMode.percentage:
        return '%';
      case CapacityDisplayMode.fte:
        return ' FTE';
    }
  }
}

/// Default values for new initiatives
class InitiativeDefaults extends Equatable {
  const InitiativeDefaults({
    this.defaultPriority = 5,
    this.defaultBusinessValue = 5,
    this.defaultEstimateWeeks = 4.0,
    this.requireDescription = true,
    this.requireBusinessValue = true,
  });

  final int defaultPriority;
  final int defaultBusinessValue;
  final double defaultEstimateWeeks;
  final bool requireDescription;
  final bool requireBusinessValue;

  /// Validates the initiative defaults
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    if (defaultPriority < 1 || defaultPriority > 10) {
      errors.add('Default priority must be between 1 and 10');
    }

    if (defaultBusinessValue < 1 || defaultBusinessValue > 10) {
      errors.add('Default business value must be between 1 and 10');
    }

    if (defaultEstimateWeeks <= 0 || defaultEstimateWeeks > 52) {
      errors.add('Default estimate weeks must be between 0 and 52');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Initiative defaults validation failed',
          ValidationErrorType.businessRuleViolation,
          {'initiativeDefaults': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  InitiativeDefaults copyWith({
    int? defaultPriority,
    int? defaultBusinessValue,
    double? defaultEstimateWeeks,
    bool? requireDescription,
    bool? requireBusinessValue,
  }) {
    return InitiativeDefaults(
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultBusinessValue: defaultBusinessValue ?? this.defaultBusinessValue,
      defaultEstimateWeeks: defaultEstimateWeeks ?? this.defaultEstimateWeeks,
      requireDescription: requireDescription ?? this.requireDescription,
      requireBusinessValue: requireBusinessValue ?? this.requireBusinessValue,
    );
  }

  factory InitiativeDefaults.fromMap(Map<String, dynamic> map) {
    return InitiativeDefaults(
      defaultPriority: map['defaultPriority'] as int? ?? 5,
      defaultBusinessValue: map['defaultBusinessValue'] as int? ?? 5,
      defaultEstimateWeeks: (map['defaultEstimateWeeks'] as num?)?.toDouble() ?? 4.0,
      requireDescription: map['requireDescription'] as bool? ?? true,
      requireBusinessValue: map['requireBusinessValue'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultPriority': defaultPriority,
      'defaultBusinessValue': defaultBusinessValue,
      'defaultEstimateWeeks': defaultEstimateWeeks,
      'requireDescription': requireDescription,
      'requireBusinessValue': requireBusinessValue,
    };
  }

  @override
  List<Object?> get props => [
        defaultPriority,
        defaultBusinessValue,
        defaultEstimateWeeks,
        requireDescription,
        requireBusinessValue,
      ];
}

/// Default values for new team members
class TeamMemberDefaults extends Equatable {
  const TeamMemberDefaults({
    this.defaultSkillLevel = 5,
    this.defaultWeeklyCapacity = 1.0,
    this.requireEmail = true,
    this.requireRoles = true,
    this.defaultActiveStatus = true,
  });

  final int defaultSkillLevel;
  final double defaultWeeklyCapacity;
  final bool requireEmail;
  final bool requireRoles;
  final bool defaultActiveStatus;

  /// Validates the team member defaults
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    if (defaultSkillLevel < 1 || defaultSkillLevel > 10) {
      errors.add('Default skill level must be between 1 and 10');
    }

    if (defaultWeeklyCapacity <= 0 || defaultWeeklyCapacity > 1.0) {
      errors.add('Default weekly capacity must be between 0 and 1.0');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Team member defaults validation failed',
          ValidationErrorType.businessRuleViolation,
          {'teamMemberDefaults': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  TeamMemberDefaults copyWith({
    int? defaultSkillLevel,
    double? defaultWeeklyCapacity,
    bool? requireEmail,
    bool? requireRoles,
    bool? defaultActiveStatus,
  }) {
    return TeamMemberDefaults(
      defaultSkillLevel: defaultSkillLevel ?? this.defaultSkillLevel,
      defaultWeeklyCapacity: defaultWeeklyCapacity ?? this.defaultWeeklyCapacity,
      requireEmail: requireEmail ?? this.requireEmail,
      requireRoles: requireRoles ?? this.requireRoles,
      defaultActiveStatus: defaultActiveStatus ?? this.defaultActiveStatus,
    );
  }

  factory TeamMemberDefaults.fromMap(Map<String, dynamic> map) {
    return TeamMemberDefaults(
      defaultSkillLevel: map['defaultSkillLevel'] as int? ?? 5,
      defaultWeeklyCapacity: (map['defaultWeeklyCapacity'] as num?)?.toDouble() ?? 1.0,
      requireEmail: map['requireEmail'] as bool? ?? true,
      requireRoles: map['requireRoles'] as bool? ?? true,
      defaultActiveStatus: map['defaultActiveStatus'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultSkillLevel': defaultSkillLevel,
      'defaultWeeklyCapacity': defaultWeeklyCapacity,
      'requireEmail': requireEmail,
      'requireRoles': requireRoles,
      'defaultActiveStatus': defaultActiveStatus,
    };
  }

  @override
  List<Object?> get props => [
        defaultSkillLevel,
        defaultWeeklyCapacity,
        requireEmail,
        requireRoles,
        defaultActiveStatus,
      ];
}
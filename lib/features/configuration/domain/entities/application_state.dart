import 'package:equatable/equatable.dart';

import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Represents the global application state including current plan and view settings.
/// 
/// ApplicationState tracks:
/// - Currently active quarter plan
/// - UI view preferences
/// - Application-level settings
/// - Last saved state information
class ApplicationState extends Equatable {
  const ApplicationState({
    this.currentPlanId,
    this.lastAccessedPlanIds = const [],
    this.viewMode = ViewMode.timeline,
    this.selectedQuarter,
    this.selectedYear,
    this.filters = const ApplicationFilters(),
    this.isAutoSaveEnabled = true,
    this.lastSaveTime,
    this.hasUnsavedChanges = false,
    this.createdAt,
    this.updatedAt,
  });

  /// ID of the currently active quarter plan
  final String? currentPlanId;

  /// List of recently accessed plan IDs (most recent first)
  final List<String> lastAccessedPlanIds;

  /// Current view mode for the application
  final ViewMode viewMode;

  /// Currently selected quarter (for filtering/navigation)
  final int? selectedQuarter;

  /// Currently selected year (for filtering/navigation)
  final int? selectedYear;

  /// Current filter settings
  final ApplicationFilters filters;

  /// Whether auto-save is enabled
  final bool isAutoSaveEnabled;

  /// When the application was last saved
  final DateTime? lastSaveTime;

  /// Whether there are unsaved changes
  final bool hasUnsavedChanges;

  /// When this state was created
  final DateTime? createdAt;

  /// When this state was last updated
  final DateTime? updatedAt;

  /// Gets the default quarter/year if none selected
  (int quarter, int year) get effectiveQuarterYear {
    final now = DateTime.now();
    final defaultQuarter = ((now.month - 1) ~/ 3) + 1;
    final defaultYear = now.year;
    
    return (
      selectedQuarter ?? defaultQuarter,
      selectedYear ?? defaultYear,
    );
  }

  /// Checks if there's a currently active plan
  bool get hasActivePlan => currentPlanId != null && currentPlanId!.isNotEmpty;

  /// Checks if auto-save is due (more than 30 seconds since last save)
  bool get isAutoSaveDue {
    if (!isAutoSaveEnabled || !hasUnsavedChanges) return false;
    if (lastSaveTime == null) return true;
    
    final now = DateTime.now();
    const autoSaveInterval = Duration(seconds: 30);
    return now.difference(lastSaveTime!) > autoSaveInterval;
  }

  /// Gets the number of recent plans to track
  static const int maxRecentPlans = 10;

  /// Adds a plan ID to the recent list (removes duplicates and limits size)
  List<String> _updateRecentPlans(String planId) {
    final updatedList = [planId];
    
    // Add existing plans (excluding the one we just added)
    for (final existingId in lastAccessedPlanIds) {
      if (existingId != planId && updatedList.length < maxRecentPlans) {
        updatedList.add(existingId);
      }
    }
    
    return updatedList;
  }

  /// Validates the application state
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    // Quarter validation
    if (selectedQuarter != null && (selectedQuarter! < 1 || selectedQuarter! > 4)) {
      errors.add('Selected quarter must be between 1 and 4');
    }

    // Year validation
    if (selectedYear != null && (selectedYear! < 2020 || selectedYear! > 2050)) {
      errors.add('Selected year must be between 2020 and 2050');
    }

    // Recent plans list validation
    if (lastAccessedPlanIds.length > maxRecentPlans) {
      errors.add('Recent plans list cannot exceed $maxRecentPlans items');
    }

    // Check for duplicate plan IDs in recent list
    final uniqueIds = lastAccessedPlanIds.toSet();
    if (uniqueIds.length != lastAccessedPlanIds.length) {
      errors.add('Recent plans list contains duplicate IDs');
    }

    // Validate filters
    final filterValidation = filters.validate();
    if (filterValidation.isError) {
      errors.add('Filters validation failed: ${filterValidation.error}');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Application state validation failed',
          ValidationErrorType.businessRuleViolation,
          {'applicationState': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  /// Creates a copy with updated current plan
  ApplicationState withCurrentPlan(String? planId) {
    final updatedRecentPlans = planId != null 
        ? _updateRecentPlans(planId)
        : lastAccessedPlanIds;

    return copyWith(
      currentPlanId: planId,
      lastAccessedPlanIds: updatedRecentPlans,
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy with updated view settings
  ApplicationState withViewSettings({
    ViewMode? viewMode,
    int? quarter,
    int? year,
  }) {
    return copyWith(
      viewMode: viewMode ?? this.viewMode,
      selectedQuarter: quarter ?? selectedQuarter,
      selectedYear: year ?? selectedYear,
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy marked as saved
  ApplicationState markAsSaved() {
    return copyWith(
      hasUnsavedChanges: false,
      lastSaveTime: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy marked as having unsaved changes
  ApplicationState markAsChanged() {
    return copyWith(
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a copy of this application state with updated fields
  ApplicationState copyWith({
    String? currentPlanId,
    List<String>? lastAccessedPlanIds,
    ViewMode? viewMode,
    int? selectedQuarter,
    int? selectedYear,
    ApplicationFilters? filters,
    bool? isAutoSaveEnabled,
    DateTime? lastSaveTime,
    bool? hasUnsavedChanges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApplicationState(
      currentPlanId: currentPlanId ?? this.currentPlanId,
      lastAccessedPlanIds: lastAccessedPlanIds ?? this.lastAccessedPlanIds,
      viewMode: viewMode ?? this.viewMode,
      selectedQuarter: selectedQuarter ?? this.selectedQuarter,
      selectedYear: selectedYear ?? this.selectedYear,
      filters: filters ?? this.filters,
      isAutoSaveEnabled: isAutoSaveEnabled ?? this.isAutoSaveEnabled,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates an ApplicationState from a Map (for serialization)
  factory ApplicationState.fromMap(Map<String, dynamic> map) {
    return ApplicationState(
      currentPlanId: map['currentPlanId'] as String?,
      lastAccessedPlanIds: List<String>.from(map['lastAccessedPlanIds'] as List? ?? []),
      viewMode: ViewMode.values.firstWhere(
        (mode) => mode.name == map['viewMode'],
        orElse: () => ViewMode.timeline,
      ),
      selectedQuarter: map['selectedQuarter'] as int?,
      selectedYear: map['selectedYear'] as int?,
      filters: map['filters'] != null 
          ? ApplicationFilters.fromMap(map['filters'] as Map<String, dynamic>)
          : const ApplicationFilters(),
      isAutoSaveEnabled: map['isAutoSaveEnabled'] as bool? ?? true,
      lastSaveTime: map['lastSaveTime'] != null 
          ? DateTime.parse(map['lastSaveTime'] as String)
          : null,
      hasUnsavedChanges: map['hasUnsavedChanges'] as bool? ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this ApplicationState to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'currentPlanId': currentPlanId,
      'lastAccessedPlanIds': lastAccessedPlanIds,
      'viewMode': viewMode.name,
      'selectedQuarter': selectedQuarter,
      'selectedYear': selectedYear,
      'filters': filters.toMap(),
      'isAutoSaveEnabled': isAutoSaveEnabled,
      'lastSaveTime': lastSaveTime?.toIso8601String(),
      'hasUnsavedChanges': hasUnsavedChanges,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        currentPlanId,
        lastAccessedPlanIds,
        viewMode,
        selectedQuarter,
        selectedYear,
        filters,
        isAutoSaveEnabled,
        lastSaveTime,
        hasUnsavedChanges,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ApplicationState('
        'currentPlan: $currentPlanId, '
        'viewMode: ${viewMode.displayName}, '
        'quarter: Q${selectedQuarter ?? '?'} ${selectedYear ?? '?'}, '
        'hasChanges: $hasUnsavedChanges'
        ')';
  }
}

/// Available view modes for the application
enum ViewMode {
  /// Timeline view showing initiatives over time
  timeline('Timeline'),
  
  /// Capacity view showing team member allocations
  capacity('Capacity'),
  
  /// Table view showing tabular data
  table('Table'),
  
  /// Kanban board view
  kanban('Kanban');

  const ViewMode(this.displayName);

  /// Human-readable display name
  final String displayName;

  /// Check if this view supports drag and drop
  bool get supportsDragDrop => 
      this == ViewMode.timeline || 
      this == ViewMode.kanban;

  /// Check if this view shows time-based information
  bool get isTimeBased => 
      this == ViewMode.timeline;

  /// Check if this view shows capacity information
  bool get showsCapacity => 
      this == ViewMode.capacity || 
      this == ViewMode.timeline;
}

/// Filter settings for the application
class ApplicationFilters extends Equatable {
  const ApplicationFilters({
    this.showCompletedInitiatives = true,
    this.showInactiveMembers = false,
    this.roleFilter = const {},
    this.searchQuery = '',
    this.priorityRange = const (1, 10),
    this.capacityUtilizationRange = const (0.0, 200.0),
  });

  /// Whether to show completed initiatives
  final bool showCompletedInitiatives;

  /// Whether to show inactive team members
  final bool showInactiveMembers;

  /// Filter by specific roles (empty set means show all)
  final Set<String> roleFilter;

  /// Text search query
  final String searchQuery;

  /// Priority range filter (min, max)
  final (int, int) priorityRange;

  /// Capacity utilization range filter (min%, max%)
  final (double, double) capacityUtilizationRange;

  /// Checks if any filters are active
  bool get hasActiveFilters =>
      !showCompletedInitiatives ||
      showInactiveMembers ||
      roleFilter.isNotEmpty ||
      searchQuery.isNotEmpty ||
      priorityRange != (1, 10) ||
      capacityUtilizationRange != (0.0, 200.0);

  /// Validates filter settings
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    // Priority range validation
    if (priorityRange.$1 < 1 || priorityRange.$1 > 10) {
      errors.add('Priority range minimum must be between 1 and 10');
    }
    if (priorityRange.$2 < 1 || priorityRange.$2 > 10) {
      errors.add('Priority range maximum must be between 1 and 10');
    }
    if (priorityRange.$1 > priorityRange.$2) {
      errors.add('Priority range minimum cannot exceed maximum');
    }

    // Capacity range validation
    if (capacityUtilizationRange.$1 < 0.0) {
      errors.add('Capacity utilization range minimum cannot be negative');
    }
    if (capacityUtilizationRange.$2 > 500.0) {
      errors.add('Capacity utilization range maximum cannot exceed 500%');
    }
    if (capacityUtilizationRange.$1 > capacityUtilizationRange.$2) {
      errors.add('Capacity utilization range minimum cannot exceed maximum');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Application filters validation failed',
          ValidationErrorType.businessRuleViolation,
          {'applicationFilters': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  /// Creates a copy with updated fields
  ApplicationFilters copyWith({
    bool? showCompletedInitiatives,
    bool? showInactiveMembers,
    Set<String>? roleFilter,
    String? searchQuery,
    (int, int)? priorityRange,
    (double, double)? capacityUtilizationRange,
  }) {
    return ApplicationFilters(
      showCompletedInitiatives: showCompletedInitiatives ?? this.showCompletedInitiatives,
      showInactiveMembers: showInactiveMembers ?? this.showInactiveMembers,
      roleFilter: roleFilter ?? this.roleFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      priorityRange: priorityRange ?? this.priorityRange,
      capacityUtilizationRange: capacityUtilizationRange ?? this.capacityUtilizationRange,
    );
  }

  /// Creates filters from a Map (for serialization)
  factory ApplicationFilters.fromMap(Map<String, dynamic> map) {
    return ApplicationFilters(
      showCompletedInitiatives: map['showCompletedInitiatives'] as bool? ?? true,
      showInactiveMembers: map['showInactiveMembers'] as bool? ?? false,
      roleFilter: Set<String>.from(map['roleFilter'] as List? ?? []),
      searchQuery: map['searchQuery'] as String? ?? '',
      priorityRange: map['priorityRange'] != null
          ? (
              (map['priorityRange'] as List)[0] as int,
              (map['priorityRange'] as List)[1] as int,
            )
          : (1, 10),
      capacityUtilizationRange: map['capacityUtilizationRange'] != null
          ? (
              (map['capacityUtilizationRange'] as List)[0] as double,
              (map['capacityUtilizationRange'] as List)[1] as double,
            )
          : (0.0, 200.0),
    );
  }

  /// Converts filters to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'showCompletedInitiatives': showCompletedInitiatives,
      'showInactiveMembers': showInactiveMembers,
      'roleFilter': roleFilter.toList(),
      'searchQuery': searchQuery,
      'priorityRange': [priorityRange.$1, priorityRange.$2],
      'capacityUtilizationRange': [capacityUtilizationRange.$1, capacityUtilizationRange.$2],
    };
  }

  @override
  List<Object?> get props => [
        showCompletedInitiatives,
        showInactiveMembers,
        roleFilter,
        searchQuery,
        priorityRange,
        capacityUtilizationRange,
      ];

  @override
  String toString() {
    return 'ApplicationFilters('
        'completed: $showCompletedInitiatives, '
        'inactive: $showInactiveMembers, '
        'roles: ${roleFilter.length}, '
        'search: "${searchQuery}", '
        'active: $hasActiveFilters'
        ')';
  }
}
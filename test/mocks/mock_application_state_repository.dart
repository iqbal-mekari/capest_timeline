/// Mock implementation of ApplicationStateRepository for testing.
/// 
/// This mock will be replaced with actual repository interfaces and 
/// implementation when they are created in Phase 3.3+.
library;

/// Mock ApplicationState entity (placeholder until actual entity is implemented)
class MockApplicationState {
  const MockApplicationState({
    this.currentPlanId,
    this.lastAccessedPlanIds = const [],
    this.viewMode = 'timeline',
    this.selectedQuarter,
    this.selectedYear,
    this.isAutoSaveEnabled = true,
    this.hasUnsavedChanges = false,
    this.lastSaveTime,
    this.createdAt,
    this.updatedAt,
  });

  final String? currentPlanId;
  final List<String> lastAccessedPlanIds;
  final String viewMode;
  final int? selectedQuarter;
  final int? selectedYear;
  final bool isAutoSaveEnabled;
  final bool hasUnsavedChanges;
  final DateTime? lastSaveTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MockApplicationState copyWith({
    String? currentPlanId,
    List<String>? lastAccessedPlanIds,
    String? viewMode,
    int? selectedQuarter,
    int? selectedYear,
    bool? isAutoSaveEnabled,
    bool? hasUnsavedChanges,
    DateTime? lastSaveTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MockApplicationState(
      currentPlanId: currentPlanId ?? this.currentPlanId,
      lastAccessedPlanIds: lastAccessedPlanIds ?? this.lastAccessedPlanIds,
      viewMode: viewMode ?? this.viewMode,
      selectedQuarter: selectedQuarter ?? this.selectedQuarter,
      selectedYear: selectedYear ?? this.selectedYear,
      isAutoSaveEnabled: isAutoSaveEnabled ?? this.isAutoSaveEnabled,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPlanId': currentPlanId,
      'lastAccessedPlanIds': lastAccessedPlanIds,
      'viewMode': viewMode,
      'selectedQuarter': selectedQuarter,
      'selectedYear': selectedYear,
      'isAutoSaveEnabled': isAutoSaveEnabled,
      'hasUnsavedChanges': hasUnsavedChanges,
      'lastSaveTime': lastSaveTime?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Mock draft data for incomplete plans
class MockDraftData {
  const MockDraftData({
    required this.id,
    required this.name,
    required this.data,
    required this.lastModified,
  });

  final String id;
  final String name;
  final Map<String, dynamic> data;
  final DateTime lastModified;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'data': data,
      'lastModified': lastModified.toIso8601String(),
    };
  }
}

/// Mock repository for application state operations
class MockApplicationStateRepository {
  MockApplicationState _currentState = const MockApplicationState();
  final Map<String, MockDraftData> _drafts = {};
  bool _shouldFailSave = false;
  bool _shouldFailLoad = false;

  /// Simulates loading the current application state
  Future<MockApplicationState> loadApplicationState() async {
    if (_shouldFailLoad) {
      throw Exception('Simulated load failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate async operation
    return _currentState;
  }

  /// Simulates saving the application state
  Future<void> saveApplicationState(MockApplicationState state) async {
    if (_shouldFailSave) {
      throw Exception('Simulated save failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async operation
    _currentState = state.copyWith(
      lastSaveTime: DateTime.now(),
      updatedAt: DateTime.now(),
      hasUnsavedChanges: false,
    );
  }

  /// Simulates updating the current plan ID
  Future<void> updateCurrentPlan(String? planId) async {
    await Future.delayed(const Duration(milliseconds: 25)); // Simulate async operation
    _currentState = _currentState.copyWith(
      currentPlanId: planId,
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Simulates updating view settings
  Future<void> updateViewSettings({
    String? viewMode,
    int? quarter,
    int? year,
  }) async {
    await Future.delayed(const Duration(milliseconds: 25)); // Simulate async operation
    _currentState = _currentState.copyWith(
      viewMode: viewMode,
      selectedQuarter: quarter,
      selectedYear: year,
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Simulates saving a draft
  Future<void> saveDraft(MockDraftData draft) async {
    if (_shouldFailSave) {
      throw Exception('Simulated draft save failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 75)); // Simulate async operation
    _drafts[draft.id] = draft;
  }

  /// Simulates loading a draft
  Future<MockDraftData?> loadDraft(String id) async {
    if (_shouldFailLoad) {
      throw Exception('Simulated draft load failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate async operation
    return _drafts[id];
  }

  /// Simulates loading all drafts
  Future<List<MockDraftData>> loadAllDrafts() async {
    if (_shouldFailLoad) {
      throw Exception('Simulated drafts load failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 75)); // Simulate async operation
    return _drafts.values.toList();
  }

  /// Simulates deleting a draft
  Future<void> deleteDraft(String id) async {
    await Future.delayed(const Duration(milliseconds: 25)); // Simulate async operation
    _drafts.remove(id);
  }

  /// Simulates marking state as having unsaved changes
  Future<void> markAsChanged() async {
    await Future.delayed(const Duration(milliseconds: 10)); // Simulate async operation
    _currentState = _currentState.copyWith(
      hasUnsavedChanges: true,
      updatedAt: DateTime.now(),
    );
  }

  /// Simulates auto-save trigger
  Future<void> triggerAutoSave() async {
    if (_currentState.isAutoSaveEnabled && _currentState.hasUnsavedChanges) {
      await saveApplicationState(_currentState);
    }
  }

  /// Sets up the mock to simulate save failures
  void setupSaveFailure() {
    _shouldFailSave = true;
  }

  /// Sets up the mock to simulate load failures
  void setupLoadFailure() {
    _shouldFailLoad = true;
  }

  /// Clears failure simulation
  void clearSaveFailure() {
    _shouldFailSave = false;
  }

  /// Clears load failure simulation
  void clearLoadFailure() {
    _shouldFailLoad = false;
  }

  /// Resets to default state (for test cleanup)
  void resetToDefaultState() {
    _currentState = const MockApplicationState();
    _drafts.clear();
  }

  /// Gets current state (for testing)
  MockApplicationState get currentState => _currentState;

  /// Gets draft count (for testing)
  int get draftCount => _drafts.length;

  /// Gets all draft IDs (for testing)
  List<String> get draftIds => _drafts.keys.toList();

  /// Checks if auto-save is due
  bool get isAutoSaveDue {
    if (!_currentState.isAutoSaveEnabled || !_currentState.hasUnsavedChanges) {
      return false;
    }
    
    final lastSave = _currentState.lastSaveTime;
    if (lastSave == null) return true;
    
    return DateTime.now().difference(lastSave).inMinutes >= 5;
  }
}
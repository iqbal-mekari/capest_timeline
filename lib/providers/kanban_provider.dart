import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/kanban_service.dart';
import '../services/capacity_service.dart';
import '../services/storage_service.dart';

/// Provider for managing Kanban board state and operations
class KanbanProvider extends ChangeNotifier {
  final KanbanService _kanbanService;
  final CapacityService _capacityService;
  final StorageService _storageService;

  // State variables
  List<Initiative> _initiatives = [];
  List<PlatformVariant> _platformVariants = [];
  List<DateTime> _timelineWeeks = [];
  List<CapacityPeriod> _capacityPeriods = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  // Constructor
  KanbanProvider({
    required KanbanService kanbanService,
    required CapacityService capacityService,
    required StorageService storageService,
  })  : _kanbanService = kanbanService,
        _capacityService = capacityService,
        _storageService = storageService;

  // Getters
  List<Initiative> get initiatives => List.unmodifiable(_initiatives);
  List<PlatformVariant> get platformVariants => List.unmodifiable(_platformVariants);
  List<DateTime> get timelineWeeks => List.unmodifiable(_timelineWeeks);
  List<CapacityPeriod> get capacityPeriods => List.unmodifiable(_capacityPeriods);
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;

  /// Initialize the kanban board data
  Future<void> initialize() async {
    await _loadData();
  }

  /// Load all kanban data
  Future<void> _loadData() async {
    _setLoading(true);
    _clearError();

    try {
      // Generate timeline weeks (e.g., next 12 weeks)
      _timelineWeeks = _generateTimelineWeeks();

      // Load kanban data using service
      final kanbanData = await _kanbanService.getKanbanData(
        startDate: _timelineWeeks.first,
        endDate: _timelineWeeks.last,
      );

      _initiatives = kanbanData.initiatives;
      _capacityPeriods = kanbanData.capacityPeriods;

      // Load platform variants from storage
      _platformVariants = await _storageService.loadPlatformVariants();

      _setLoading(false);
    } catch (e) {
      _setError('Failed to load kanban data: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Generate timeline weeks starting from current week
  List<DateTime> _generateTimelineWeeks({int weekCount = 12}) {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return List.generate(weekCount, (index) {
      return currentWeekStart.add(Duration(days: index * 7));
    });
  }

  /// Move a platform variant to a specific week
  Future<bool> moveVariantToWeek(String variantId, DateTime targetWeek) async {
    try {
      // Find the variant to move
      final variant = _platformVariants.firstWhere(
        (v) => v.id == variantId,
        orElse: () => throw Exception('Variant not found: $variantId'),
      );

      // Perform the move using the service
      await _kanbanService.moveVariantToWeek(variant, targetWeek);
      
      // Refresh data after successful move
      await _loadData();
      return true;
    } catch (e) {
      _setError('Error moving variant: ${e.toString()}');
      return false;
    }
  }

  /// Create a new initiative
  Future<bool> createInitiative(Initiative initiative) async {
    try {
      // Convert initiative to map format expected by service
      final initiativeData = {
        'title': initiative.title,
        'description': initiative.description,
        'requiredPlatforms': initiative.requiredPlatforms.map((p) => p.name).toList(),
        'estimatedWeeks': initiative.platformVariants.fold(0.0, (sum, v) => sum + v.estimatedWeeks),
        'priority': int.tryParse(initiative.priority ?? '1') ?? 1,
      };

      await _kanbanService.createInitiative(initiativeData);
      await _loadData(); // Refresh data
      return true;
    } catch (e) {
      _setError('Error creating initiative: ${e.toString()}');
      return false;
    }
  }

  /// Update an existing initiative
  Future<bool> updateInitiative(Initiative initiative) async {
    try {
      await _kanbanService.updateInitiative(
        initiativeId: initiative.id,
        title: initiative.title,
        description: initiative.description,
        priority: int.tryParse(initiative.priority ?? '1'),
      );
      
      await _loadData(); // Refresh data
      return true;
    } catch (e) {
      _setError('Error updating initiative: ${e.toString()}');
      return false;
    }
  }

  /// Delete an initiative
  Future<bool> deleteInitiative(String initiativeId) async {
    try {
      await _kanbanService.deleteInitiative(initiativeId);
      await _loadData(); // Refresh data
      return true;
    } catch (e) {
      _setError('Error deleting initiative: ${e.toString()}');
      return false;
    }
  }

  /// Get variants for a specific initiative
  List<PlatformVariant> getVariantsForInitiative(String initiativeId) {
    return _platformVariants
        .where((variant) => variant.initiativeId == initiativeId)
        .toList();
  }

  /// Get variants for a specific week
  List<PlatformVariant> getVariantsForWeek(DateTime week) {
    return _platformVariants
        .where((variant) => _isSameWeek(variant.currentWeek, week))
        .toList();
  }

  /// Get capacity for a specific week
  CapacityPeriod? getCapacityForWeek(DateTime week) {
    return _capacityPeriods.firstWhere(
      (period) => _isSameWeek(period.weekStart, week),
      orElse: () => CapacityPeriod(
        weekStart: week,
        weekEnd: week.add(const Duration(days: 6)),
        assignments: [],
        totalCapacityAvailable: 0.0,
      ),
    );
  }

  /// Check if two dates are in the same week
  bool _isSameWeek(DateTime date1, DateTime date2) {
    final week1Start = date1.subtract(Duration(days: date1.weekday - 1));
    final week2Start = date2.subtract(Duration(days: date2.weekday - 1));
    return week1Start.isAtSameMomentAs(week2Start);
  }

  /// Refresh data from storage
  Future<void> refresh() async {
    await _loadData();
  }

  /// Clear all error states
  void _clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set error state
  void _setError(String message) {
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      _hasError = false;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _clearError();
  }

  /// Retry last failed operation
  Future<void> retry() async {
    await _loadData();
  }

  /// Save current state to storage
  Future<void> saveToStorage() async {
    try {
      final kanbanState = {
        'initiatives': initiatives.map((i) => i.toJson()).toList(),
        'platformVariants': platformVariants.map((v) => v.toJson()).toList(),
        'timelineWeeks': timelineWeeks.map((w) => w.toIso8601String()).toList(),
      };
      await _storageService.saveKanbanState(kanbanState);
    } catch (e) {
      _setError('Error saving to storage: ${e.toString()}');
    }
  }
}
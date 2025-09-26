/// UI state management using ChangeNotifier for capacity planning features.
/// 
/// This file contains ChangeNotifier classes that manage UI state for
/// capacity planning screens and components.
library;

import 'package:flutter/foundation.dart';

// Core imports
import '../../../../core/enums/role.dart';

// Domain entities
import '../../domain/entities/quarter_plan.dart';
import '../../domain/entities/initiative.dart';
import '../../domain/entities/capacity_allocation.dart';

// Use cases
import '../../domain/usecases/capacity_planning_usecases.dart';

/// State management for quarter plan operations
class QuarterPlanProvider extends ChangeNotifier {
  QuarterPlanProvider({
    required CreateQuarterPlan createQuarterPlan,
    required LoadQuarterPlan loadQuarterPlan,
    required GetCapacityAnalytics getCapacityAnalytics,
  }) : _createQuarterPlan = createQuarterPlan,
       _loadQuarterPlan = loadQuarterPlan,
       _getCapacityAnalytics = getCapacityAnalytics;

  final CreateQuarterPlan _createQuarterPlan;
  final LoadQuarterPlan _loadQuarterPlan;
  final GetCapacityAnalytics _getCapacityAnalytics;

  // State variables
  QuarterPlan? _currentPlan;
  CapacityAnalytics? _analytics;
  bool _isLoading = false;
  String? _error;

  // Getters
  QuarterPlan? get currentPlan => _currentPlan;
  CapacityAnalytics? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasPlan => _currentPlan != null;

  /// Creates a new quarter plan
  Future<bool> createPlan({
    required int quarter,
    required int year,
    String? name,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _createQuarterPlan.execute(
      quarter: quarter,
      year: year,
      name: name,
      notes: notes,
    );

    if (result.isSuccess) {
      _currentPlan = result.value;
      await _loadAnalytics();
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Loads an existing quarter plan
  Future<bool> loadPlan(String planId) async {
    _setLoading(true);
    _clearError();

    final result = await _loadQuarterPlan.execute(planId);
    
    if (result.isSuccess) {
      _currentPlan = result.value;
      await _loadAnalytics();
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Refreshes the current plan and analytics
  Future<void> refresh() async {
    if (_currentPlan == null) return;
    await loadPlan(_currentPlan!.id);
  }

  /// Clears the current plan
  void clearPlan() {
    _currentPlan = null;
    _analytics = null;
    _clearError();
    notifyListeners();
  }

  /// Loads analytics for the current plan
  Future<void> _loadAnalytics() async {
    if (_currentPlan == null) return;

    final result = await _getCapacityAnalytics.execute(_currentPlan!.id);
    if (result.isSuccess) {
      _analytics = result.value;
    }
    // Don't treat analytics loading failure as critical
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

/// State management for initiative operations
class InitiativeProvider extends ChangeNotifier {
  InitiativeProvider({
    required AddInitiativeToPlan addInitiativeToPlan,
  }) : _addInitiativeToPlan = addInitiativeToPlan;

  final AddInitiativeToPlan _addInitiativeToPlan;

  // State variables
  bool _isLoading = false;
  String? _error;
  Initiative? _lastCreatedInitiative;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  Initiative? get lastCreatedInitiative => _lastCreatedInitiative;

  /// Adds a new initiative to a plan
  Future<bool> addInitiative({
    required String planId,
    required String name,
    required String description,
    required Map<Role, double> requiredRoles,
    required int priority,
    required int businessValue,
    List<String> dependencies = const [],
    List<String> tags = const [],
    String notes = '',
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _addInitiativeToPlan.execute(
      planId: planId,
      name: name,
      description: description,
      requiredRoles: requiredRoles,
      priority: priority,
      businessValue: businessValue,
      dependencies: dependencies,
      tags: tags,
      notes: notes,
    );

    if (result.isSuccess) {
      _lastCreatedInitiative = result.value;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Clears the last created initiative
  void clearLastCreated() {
    _lastCreatedInitiative = null;
    notifyListeners();
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

/// State management for capacity allocation operations
class AllocationProvider extends ChangeNotifier {
  AllocationProvider({
    required AllocateCapacity allocateCapacity,
  }) : _allocateCapacity = allocateCapacity;

  final AllocateCapacity _allocateCapacity;

  // State variables
  bool _isLoading = false;
  String? _error;
  CapacityAllocation? _lastCreatedAllocation;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  CapacityAllocation? get lastCreatedAllocation => _lastCreatedAllocation;

  /// Creates a new capacity allocation
  Future<bool> allocateCapacity({
    required String planId,
    required String teamMemberId,
    required String initiativeId,
    required Role role,
    required double allocatedWeeks,
    required DateTime startDate,
    required DateTime endDate,
    String notes = '',
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _allocateCapacity.execute(
      planId: planId,
      teamMemberId: teamMemberId,
      initiativeId: initiativeId,
      role: role,
      allocatedWeeks: allocatedWeeks,
      startDate: startDate,
      endDate: endDate,
      notes: notes,
    );

    if (result.isSuccess) {
      _lastCreatedAllocation = result.value;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Clears the last created allocation
  void clearLastCreated() {
    _lastCreatedAllocation = null;
    notifyListeners();
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
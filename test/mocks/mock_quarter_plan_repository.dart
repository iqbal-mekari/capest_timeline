/// Mock implementation of QuarterPlanRepository for testing.
/// 
/// This mock will be replaced with actual repository interfaces and 
/// implementation when they are created in Phase 3.3+.
library;

import 'dart:convert';

/// Mock QuarterPlan entity (placeholder until actual entity is implemented)
class MockQuarterPlan {
  const MockQuarterPlan({
    required this.id,
    required this.quarter,
    required this.year,
    required this.teamMembers,
    required this.initiatives,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int quarter;
  final int year;
  final List<MockTeamMember> teamMembers;
  final List<MockInitiative> initiatives;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quarter': quarter,
      'year': year,
      'teamMembers': teamMembers.map((m) => m.toJson()).toList(),
      'initiatives': initiatives.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

/// Mock TeamMember entity (placeholder until actual entity is implemented)
class MockTeamMember {
  const MockTeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.capacity,
  });

  final String id;
  final String name;
  final String role;
  final double capacity;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'capacity': capacity,
    };
  }
}

/// Mock Initiative entity (placeholder until actual entity is implemented)
class MockInitiative {
  const MockInitiative({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
  });

  final String id;
  final String title;
  final String description;
  final int priority;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
    };
  }
}

/// Mock repository for quarter plan operations
class MockQuarterPlanRepository {
  final Map<String, MockQuarterPlan> _plans = {};
  bool _shouldFailSave = false;
  bool _shouldFailLoad = false;

  /// Simulates saving a quarter plan
  Future<void> saveQuarterPlan(MockQuarterPlan plan) async {
    if (_shouldFailSave) {
      throw Exception('Simulated storage failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async operation
    _plans[plan.id] = plan;
  }

  /// Simulates loading a quarter plan by ID
  Future<MockQuarterPlan?> loadQuarterPlan(String id) async {
    if (_shouldFailLoad) {
      throw Exception('Simulated load failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate async operation
    return _plans[id];
  }

  /// Simulates loading all quarter plans
  Future<List<MockQuarterPlan>> loadAllQuarterPlans() async {
    if (_shouldFailLoad) {
      throw Exception('Simulated load failure');
    }
    
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async operation
    return _plans.values.toList();
  }

  /// Simulates deleting a quarter plan
  Future<void> deleteQuarterPlan(String id) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate async operation
    _plans.remove(id);
  }

  /// Simulates checking if a plan exists
  Future<bool> planExists(String id) async {
    await Future.delayed(const Duration(milliseconds: 25)); // Simulate async operation
    return _plans.containsKey(id);
  }

  /// Sets up the mock to simulate storage failures
  void setupStorageFailure() {
    _shouldFailSave = true;
  }

  /// Sets up the mock to simulate load failures
  void setupLoadFailure() {
    _shouldFailLoad = true;
  }

  /// Clears failure simulation
  void clearStorageFailure() {
    _shouldFailSave = false;
  }

  /// Clears load failure simulation
  void clearLoadFailure() {
    _shouldFailLoad = false;
  }

  /// Clears all stored plans (for test cleanup)
  void clearAllPlans() {
    _plans.clear();
  }

  /// Gets count of stored plans (for testing)
  int get planCount => _plans.length;

  /// Gets all plan IDs (for testing)
  List<String> get planIds => _plans.keys.toList();
}
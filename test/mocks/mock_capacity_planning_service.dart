/// Mock implementation of CapacityPlanningService for testing.
/// 
/// This mock will be replaced with actual service interfaces and 
/// implementation when they are created in Phase 3.3+.
library;

import 'mock_quarter_plan_repository.dart';

/// Mock validation result for capacity planning operations
class MockValidationResult {
  const MockValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Mock capacity utilization data
class MockCapacityUtilization {
  const MockCapacityUtilization({
    required this.memberId,
    required this.memberName,
    required this.totalCapacity,
    required this.allocatedCapacity,
    required this.utilizationPercentage,
  });

  final String memberId;
  final String memberName;
  final double totalCapacity;
  final double allocatedCapacity;
  final double utilizationPercentage;

  bool get isOverAllocated => utilizationPercentage > 100.0;
  bool get isUnderUtilized => utilizationPercentage < 70.0;
}

/// Mock allocation conflict data
class MockAllocationConflict {
  const MockAllocationConflict({
    required this.memberId,
    required this.memberName,
    required this.conflictingInitiatives,
    required this.totalAllocation,
    required this.conflictType,
  });

  final String memberId;
  final String memberName;
  final List<String> conflictingInitiatives;
  final double totalAllocation;
  final String conflictType; // 'over_allocation', 'time_conflict', 'skill_mismatch'
}

/// Mock service for capacity planning business logic
class MockCapacityPlanningService {
  bool _shouldFailValidation = false;
  String _validationErrorMessage = '';
  final List<MockCapacityUtilization> _utilizationData = [];
  final List<MockAllocationConflict> _conflicts = [];

  /// Simulates validating a quarter plan
  Future<MockValidationResult> validateQuarterPlan(MockQuarterPlan plan) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async operation
    
    if (_shouldFailValidation) {
      return MockValidationResult(
        isValid: false,
        errors: [_validationErrorMessage],
      );
    }

    // Simulate business rule validation
    final errors = <String>[];
    final warnings = <String>[];

    // Check for over-allocation
    for (final member in plan.teamMembers) {
      if (member.capacity > 100.0) {
        errors.add('Team member ${member.name} is over-allocated (${member.capacity}%)');
      } else if (member.capacity > 90.0) {
        warnings.add('Team member ${member.name} has high utilization (${member.capacity}%)');
      }
    }

    // Check for initiatives without allocations
    if (plan.initiatives.isNotEmpty && plan.teamMembers.isEmpty) {
      errors.add('Initiatives exist but no team members are allocated');
    }

    // Check for invalid quarter/year
    if (plan.quarter < 1 || plan.quarter > 4) {
      errors.add('Quarter must be between 1 and 4');
    }

    if (plan.year < 2020 || plan.year > 2050) {
      errors.add('Year must be between 2020 and 2050');
    }

    return MockValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Simulates calculating capacity utilization for all team members
  Future<List<MockCapacityUtilization>> calculateCapacityUtilization(MockQuarterPlan plan) async {
    await Future.delayed(const Duration(milliseconds: 150)); // Simulate async operation
    
    final utilizations = <MockCapacityUtilization>[];
    
    for (final member in plan.teamMembers) {
      utilizations.add(MockCapacityUtilization(
        memberId: member.id,
        memberName: member.name,
        totalCapacity: 100.0, // Assume 100% capacity
        allocatedCapacity: member.capacity,
        utilizationPercentage: member.capacity,
      ));
    }

    _utilizationData.clear();
    _utilizationData.addAll(utilizations);
    
    return utilizations;
  }

  /// Simulates detecting allocation conflicts
  Future<List<MockAllocationConflict>> detectAllocationConflicts(MockQuarterPlan plan) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate async operation
    
    final conflicts = <MockAllocationConflict>[];
    
    for (final member in plan.teamMembers) {
      if (member.capacity > 100.0) {
        conflicts.add(MockAllocationConflict(
          memberId: member.id,
          memberName: member.name,
          conflictingInitiatives: plan.initiatives.map((i) => i.title).toList(),
          totalAllocation: member.capacity,
          conflictType: 'over_allocation',
        ));
      }
    }

    _conflicts.clear();
    _conflicts.addAll(conflicts);
    
    return conflicts;
  }

  /// Simulates optimizing allocations to resolve conflicts
  Future<MockQuarterPlan> optimizeAllocations(MockQuarterPlan plan) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate async operation
    
    // Simple optimization: cap all allocations at 100%
    final optimizedMembers = plan.teamMembers.map((member) {
      return MockTeamMember(
        id: member.id,
        name: member.name,
        role: member.role,
        capacity: member.capacity > 100.0 ? 100.0 : member.capacity,
      );
    }).toList();

    return MockQuarterPlan(
      id: plan.id,
      quarter: plan.quarter,
      year: plan.year,
      teamMembers: optimizedMembers,
      initiatives: plan.initiatives,
      createdAt: plan.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Simulates calculating initiative effort requirements
  Future<Map<String, double>> calculateInitiativeEffort(List<MockInitiative> initiatives) async {
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate async operation
    
    final efforts = <String, double>{};
    
    for (final initiative in initiatives) {
      // Mock effort calculation based on priority
      final effort = initiative.priority * 10.0; // Simple formula
      efforts[initiative.id] = effort;
    }
    
    return efforts;
  }

  /// Simulates generating capacity planning recommendations
  Future<List<String>> generateRecommendations(MockQuarterPlan plan) async {
    await Future.delayed(const Duration(milliseconds: 150)); // Simulate async operation
    
    final recommendations = <String>[];
    
    // Analyze utilization and provide recommendations
    for (final member in plan.teamMembers) {
      if (member.capacity > 100.0) {
        recommendations.add('Reduce allocation for ${member.name} to avoid burnout');
      } else if (member.capacity < 70.0) {
        recommendations.add('Consider increasing allocation for ${member.name}');
      }
    }

    if (plan.initiatives.length > plan.teamMembers.length * 2) {
      recommendations.add('Consider adding more team members or reducing scope');
    }

    return recommendations;
  }

  /// Sets up the mock to simulate validation errors
  void setupValidationError(String errorMessage) {
    _shouldFailValidation = true;
    _validationErrorMessage = errorMessage;
  }

  /// Clears validation error simulation
  void clearValidationError() {
    _shouldFailValidation = false;
    _validationErrorMessage = '';
  }

  /// Gets current utilization data (for testing)
  List<MockCapacityUtilization> get currentUtilization => List.unmodifiable(_utilizationData);

  /// Gets current conflicts (for testing)
  List<MockAllocationConflict> get currentConflicts => List.unmodifiable(_conflicts);

  /// Clears internal state (for test cleanup)
  void clearState() {
    _utilizationData.clear();
    _conflicts.clear();
    clearValidationError();
  }

  /// Simulates batch processing of multiple plans
  Future<Map<String, MockValidationResult>> validateMultiplePlans(List<MockQuarterPlan> plans) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate async operation
    
    final results = <String, MockValidationResult>{};
    
    for (final plan in plans) {
      results[plan.id] = await validateQuarterPlan(plan);
    }
    
    return results;
  }

  /// Simulates real-time validation during plan editing
  Future<MockValidationResult> validateIncrementalChange({
    required MockQuarterPlan plan,
    String? addedMemberId,
    String? removedMemberId,
    String? addedInitiativeId,
    String? removedInitiativeId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50)); // Simulate async operation
    
    // Lightweight validation for incremental changes
    if (addedMemberId != null) {
      final member = plan.teamMembers.firstWhere((m) => m.id == addedMemberId);
      if (member.capacity > 100.0) {
        return const MockValidationResult(
          isValid: false,
          errors: ['Added member would cause over-allocation'],
        );
      }
    }

    return const MockValidationResult(isValid: true);
  }
}
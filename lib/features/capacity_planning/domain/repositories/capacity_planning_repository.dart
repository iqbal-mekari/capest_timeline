import '../../domain/entities/initiative.dart';
import '../../domain/entities/quarter_plan.dart';
import '../../domain/entities/capacity_allocation.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Repository interface for capacity planning operations.
/// 
/// This repository handles persistence and retrieval of:
/// - Quarter plans and their metadata
/// - Initiatives within plans
/// - Capacity allocations between team members and initiatives
abstract class CapacityPlanningRepository {
  /// Saves a complete quarter plan
  Future<Result<void, StorageException>> savePlan(QuarterPlan plan);

  /// Loads a quarter plan by ID
  Future<Result<QuarterPlan?, StorageException>> loadPlan(String planId);

  /// Lists all available quarter plans (metadata only)
  Future<Result<List<QuarterPlanMetadata>, StorageException>> listPlans();

  /// Deletes a quarter plan by ID
  Future<Result<void, StorageException>> deletePlan(String planId);

  /// Checks if a plan exists
  Future<Result<bool, StorageException>> planExists(String planId);

  /// Saves an individual initiative within a plan
  Future<Result<void, StorageException>> saveInitiative(
    String planId,
    Initiative initiative,
  );

  /// Loads an initiative by ID from a specific plan
  Future<Result<Initiative?, StorageException>> loadInitiative(
    String planId,
    String initiativeId,
  );

  /// Lists all initiatives in a plan
  Future<Result<List<Initiative>, StorageException>> listInitiatives(
    String planId,
  );

  /// Deletes an initiative from a plan
  Future<Result<void, StorageException>> deleteInitiative(
    String planId,
    String initiativeId,
  );

  /// Saves a capacity allocation
  Future<Result<void, StorageException>> saveAllocation(
    String planId,
    CapacityAllocation allocation,
  );

  /// Loads a capacity allocation by ID
  Future<Result<CapacityAllocation?, StorageException>> loadAllocation(
    String planId,
    String allocationId,
  );

  /// Lists all allocations in a plan
  Future<Result<List<CapacityAllocation>, StorageException>> listAllocations(
    String planId,
  );

  /// Lists allocations for a specific team member
  Future<Result<List<CapacityAllocation>, StorageException>> listAllocationsForMember(
    String planId,
    String memberId,
  );

  /// Lists allocations for a specific initiative
  Future<Result<List<CapacityAllocation>, StorageException>> listAllocationsForInitiative(
    String planId,
    String initiativeId,
  );

  /// Deletes a capacity allocation
  Future<Result<void, StorageException>> deleteAllocation(
    String planId,
    String allocationId,
  );

  /// Bulk operations for better performance
  /// Saves multiple initiatives at once
  Future<Result<void, StorageException>> saveInitiatives(
    String planId,
    List<Initiative> initiatives,
  );

  /// Saves multiple allocations at once
  Future<Result<void, StorageException>> saveAllocations(
    String planId,
    List<CapacityAllocation> allocations,
  );

  /// Gets the last modified timestamp for a plan
  Future<Result<DateTime?, StorageException>> getPlanLastModified(String planId);

  /// Backs up a plan to a JSON string
  Future<Result<String, StorageException>> exportPlan(String planId);

  /// Restores a plan from a JSON string
  Future<Result<void, StorageException>> importPlan(String jsonData);
}

/// Metadata about a quarter plan (for listing purposes)
class QuarterPlanMetadata {
  const QuarterPlanMetadata({
    required this.id,
    required this.quarter,
    required this.year,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.isLocked,
    required this.initiativeCount,
    required this.teamMemberCount,
    required this.allocationCount,
  });

  final String id;
  final int quarter;
  final int year;
  final String? name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isLocked;
  final int initiativeCount;
  final int teamMemberCount;
  final int allocationCount;

  String get displayName => name ?? 'Q$quarter $year';

  factory QuarterPlanMetadata.fromPlan(QuarterPlan plan) {
    return QuarterPlanMetadata(
      id: plan.id,
      quarter: plan.quarter,
      year: plan.year,
      name: plan.name,
      createdAt: plan.createdAt ?? DateTime.now(),
      updatedAt: plan.updatedAt ?? DateTime.now(),
      isLocked: plan.isLocked,
      initiativeCount: plan.initiatives.length,
      teamMemberCount: plan.teamMembers.length,
      allocationCount: plan.allocations.length,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quarter': quarter,
      'year': year,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isLocked': isLocked,
      'initiativeCount': initiativeCount,
      'teamMemberCount': teamMemberCount,
      'allocationCount': allocationCount,
    };
  }

  factory QuarterPlanMetadata.fromMap(Map<String, dynamic> map) {
    return QuarterPlanMetadata(
      id: map['id'] as String,
      quarter: map['quarter'] as int,
      year: map['year'] as int,
      name: map['name'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isLocked: map['isLocked'] as bool,
      initiativeCount: map['initiativeCount'] as int,
      teamMemberCount: map['teamMemberCount'] as int,
      allocationCount: map['allocationCount'] as int,
    );
  }
}
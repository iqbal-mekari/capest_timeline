import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/quarter_plan.dart';
import '../../domain/entities/initiative.dart';
import '../../domain/entities/capacity_allocation.dart';
import '../../domain/repositories/capacity_planning_repository.dart';

class CapacityPlanningRepositoryImpl implements CapacityPlanningRepository {
  final SharedPreferences _prefs;
  
  // Storage keys
  static const String _plansKey = 'quarter_plans';
  static const String _metadataKey = 'quarter_plans_metadata';
  
  const CapacityPlanningRepositoryImpl(this._prefs);

  @override
  Future<Result<void, StorageException>> savePlan(QuarterPlan plan) async {
    try {
      // Save the full plan
      final plansResult = await _getPlansMap();
      if (plansResult.isError) {
        return Result.error(plansResult.error);
      }

      final plans = plansResult.value;
      plans[plan.id] = plan.toMap();

      final success = await _prefs.setString(_plansKey, jsonEncode(plans));
      if (!success) {
        return Result.error(const StorageException(
          'Failed to save quarter plan',
          StorageErrorType.unknown,
        ));
      }

      // Update metadata
      await _updateMetadata(plan);

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save quarter plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<QuarterPlan?, StorageException>> loadPlan(String planId) async {
    try {
      final plansResult = await _getPlansMap();
      if (plansResult.isError) {
        return Result.error(plansResult.error);
      }

      final planData = plansResult.value[planId];
      if (planData == null) {
        return const Result.success(null);
      }

      final plan = QuarterPlan.fromMap(planData as Map<String, dynamic>);
      return Result.success(plan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load quarter plan: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<List<QuarterPlanMetadata>, StorageException>> listPlans() async {
    try {
      final jsonString = _prefs.getString(_metadataKey);
      if (jsonString == null) {
        return const Result.success([]);
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final metadata = jsonList
          .map((json) => QuarterPlanMetadata.fromMap(json as Map<String, dynamic>))
          .toList();

      return Result.success(metadata);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list quarter plans: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> deletePlan(String planId) async {
    try {
      final plansResult = await _getPlansMap();
      if (plansResult.isError) {
        return Result.error(plansResult.error);
      }

      final plans = plansResult.value;
      plans.remove(planId);

      final success = await _prefs.setString(_plansKey, jsonEncode(plans));
      if (!success) {
        return Result.error(const StorageException(
          'Failed to delete quarter plan',
          StorageErrorType.unknown,
        ));
      }

      // Remove from metadata
      await _removeFromMetadata(planId);

      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to delete quarter plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<bool, StorageException>> planExists(String planId) async {
    try {
      final plansResult = await _getPlansMap();
      if (plansResult.isError) {
        return Result.error(plansResult.error);
      }

      return Result.success(plansResult.value.containsKey(planId));
    } catch (e) {
      return Result.error(StorageException(
        'Failed to check plan existence: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> saveInitiative(
    String planId,
    Initiative initiative,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return Result.error(StorageException(
          'Plan not found: $planId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedInitiatives = List<Initiative>.from(plan.initiatives);
      final existingIndex = updatedInitiatives.indexWhere((i) => i.id == initiative.id);

      if (existingIndex >= 0) {
        updatedInitiatives[existingIndex] = initiative;
      } else {
        updatedInitiatives.add(initiative);
      }

      final updatedPlan = plan.copyWith(
        initiatives: updatedInitiatives,
        updatedAt: DateTime.now(),
      );

      return await savePlan(updatedPlan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save initiative: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<Initiative?, StorageException>> loadInitiative(
    String planId,
    String initiativeId,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return const Result.success(null);
      }

      final initiative = plan.initiatives.where((i) => i.id == initiativeId).firstOrNull;
      return Result.success(initiative);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load initiative: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<List<Initiative>, StorageException>> listInitiatives(
    String planId,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return const Result.success([]);
      }

      return Result.success(List<Initiative>.from(plan.initiatives));
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list initiatives: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> deleteInitiative(
    String planId,
    String initiativeId,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return Result.error(StorageException(
          'Plan not found: $planId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedInitiatives = plan.initiatives.where((i) => i.id != initiativeId).toList();
      final updatedPlan = plan.copyWith(
        initiatives: updatedInitiatives,
        updatedAt: DateTime.now(),
      );

      return await savePlan(updatedPlan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to delete initiative: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> saveAllocation(
    String planId,
    CapacityAllocation allocation,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return Result.error(StorageException(
          'Plan not found: $planId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedAllocations = List<CapacityAllocation>.from(plan.allocations);
      final existingIndex = updatedAllocations.indexWhere((a) => a.id == allocation.id);

      if (existingIndex >= 0) {
        updatedAllocations[existingIndex] = allocation;
      } else {
        updatedAllocations.add(allocation);
      }

      final updatedPlan = plan.copyWith(
        allocations: updatedAllocations,
        updatedAt: DateTime.now(),
      );

      return await savePlan(updatedPlan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save allocation: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<CapacityAllocation?, StorageException>> loadAllocation(
    String planId,
    String allocationId,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return const Result.success(null);
      }

      final allocation = plan.allocations.where((a) => a.id == allocationId).firstOrNull;
      return Result.success(allocation);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load allocation: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<List<CapacityAllocation>, StorageException>> listAllocations(
    String planId,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return const Result.success([]);
      }

      return Result.success(List<CapacityAllocation>.from(plan.allocations));
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list allocations: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<List<CapacityAllocation>, StorageException>> listAllocationsForMember(
    String planId,
    String memberId,
  ) async {
    try {
      final allocationsResult = await listAllocations(planId);
      if (allocationsResult.isError) {
        return Result.error(allocationsResult.error);
      }

      final memberAllocations = allocationsResult.value
          .where((a) => a.teamMemberId == memberId)
          .toList();

      return Result.success(memberAllocations);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list member allocations: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<List<CapacityAllocation>, StorageException>> listAllocationsForInitiative(
    String planId,
    String initiativeId,
  ) async {
    try {
      final allocationsResult = await listAllocations(planId);
      if (allocationsResult.isError) {
        return Result.error(allocationsResult.error);
      }

      final initiativeAllocations = allocationsResult.value
          .where((a) => a.initiativeId == initiativeId)
          .toList();

      return Result.success(initiativeAllocations);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list initiative allocations: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> deleteAllocation(
    String planId,
    String allocationId,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return Result.error(StorageException(
          'Plan not found: $planId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedAllocations = plan.allocations.where((a) => a.id != allocationId).toList();
      final updatedPlan = plan.copyWith(
        allocations: updatedAllocations,
        updatedAt: DateTime.now(),
      );

      return await savePlan(updatedPlan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to delete allocation: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> saveInitiatives(
    String planId,
    List<Initiative> initiatives,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return Result.error(StorageException(
          'Plan not found: $planId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedPlan = plan.copyWith(
        initiatives: initiatives,
        updatedAt: DateTime.now(),
      );

      return await savePlan(updatedPlan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save initiatives: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> saveAllocations(
    String planId,
    List<CapacityAllocation> allocations,
  ) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return Result.error(StorageException(
          'Plan not found: $planId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedPlan = plan.copyWith(
        allocations: allocations,
        updatedAt: DateTime.now(),
      );

      return await savePlan(updatedPlan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save allocations: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<DateTime?, StorageException>> getPlanLastModified(String planId) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      return Result.success(plan?.updatedAt);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get plan last modified: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<String, StorageException>> exportPlan(String planId) async {
    try {
      final planResult = await loadPlan(planId);
      if (planResult.isError) {
        return Result.error(planResult.error);
      }

      final plan = planResult.value;
      if (plan == null) {
        return Result.error(StorageException(
          'Plan not found: $planId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final jsonString = jsonEncode(plan.toMap());
      return Result.success(jsonString);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to export plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> importPlan(String jsonData) async {
    try {
      final Map<String, dynamic> planData = jsonDecode(jsonData);
      final plan = QuarterPlan.fromMap(planData);
      return await savePlan(plan);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to import plan: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  // Private helper methods
  Future<Result<Map<String, dynamic>, StorageException>> _getPlansMap() async {
    try {
      final jsonString = _prefs.getString(_plansKey);
      if (jsonString == null) {
        return const Result.success({});
      }

      final Map<String, dynamic> plans = jsonDecode(jsonString);
      return Result.success(plans);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load plans map: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  Future<void> _updateMetadata(QuarterPlan plan) async {
    try {
      final metadataResult = await listPlans();
      final metadataList = metadataResult.valueOrNull ?? [];

      // Remove existing metadata for this plan
      metadataList.removeWhere((m) => m.id == plan.id);

      // Add new metadata
      metadataList.add(QuarterPlanMetadata.fromPlan(plan));

      final jsonString = jsonEncode(metadataList.map((m) => m.toMap()).toList());
      await _prefs.setString(_metadataKey, jsonString);
    } catch (e) {
      // Metadata update failure is not critical, we can continue
      // In a production app, we might want to log this error
    }
  }

  Future<void> _removeFromMetadata(String planId) async {
    try {
      final metadataResult = await listPlans();
      final metadataList = metadataResult.valueOrNull ?? [];

      metadataList.removeWhere((m) => m.id == planId);

      final jsonString = jsonEncode(metadataList.map((m) => m.toMap()).toList());
      await _prefs.setString(_metadataKey, jsonString);
    } catch (e) {
      // Metadata update failure is not critical, we can continue
    }
  }
}
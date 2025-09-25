import '../../core/errors/exceptions.dart';
import '../../core/types/result.dart';
import '../../features/capacity_planning/domain/entities/quarter_plan.dart';
import '../../features/capacity_planning/domain/repositories/capacity_planning_repository.dart';
import '../../features/configuration/data/datasources/local_storage_datasource.dart';

/// Abstract interface for quarter plan storage operations
abstract class QuarterPlanStorageService {
  /// Save quarter plan to local storage
  Future<Result<void, StorageException>> saveQuarterPlan(QuarterPlan plan);
  
  /// Load quarter plan from local storage
  Future<Result<QuarterPlan?, StorageException>> loadQuarterPlan(String planId);
  
  /// List all saved quarter plans metadata
  Future<Result<List<QuarterPlanMetadata>, StorageException>> listQuarterPlans();
  
  /// Delete quarter plan from storage
  Future<Result<void, StorageException>> deleteQuarterPlan(String planId);
}

/// Implementation of QuarterPlanStorageService using LocalStorageDataSource
class QuarterPlanStorageServiceImpl implements QuarterPlanStorageService {
  const QuarterPlanStorageServiceImpl({
    required LocalStorageDataSource dataSource,
  }) : _dataSource = dataSource;

  final LocalStorageDataSource _dataSource;

  @override
  Future<Result<void, StorageException>> saveQuarterPlan(QuarterPlan plan) async {
    try {
      // Validate the plan before saving
      final validationResult = plan.validate();
      if (validationResult.isError) {
        return Result.error(StorageException(
          'Invalid quarter plan: ${validationResult.error.message}',
          StorageErrorType.dataCorrupted,
        ));
      }

      // Initialize storage
      final initResult = await _dataSource.initialize();
      if (initResult.isError) {
        return Result.error(initResult.error);
      }

      // Save the plan data using the existing method
      await _dataSource.saveQuarterPlan(plan.id, plan.toMap());

      return const Result.success(null);
    } catch (e) {
      if (e is StorageException) {
        return Result.error(e);
      }
      return Result.error(StorageException(
        'Failed to save quarter plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<QuarterPlan?, StorageException>> loadQuarterPlan(String planId) async {
    try {
      if (planId.trim().isEmpty) {
        return Result.error(StorageException(
          'Plan ID cannot be empty',
          StorageErrorType.dataCorrupted,
        ));
      }

      // Initialize storage
      final initResult = await _dataSource.initialize();
      if (initResult.isError) {
        return Result.error(initResult.error);
      }

      // Load the plan data using the existing method
      final planData = await _dataSource.getQuarterPlan(planId);
      if (planData == null) {
        return const Result.success(null);
      }

      // Parse the plan data
      final plan = QuarterPlan.fromMap(planData);
      
      return Result.success(plan);
    } catch (e) {
      if (e is StorageException) {
        return Result.error(e);
      }
      return Result.error(StorageException(
        'Failed to load quarter plan: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<List<QuarterPlanMetadata>, StorageException>> listQuarterPlans() async {
    try {
      // Initialize storage
      final initResult = await _dataSource.initialize();
      if (initResult.isError) {
        return Result.error(initResult.error);
      }

      // Load summaries using the existing method
      final summaries = await _dataSource.getQuarterPlanSummaries();

      // Convert summaries to metadata
      final metadata = summaries.map((summary) {
        return QuarterPlanMetadata(
          id: summary['id'] as String,
          quarter: summary['quarter'] as int,
          year: summary['year'] as int,
          name: summary['displayName'] as String?,
          createdAt: DateTime.parse(summary['lastModified'] as String),
          updatedAt: DateTime.parse(summary['lastModified'] as String),
          isLocked: false, // Default value, update if summary contains this
          initiativeCount: summary['initiativeCount'] as int? ?? 0,
          teamMemberCount: summary['teamMemberCount'] as int? ?? 0,
          allocationCount: summary['allocationCount'] as int? ?? 0,
        );
      }).toList();

      // Sort by year and quarter
      metadata.sort((a, b) {
        final yearComparison = b.year.compareTo(a.year);
        if (yearComparison != 0) return yearComparison;
        return b.quarter.compareTo(a.quarter);
      });

      return Result.success(metadata);
    } catch (e) {
      if (e is StorageException) {
        return Result.error(e);
      }
      return Result.error(StorageException(
        'Failed to list quarter plans: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> deleteQuarterPlan(String planId) async {
    try {
      if (planId.trim().isEmpty) {
        return Result.error(StorageException(
          'Plan ID cannot be empty',
          StorageErrorType.dataCorrupted,
        ));
      }

      // Initialize storage
      final initResult = await _dataSource.initialize();
      if (initResult.isError) {
        return Result.error(initResult.error);
      }

      // Delete the plan using the existing method
      await _dataSource.deleteQuarterPlan(planId);

      return const Result.success(null);
    } catch (e) {
      if (e is StorageException) {
        return Result.error(e);
      }
      return Result.error(StorageException(
        'Failed to delete quarter plan: $e',
        StorageErrorType.unknown,
      ));
    }
  }
}
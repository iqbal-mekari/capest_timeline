import '../../domain/entities/quarter_plan.dart';
import '../../domain/repositories/quarter_plan_repository.dart';
import '../../../configuration/data/datasources/local_storage_data_source.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Implementation of QuarterPlanRepository using local storage
class QuarterPlanRepositoryImpl implements QuarterPlanRepository {
  final LocalStorageDataSource _dataSource;

  const QuarterPlanRepositoryImpl(this._dataSource);

  @override
  Future<Result<void, StorageException>> saveQuarterPlan(QuarterPlan plan) async {
    try {
      if (!await isStorageAvailable()) {
        return Result.error(
          const StorageException(
            'Storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final key = '${StorageKeys.quarterPlanPrefix}${plan.id}';
      final data = _planToJson(plan);
      
      return await _dataSource.store(key, data);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to save quarter plan: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Result<QuarterPlan?, StorageException>> loadQuarterPlan(String planId) async {
    try {
      if (!await isStorageAvailable()) {
        return Result.error(
          const StorageException(
            'Storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final key = '${StorageKeys.quarterPlanPrefix}$planId';
      final result = await _dataSource.retrieve(key);
      
      if (result.isError) {
        return Result.error(result.error);
      }

      final data = result.value;
      if (data == null) {
        return const Result.success(null);
      }

      try {
        final plan = _planFromJson(data);
        return Result.success(plan);
      } catch (e) {
        return Result.error(
          StorageException(
            'Failed to parse quarter plan data: ${e.toString()}',
            StorageErrorType.dataCorrupted,
            e is Exception ? e : Exception(e.toString()),
          ),
        );
      }
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to load quarter plan: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Result<List<QuarterPlanMetadata>, StorageException>> listQuarterPlans() async {
    try {
      if (!await isStorageAvailable()) {
        return Result.error(
          const StorageException(
            'Storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final keysResult = await _dataSource.listKeys(StorageKeys.quarterPlanPrefix);
      if (keysResult.isError) {
        return Result.error(keysResult.error);
      }

      final keys = keysResult.value;
      final metadata = <QuarterPlanMetadata>[];

      for (final key in keys) {
        final dataResult = await _dataSource.retrieve(key);
        if (dataResult.isError) {
          // Skip corrupted entries but continue processing others
          continue;
        }

        final data = dataResult.value;
        if (data == null) continue;

        try {
          final planMetadata = _metadataFromJson(data, key);
          metadata.add(planMetadata);
        } catch (e) {
          // Skip corrupted entries but continue processing others
          continue;
        }
      }

      // Sort by last modified date (most recent first)
      metadata.sort((a, b) => b.lastModified.compareTo(a.lastModified));

      return Result.success(metadata);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to list quarter plans: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Result<void, StorageException>> deleteQuarterPlan(String planId) async {
    try {
      if (!await isStorageAvailable()) {
        return Result.error(
          const StorageException(
            'Storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final key = '${StorageKeys.quarterPlanPrefix}$planId';
      return await _dataSource.remove(key);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to delete quarter plan: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<bool> isStorageAvailable() async {
    return await _dataSource.isAvailable();
  }

  /// Convert QuarterPlan to JSON for storage
  Map<String, dynamic> _planToJson(QuarterPlan plan) {
    // Use the entity's built-in toMap method
    final planMap = plan.toMap();
    
    // Add computed fields for metadata queries
    final (startDate, endDate) = plan.quarterDateRange;
    planMap['_startDate'] = startDate.toIso8601String();
    planMap['_endDate'] = endDate.toIso8601String();
    planMap['_lastModified'] = plan.updatedAt?.toIso8601String() ?? DateTime.now().toIso8601String();
    planMap['_version'] = 1; // Schema version for future migrations
    
    return planMap;
  }

  /// Convert JSON to QuarterPlan
  QuarterPlan _planFromJson(Map<String, dynamic> json) {
    // Use the entity's built-in fromMap method
    return QuarterPlan.fromMap(json);
  }

  /// Extract metadata from JSON without full deserialization
  QuarterPlanMetadata _metadataFromJson(Map<String, dynamic> json, String key) {
    final planId = key.substring(StorageKeys.quarterPlanPrefix.length);
    final teamMembers = json['teamMembers'] as List<dynamic>? ?? [];
    final initiatives = json['initiatives'] as List<dynamic>? ?? [];


    // Use computed fields if available, otherwise calculate from quarter/year
    DateTime startDate, endDate;
    if (json.containsKey('_startDate') && json.containsKey('_endDate')) {
      startDate = DateTime.parse(json['_startDate'] as String);
      endDate = DateTime.parse(json['_endDate'] as String);
    } else {
      // Calculate from quarter and year
      final quarter = json['quarter'] as int;
      final year = json['year'] as int;
      final startMonth = (quarter - 1) * 3 + 1;
      startDate = DateTime(year, startMonth, 1);
      endDate = DateTime(year, startMonth + 3, 0);
    }

    // Get last modified date
    DateTime lastModified;
    if (json.containsKey('_lastModified')) {
      lastModified = DateTime.parse(json['_lastModified'] as String);
    } else if (json.containsKey('updatedAt') && json['updatedAt'] != null) {
      lastModified = DateTime.parse(json['updatedAt'] as String);
    } else if (json.containsKey('createdAt') && json['createdAt'] != null) {
      lastModified = DateTime.parse(json['createdAt'] as String);
    } else {
      lastModified = DateTime.now();
    }

    // Generate display name
    String displayName;
    if (json['name'] != null && (json['name'] as String).isNotEmpty) {
      displayName = json['name'] as String;
    } else {
      final quarter = json['quarter'] as int? ?? 1;
      final year = json['year'] as int? ?? DateTime.now().year;
      displayName = 'Q$quarter $year';
    }

    return QuarterPlanMetadata(
      id: planId,
      name: displayName,
      startDate: startDate,
      endDate: endDate,
      teamMemberCount: teamMembers.length,
      initiativeCount: initiatives.length,
      lastModified: lastModified,
    );
  }


}
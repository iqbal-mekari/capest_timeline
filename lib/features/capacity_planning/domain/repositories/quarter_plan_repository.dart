import '../entities/quarter_plan.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Metadata for quarter plan listing
class QuarterPlanMetadata {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int teamMemberCount;
  final int initiativeCount;
  final DateTime lastModified;

  const QuarterPlanMetadata({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.teamMemberCount,
    required this.initiativeCount,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuarterPlanMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          teamMemberCount == other.teamMemberCount &&
          initiativeCount == other.initiativeCount &&
          lastModified == other.lastModified;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      teamMemberCount.hashCode ^
      initiativeCount.hashCode ^
      lastModified.hashCode;

  @override
  String toString() =>
      'QuarterPlanMetadata(id: $id, name: $name, period: $startDate - $endDate, '
      'members: $teamMemberCount, initiatives: $initiativeCount, modified: $lastModified)';
}

/// Repository interface for quarter plan persistence and retrieval
abstract class QuarterPlanRepository {
  /// Save quarter plan to persistent storage
  /// Returns: Success/failure result
  Future<Result<void, StorageException>> saveQuarterPlan(QuarterPlan plan);

  /// Load quarter plan from persistent storage
  /// Returns: Quarter plan or null if not found
  Future<Result<QuarterPlan?, StorageException>> loadQuarterPlan(String planId);

  /// List all saved quarter plans
  /// Returns: List of plan metadata (id, name, date range)
  Future<Result<List<QuarterPlanMetadata>, StorageException>> listQuarterPlans();

  /// Delete quarter plan from storage
  /// Returns: Success/failure result
  Future<Result<void, StorageException>> deleteQuarterPlan(String planId);

  /// Check if the underlying storage is available and accessible
  Future<bool> isStorageAvailable();
}
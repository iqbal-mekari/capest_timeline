import '../../domain/entities/application_state.dart';
import '../../domain/repositories/application_state_repository.dart';
import '../datasources/local_storage_data_source.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Implementation of ApplicationStateRepository using local storage
class ApplicationStateRepositoryImpl implements ApplicationStateRepository {
  final LocalStorageDataSource _dataSource;

  const ApplicationStateRepositoryImpl(this._dataSource);

  @override
  Future<Result<void, StorageException>> saveState(ApplicationState state) async {
    try {
      if (!await isStorageAvailable()) {
        return Result.error(
          const StorageException(
            'Storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      // Mark as saved in the state we're storing
      final stateToSave = state.markAsSaved();
      final data = stateToSave.toMap();
      
      // Add metadata for storage management
      data['_version'] = 1; // Schema version for future migrations
      data['_savedAt'] = DateTime.now().toIso8601String();
      
      return await _dataSource.store(StorageKeys.applicationState, data);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to save application state: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Result<ApplicationState, StorageException>> restoreState() async {
    try {
      if (!await isStorageAvailable()) {
        return Result.error(
          const StorageException(
            'Storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      final result = await _dataSource.retrieve(StorageKeys.applicationState);
      if (result.isError) {
        return Result.error(result.error);
      }

      final data = result.value;
      if (data == null) {
        // No saved state found, return default state
        return Result.success(_createDefaultState());
      }

      try {
        final state = ApplicationState.fromMap(data);
        
        // Validate the restored state
        final validation = state.validate();
        if (validation.isError) {
          // If validation fails, return default state and log the issue
          return Result.success(_createDefaultState());
        }
        
        return Result.success(state);
      } catch (e) {
        // If deserialization fails, return default state
        return Result.success(_createDefaultState());
      }
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to restore application state: ${e.toString()}',
          StorageErrorType.notAvailable,
          e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Result<void, StorageException>> resetState() async {
    try {
      if (!await isStorageAvailable()) {
        return Result.error(
          const StorageException(
            'Storage is not available',
            StorageErrorType.notAvailable,
          ),
        );
      }

      // Remove the stored state
      final removeResult = await _dataSource.remove(StorageKeys.applicationState);
      if (removeResult.isError) {
        return Result.error(removeResult.error);
      }

      return const Result.success(null);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to reset application state: ${e.toString()}',
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

  /// Creates a default application state for first-time users
  ApplicationState _createDefaultState() {
    final now = DateTime.now();
    final currentQuarter = ((now.month - 1) ~/ 3) + 1;
    final currentYear = now.year;

    return ApplicationState(
      currentPlanId: null,
      lastAccessedPlanIds: const [],
      viewMode: ViewMode.timeline,
      selectedQuarter: currentQuarter,
      selectedYear: currentYear,
      filters: const ApplicationFilters(),
      isAutoSaveEnabled: true,
      lastSaveTime: null,
      hasUnsavedChanges: false,
      createdAt: now,
      updatedAt: now,
    );
  }
}
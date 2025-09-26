import '../entities/application_state.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// Repository interface for application state persistence and retrieval
/// Handles auto-save functionality and session state management
abstract class ApplicationStateRepository {
  /// Auto-save current application state
  /// Called every 30 seconds and on significant changes
  Future<Result<void, StorageException>> saveState(ApplicationState state);

  /// Restore application state on startup
  /// Returns: Saved state or default state if none exists
  Future<Result<ApplicationState, StorageException>> restoreState();

  /// Reset all application state to defaults
  /// Clears all stored state data
  Future<Result<void, StorageException>> resetState();

  /// Check if auto-save is available (storage accessible)
  Future<bool> isStorageAvailable();
}
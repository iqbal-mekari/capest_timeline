# API Contracts: Capacity Estimation Application

**Date**: 2025-09-23  
**Type**: Local Storage API Contracts  
**Scope**: Data persistence and retrieval operations

## Overview

Since this is a single-user Flutter web application with local storage, the "API" contracts define the interface between the application and the browser's local storage, as well as internal service contracts for business operations.

## Storage Service Contracts

### QuarterPlanStorageService

```dart
abstract class QuarterPlanStorageService {
  /// Save quarter plan to local storage
  /// Returns: Success/failure result
  Future<Result<void, StorageException>> saveQuarterPlan(QuarterPlan plan);
  
  /// Load quarter plan from local storage
  /// Returns: Quarter plan or null if not found
  Future<Result<QuarterPlan?, StorageException>> loadQuarterPlan(String planId);
  
  /// List all saved quarter plans
  /// Returns: List of plan metadata (id, name, date range)
  Future<Result<List<QuarterPlanMetadata>, StorageException>> listQuarterPlans();
  
  /// Delete quarter plan from storage
  /// Returns: Success/failure result
  Future<Result<void, StorageException>> deleteQuarterPlan(String planId);
}
```

### ApplicationStateService

```dart
abstract class ApplicationStateService {
  /// Auto-save current application state
  /// Called every 30 seconds and on significant changes
  Future<Result<void, StorageException>> saveState(ApplicationState state);
  
  /// Restore application state on startup
  /// Returns: Saved state or default state if none exists
  Future<Result<ApplicationState, StorageException>> restoreState();
  
  /// Reset all application state to defaults
  /// Clears all local storage data
  Future<Result<void, StorageException>> resetState();
  
  /// Check if auto-save is available (local storage accessible)
  Future<bool> isStorageAvailable();
}
```

### ConfigurationService

```dart
abstract class ConfigurationService {
  /// Save user configuration preferences
  Future<Result<void, StorageException>> saveConfiguration(UserConfiguration config);
  
  /// Load user configuration preferences
  /// Returns: Saved config or default config if none exists
  Future<Result<UserConfiguration, StorageException>> loadConfiguration();
  
  /// Reset configuration to default values
  Future<Result<void, StorageException>> resetConfiguration();
}
```

## Business Logic Service Contracts

### CapacityPlanningService

```dart
abstract class CapacityPlanningService {
  /// Create new initiative with role requirements
  /// Validates: name uniqueness, positive effort values
  Future<Result<Initiative, ValidationException>> createInitiative({
    required String name,
    required String description,
    required Map<Role, double> effortByRole,
    DateTime? deadline,
  });
  
  /// Update initiative details
  /// Validates: no allocations exist if changing effort requirements
  Future<Result<Initiative, ValidationException>> updateInitiative(
    String initiativeId,
    InitiativeUpdateRequest request,
  );
  
  /// Delete initiative
  /// Validates: no active allocations exist
  Future<Result<void, ValidationException>> deleteInitiative(String initiativeId);
  
  /// Create capacity allocation
  /// Validates: member capacity, role compatibility, time conflicts
  Future<Result<CapacityAllocation, ValidationException>> createAllocation({
    required String teamMemberId,
    required String initiativeId,
    required Role role,
    required double effortWeeks,
    required int startWeek,
    required int endWeek,
  });
  
  /// Update allocation (drag-and-drop operations)
  /// Validates: new time slot availability, capacity constraints
  Future<Result<CapacityAllocation, ValidationException>> updateAllocation(
    String allocationId,
    AllocationUpdateRequest request,
  );
  
  /// Delete allocation
  Future<Result<void, ValidationException>> deleteAllocation(String allocationId);
  
  /// Calculate capacity utilization for given time period
  Future<CapacityUtilization> calculateUtilization({
    required int startWeek,
    required int endWeek,
    Role? filterByRole,
  });
  
  /// Detect allocation conflicts (overallocation)
  Future<List<AllocationConflict>> detectConflicts();
  
  /// Suggest optimal allocation for initiative
  Future<List<AllocationSuggestion>> suggestAllocation(String initiativeId);
}
```

### TeamManagementService

```dart
abstract class TeamManagementService {
  /// Add team member to current quarter
  /// Validates: name uniqueness, valid capacity range
  Future<Result<TeamMember, ValidationException>> addTeamMember({
    required String name,
    required Set<Role> roles,
    required double weeklyCapacity,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Update team member details
  /// Validates: no capacity reduction below current allocations
  Future<Result<TeamMember, ValidationException>> updateTeamMember(
    String memberId,
    TeamMemberUpdateRequest request,
  );
  
  /// Remove team member
  /// Validates: no active allocations exist
  Future<Result<void, ValidationException>> removeTeamMember(String memberId);
  
  /// Get team member availability for time period
  Future<MemberAvailability> getMemberAvailability(
    String memberId,
    int startWeek,
    int endWeek,
  );
  
  /// List team members by role
  Future<List<TeamMember>> getTeamMembersByRole(Role role);
}
```

## Data Transfer Objects

### Request Objects

```dart
class InitiativeUpdateRequest {
  final String? name;
  final String? description;
  final Map<Role, double>? effortByRole;
  final DateTime? deadline;
}

class AllocationUpdateRequest {
  final double? effortWeeks;
  final int? startWeek;
  final int? endWeek;
}

class TeamMemberUpdateRequest {
  final String? name;
  final Set<Role>? roles;
  final double? weeklyCapacity;
  final DateTime? endDate;
}
```

### Response Objects

```dart
class CapacityUtilization {
  final Map<Role, double> totalCapacityByRole;
  final Map<Role, double> allocatedCapacityByRole;
  final Map<Role, double> utilizationPercentageByRole;
  final Map<int, Map<Role, double>> weeklyUtilization;
}

class AllocationConflict {
  final String teamMemberId;
  final String teamMemberName;
  final Role role;
  final int weekNumber;
  final double allocatedCapacity;
  final double availableCapacity;
  final double overallocation;
  final List<String> conflictingAllocationIds;
}

class AllocationSuggestion {
  final String teamMemberId;
  final Role role;
  final int suggestedStartWeek;
  final int suggestedEndWeek;
  final double effortWeeks;
  final double confidenceScore;
  final String reasoning;
}

class MemberAvailability {
  final String memberId;
  final Map<int, double> availableCapacityByWeek; // Week -> available capacity
  final Map<int, List<CapacityAllocation>> existingAllocationsByWeek;
}

class QuarterPlanMetadata {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int teamMemberCount;
  final int initiativeCount;
  final DateTime lastModified;
}
```

## Exception Types

```dart
class StorageException implements Exception {
  final String message;
  final StorageErrorType type;
  final Exception? cause;
  
  const StorageException(this.message, this.type, [this.cause]);
}

enum StorageErrorType {
  notAvailable,      // Local storage not supported/disabled
  quotaExceeded,     // Storage quota limit reached
  dataCorrupted,     // Stored data is invalid/corrupted
  permissionDenied,  // Access denied to storage
  networkError,      // For potential future cloud sync
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>> fieldErrors;
  final ValidationErrorType type;
  
  const ValidationException(this.message, this.type, [this.fieldErrors = const {}]);
}

enum ValidationErrorType {
  capacityOverallocation,
  invalidTimeRange,
  duplicateName,
  missingRequiredField,
  businessRuleViolation,
  referentialIntegrityViolation,
}
```

## Local Storage Schema

### Storage Keys
```dart
class StorageKeys {
  static const String applicationState = 'capest_app_state';
  static const String userConfiguration = 'capest_user_config';
  static const String quarterPlanPrefix = 'capest_quarter_';
  static const String schemaVersion = 'capest_schema_version';
}
```

### Data Format
All data is stored as JSON strings in browser local storage:

```typescript
// Local Storage Structure
{
  "capest_app_state": "{...ApplicationState JSON...}",
  "capest_user_config": "{...UserConfiguration JSON...}",
  "capest_quarter_q4_2025": "{...QuarterPlan JSON...}",
  "capest_schema_version": "1"
}
```

## Error Handling Patterns

### Graceful Degradation
- If local storage is unavailable, operate in memory-only mode
- Notify user of persistence limitations
- Provide data export functionality for manual backup

### Data Recovery
- Validate stored data on load, provide migration if schema changed
- Corrupt data triggers reset with user confirmation
- Backup previous data before migration

### Offline Resilience
- All operations work without network connectivity
- State changes are immediately persisted locally
- Future: Could add cloud sync as optional enhancement

These contracts provide a complete interface for all application functionality while maintaining clean separation between storage, business logic, and UI layers.
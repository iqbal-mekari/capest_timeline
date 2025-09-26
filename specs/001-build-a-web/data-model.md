# Data Model: Capacity Estimation Application

**Date**: 2025-09-23  
**Scope**: Core entities and relationships for quarterly capacity planning

## Core Entities

### Initiative
Represents a development project requiring capacity allocation across multiple roles.

```dart
class Initiative {
  final String id;
  final String name;
  final String description;
  final Map<Role, double> effortByRole; // Role -> effort in weeks
  final DateTime createdAt;
  final DateTime? deadline;
  
  // Derived properties
  double get totalEffort => effortByRole.values.fold(0, (sum, effort) => sum + effort);
  List<Role> get requiredRoles => effortByRole.keys.toList();
}
```

**Validation Rules**:
- `name` must be non-empty and unique within quarter
- `effortByRole` must contain at least one role with positive effort
- `deadline` must be within the quarter planning period if specified
- Total effort cannot exceed team capacity * 13 weeks

### Team Member
Individual developer with role specialization and weekly availability.

```dart
class TeamMember {
  final String id;
  final String name;
  final Set<Role> roles; // Primary and secondary roles
  final double weeklyCapacity; // 0.0 to 1.0 (percentage of full-time)
  final DateTime startDate;
  final DateTime? endDate; // For temporary team members
  
  // Derived properties
  bool isAvailableInWeek(int weekNumber) => // Check date range
  double getCapacityForRole(Role role) => roles.contains(role) ? weeklyCapacity : 0.0;
}
```

**Validation Rules**:
- `name` must be non-empty and unique
- `roles` must contain at least one role
- `weeklyCapacity` must be between 0.1 and 1.0
- `endDate` must be after `startDate` if specified

### Capacity Allocation
Assignment of team member effort to specific initiative and time period.

```dart
class CapacityAllocation {
  final String id;
  final String teamMemberId;
  final String initiativeId;
  final Role role;
  final double effortWeeks; // Amount of effort allocated
  final int startWeek; // Week number in quarter (1-13)
  final int endWeek; // Inclusive end week
  final DateTime createdAt;
  
  // Derived properties
  int get durationWeeks => endWeek - startWeek + 1;
  double get weeklyEffort => effortWeeks / durationWeeks;
  List<int> get weekNumbers => List.generate(durationWeeks, (i) => startWeek + i);
}
```

**Validation Rules**:
- `effortWeeks` must be positive
- `startWeek` must be 1-13, `endWeek` must be 1-13
- `endWeek` must be >= `startWeek`
- `weeklyEffort` cannot exceed team member's capacity for that role
- Cannot double-allocate same member in overlapping weeks

### Quarter Plan
Container for all capacity planning within a specific quarter period.

```dart
class QuarterPlan {
  final String id;
  final String name; // e.g., "Q4 2025"
  final DateTime startDate;
  final DateTime endDate;
  final List<TeamMember> teamMembers;
  final List<Initiative> initiatives;
  final List<CapacityAllocation> allocations;
  final DateTime createdAt;
  final DateTime lastModified;
  
  // Derived analytics
  Map<Role, double> get totalCapacityByRole;
  Map<Role, double> get allocatedCapacityByRole;
  Map<Role, double> get utilizationByRole;
  Map<int, Map<Role, double>> get capacityByWeekAndRole;
}
```

**Validation Rules**:
- Quarter must span exactly 13 weeks
- All allocations must reference existing team members and initiatives
- No allocation can extend beyond quarter boundaries

### Role
Development specialization category defining skill requirements.

```dart
enum Role {
  backend('Backend', 'Server-side development and APIs'),
  frontend('Frontend', 'User interface and client-side logic'),
  mobile('Mobile', 'iOS and Android application development'),
  qa('QA', 'Quality assurance and testing'),
  devops('DevOps', 'Infrastructure and deployment automation'),
  design('Design', 'User experience and visual design');
  
  const Role(this.displayName, this.description);
  final String displayName;
  final String description;
}
```

### Application State
Complete snapshot of user's current work session.

```dart
class ApplicationState {
  final QuarterPlan? currentQuarter;
  final String? selectedInitiativeId;
  final String? selectedMemberId;
  final TimelineView timelineView;
  final Map<String, dynamic> uiState; // Scroll positions, expanded panels, etc.
  final DateTime lastSaved;
  
  // Serialization
  Map<String, dynamic> toJson();
  static ApplicationState fromJson(Map<String, dynamic> json);
}
```

### User Configuration
Application settings and preferences.

```dart
class UserConfiguration {
  final int timelineWeeks; // 6, 13, 26, 52
  final bool showWeekends;
  final bool enableAutoSave;
  final int autoSaveIntervalSeconds;
  final ThemeMode themeMode;
  final Map<String, dynamic> customSettings;
  
  // Defaults
  static const defaultConfig = UserConfiguration(
    timelineWeeks: 13,
    showWeekends: false,
    enableAutoSave: true,
    autoSaveIntervalSeconds: 30,
    themeMode: ThemeMode.system,
  );
}
```

## Relationships

### One-to-Many Relationships
- `QuarterPlan` → `TeamMember` (1:N)
- `QuarterPlan` → `Initiative` (1:N)
- `QuarterPlan` → `CapacityAllocation` (1:N)
- `Initiative` → `CapacityAllocation` (1:N)
- `TeamMember` → `CapacityAllocation` (1:N)

### Many-to-Many Relationships
- `TeamMember` ↔ `Role` (through roles Set)
- `Initiative` ↔ `Role` (through effortByRole Map)

## State Transitions

### Initiative Lifecycle
```
Created → In Planning → In Progress → Completed → Archived
```

**Transition Rules**:
- Can only delete if status is "Created" and no allocations exist
- Cannot modify effort requirements if allocations exist (must remove allocations first)
- Archived initiatives are read-only

### Allocation Lifecycle
```
Draft → Confirmed → In Progress → Completed
```

**Transition Rules**:
- Draft allocations can be freely modified
- Confirmed allocations require validation before changes
- Cannot delete allocations that are In Progress or Completed

## Data Integrity Constraints

### Capacity Constraints
- Sum of allocations for a team member in any week cannot exceed their weekly capacity
- Total effort allocated to an initiative cannot exceed the initiative's requirements
- Allocations cannot span beyond quarter boundaries

### Referential Integrity
- All allocation `teamMemberId` must reference existing team members
- All allocation `initiativeId` must reference existing initiatives
- Orphaned allocations are automatically cleaned up

### Business Rules
- Cannot allocate a team member to a role they don't possess
- Cannot create negative effort allocations
- Cannot have overlapping allocations for the same member and role

## Performance Considerations

### Indexing Strategy
- Team members indexed by role for filtering
- Allocations indexed by week number for timeline queries
- Initiatives indexed by status for filtering

### Computed Properties
- Cache utilization calculations to avoid repeated computation
- Lazy load allocation details for large datasets
- Batch updates for multiple allocation changes

## Migration Strategy

### Schema Versioning
```dart
class DataSchema {
  static const int currentVersion = 1;
  static const Map<int, String> migrationScripts = {
    1: 'Initial schema creation',
    // Future migrations will be added here
  };
}
```

### Backward Compatibility
- Support loading data from previous schema versions
- Automatic migration on app startup
- Fallback to default values for missing fields

This data model supports all functional requirements while maintaining data integrity and performance for the target scale of 50 team members and 100+ initiatives per quarter.
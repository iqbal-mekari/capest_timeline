# Initiative Management Contracts

## KanbanService

### getKanbanData()
**Purpose**: Load complete kanban board state including all initiatives, variants, and assignments
**Input**: None
**Output**: KanbanBoardState
```dart
class KanbanBoardState {
  final List<Initiative> initiatives;
  final Map<String, List<PlatformVariant>> variantsByInitiative;
  final Map<String, List<Assignment>> assignmentsByVariant;
  final List<TeamMember> teamMembers;
  final Map<String, CapacityPeriod> capacityByMemberWeek;
  final int totalWeeks;
  final DateTime projectStartDate;
}
```
**Error Cases**: 
- Storage unavailable: Returns empty state
- Corrupted data: Returns default state with error flag

### moveVariantToWeek(String variantId, int targetWeek)
**Purpose**: Drag-and-drop a platform variant to a different week
**Input**: 
- variantId: String - ID of variant to move
- targetWeek: int - Target week number (0-based)
**Output**: MoveResult
```dart
class MoveResult {
  final bool success;
  final List<String> overAllocatedMembers;
  final String? errorMessage;
  final KanbanBoardState updatedState;
}
```
**Error Cases**:
- Invalid variant ID: success=false, errorMessage set
- Invalid target week: success=false, errorMessage set
- Move causes over-allocation: success=true, overAllocatedMembers populated

### createInitiative(String name, double manWeeks, List<PlatformType> platforms)
**Purpose**: Create new initiative with automatic platform variant generation
**Input**:
- name: String - Initiative name
- manWeeks: double - Total effort estimate
- platforms: List<PlatformType> - Required platforms
**Output**: CreateInitiativeResult
```dart
class CreateInitiativeResult {
  final bool success;
  final String? initiativeId;
  final List<String> createdVariantIds;
  final String? errorMessage;
}
```
**Error Cases**:
- Empty name: success=false
- Invalid manWeeks: success=false
- Empty platforms list: success=false

### assignMemberToVariant(String variantId, String memberId, int weeks)
**Purpose**: Assign team member to platform variant for specified duration
**Input**:
- variantId: String - Target platform variant
- memberId: String - Team member to assign
- weeks: int - Duration of assignment
**Output**: AssignmentResult
```dart
class AssignmentResult {
  final bool success;
  final String? assignmentId;
  final bool causesOverAllocation;
  final String? errorMessage;
}
```
**Error Cases**:
- Invalid variant/member ID: success=false
- Member not specialized in platform: success=false
- Invalid week count: success=false

## CapacityService

### getCapacityUtilization(int weekNumber)
**Purpose**: Get capacity utilization for all team members in specific week
**Input**: weekNumber: int - Week to analyze (0-based)
**Output**: WeekCapacityState
```dart
class WeekCapacityState {
  final int weekNumber;
  final Map<String, MemberCapacity> memberCapacities;
  final List<String> overAllocatedMembers;
}

class MemberCapacity {
  final String memberId;
  final String memberName;
  final double totalCapacity;
  final double allocatedCapacity;
  final double availableCapacity;
  final bool isOverAllocated;
  final List<VariantAllocation> allocations;
}

class VariantAllocation {
  final String variantId;
  final String initiativeName;
  final PlatformType platform;
  final double allocatedCapacity;
}
```

### getOverAllocationWarnings()
**Purpose**: Get list of all current over-allocation warnings
**Input**: None
**Output**: List<OverAllocationWarning>
```dart
class OverAllocationWarning {
  final String memberId;
  final String memberName;
  final int weekNumber;
  final double excessCapacity;
  final List<String> conflictingVariantIds;
}
```

## StorageService

### saveKanbanState(KanbanBoardState state)
**Purpose**: Persist kanban board state to local storage
**Input**: state: KanbanBoardState - Complete board state
**Output**: bool - Success indicator
**Error Cases**: Storage unavailable, serialization failure

### loadKanbanState()
**Purpose**: Load kanban board state from local storage
**Input**: None
**Output**: KanbanBoardState? - Null if no saved state
**Error Cases**: Storage unavailable, deserialization failure

### exportData()
**Purpose**: Export all data as JSON for backup
**Input**: None
**Output**: String - JSON representation
**Error Cases**: Serialization failure

### importData(String jsonData)
**Purpose**: Import data from JSON backup
**Input**: jsonData: String - JSON to import
**Output**: ImportResult
```dart
class ImportResult {
  final bool success;
  final String? errorMessage;
  final int importedInitiatives;
  final int importedMembers;
}
```
**Error Cases**: Invalid JSON, schema validation failure
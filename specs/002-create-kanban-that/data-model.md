# Data Model: Initiative Mapping Kanban

## Core Entities

### Initiative
**Purpose**: Represents a work item that needs to be completed across one or more platforms
**Attributes**:
- `id`: String - Unique identifier for the initiative
- `name`: String - Display name (e.g., "Reimbursement")
- `manWeeks`: double - Total effort estimate in man-weeks
- `requiredPlatforms`: List<PlatformType> - Platforms needed for this initiative
- `createdAt`: DateTime - When initiative was created
- `updatedAt`: DateTime - Last modification time

**Validation Rules**:
- `name` must not be empty
- `manWeeks` must be positive
- `requiredPlatforms` must not be empty
- Each platform can appear only once per initiative

### PlatformVariant
**Purpose**: Represents a specific platform implementation of an initiative
**Attributes**:
- `id`: String - Unique identifier for the variant
- `initiativeId`: String - Reference to parent initiative
- `platformType`: PlatformType - BE, FE, Mobile, or QA
- `assignedMembers`: List<String> - Team member IDs assigned to this variant
- `scheduledStartWeek`: int - Week number when work begins (0-based from project start)
- `durationWeeks`: int - Number of weeks this variant spans
- `isDisabled`: bool - True if no team members assigned

**Validation Rules**:
- `initiativeId` must reference existing initiative
- `durationWeeks` must be positive integer
- `scheduledStartWeek` must be non-negative
- `assignedMembers` can be empty (creates disabled variant)

### TeamMember
**Purpose**: Represents an individual contributor with capacity and specialization
**Attributes**:
- `id`: String - Unique identifier
- `name`: String - Display name
- `platformSpecializations`: List<PlatformType> - Platforms this member can work on
- `weeklyCapacity`: double - Available work hours per week (default: 1.0 = full-time)
- `isActive`: bool - Whether member is currently available

**Validation Rules**:
- `name` must not be empty
- `weeklyCapacity` must be positive
- `platformSpecializations` must not be empty

### Assignment
**Purpose**: Links team members to platform variants with specific time allocation
**Attributes**:
- `id`: String - Unique identifier
- `platformVariantId`: String - Reference to platform variant
- `teamMemberId`: String - Reference to team member
- `allocatedWeeks`: int - Number of weeks this member works on the variant
- `startWeek`: int - When this member's work begins (relative to variant start)

**Validation Rules**:
- `platformVariantId` must reference existing platform variant
- `teamMemberId` must reference existing team member
- `allocatedWeeks` must be positive integer
- `startWeek` must be non-negative
- Team member must be specialized in the variant's platform type

### CapacityPeriod
**Purpose**: Tracks capacity utilization for team members across time periods
**Attributes**:
- `id`: String - Unique identifier
- `teamMemberId`: String - Reference to team member
- `weekNumber`: int - Week number (0-based from project start)
- `allocatedCapacity`: double - Total capacity allocated this week
- `isOverAllocated`: bool - True if allocated capacity exceeds member's weekly capacity

**Derived Properties**:
- `availableCapacity`: double - Remaining capacity (weeklyCapacity - allocatedCapacity)
- `utilizationPercentage`: double - Percentage of capacity used

## Entity Relationships

### Initiative → PlatformVariant (1:Many)
- One initiative creates multiple platform variants
- Variants are independent (no dependencies)
- Deleting initiative cascades to variants

### PlatformVariant → Assignment (1:Many)
- One variant can have multiple team member assignments
- Assignments define flexible work distribution
- Zero assignments create disabled variant

### TeamMember → Assignment (1:Many)
- One team member can be assigned to multiple variants
- Capacity tracking across all assignments
- Over-allocation warnings when total exceeds capacity

### TeamMember → CapacityPeriod (1:Many)
- One capacity period per team member per week
- Automatically calculated from assignments
- Updated when assignments change

## State Transitions

### Initiative Lifecycle
1. Created → Active (has platform variants with assignments)
2. Active → Disabled (all variants become disabled)
3. Active → Completed (manually marked as done)
4. Any state → Deleted

### PlatformVariant Lifecycle
1. Created → Disabled (no team members assigned)
2. Created → Scheduled (has team member assignments)
3. Scheduled → Disabled (all assignments removed)
4. Scheduled → In Progress (current week >= scheduled start week)
5. In Progress → Completed (current week > scheduled end week)

### Assignment Lifecycle
1. Created → Active (within variant's scheduled period)
2. Active → Completed (work period finished)
3. Any state → Removed (unassigned from variant)

## Calculation Logic

### Duration Calculation
```
For each PlatformVariant:
  totalEffort = initiative.manWeeks / initiative.requiredPlatforms.length
  totalAssignedCapacity = sum(assignment.allocatedWeeks for all assignments)
  
  if totalAssignedCapacity == 0:
    variant.isDisabled = true
    variant.durationWeeks = 0
  else:
    variant.durationWeeks = totalEffort (rounded to nearest integer)
    // Distribute work flexibly across assignments
```

### Capacity Utilization
```
For each TeamMember per week:
  allocatedCapacity = sum(assignment allocation for that week)
  availableCapacity = member.weeklyCapacity - allocatedCapacity
  isOverAllocated = allocatedCapacity > member.weeklyCapacity
```

## Data Persistence

### Local Storage Schema
```json
{
  "initiatives": Map<String, Initiative>,
  "platformVariants": Map<String, PlatformVariant>,
  "teamMembers": Map<String, TeamMember>,
  "assignments": Map<String, Assignment>,
  "projectSettings": {
    "startDate": "ISO-8601 date",
    "totalWeeks": "integer"
  }
}
```

### Storage Operations
- **Load**: Deserialize from SharedPreferences on app start
- **Save**: Serialize to SharedPreferences on any data change
- **Backup**: Export JSON for external backup
- **Import**: Validate and merge external data
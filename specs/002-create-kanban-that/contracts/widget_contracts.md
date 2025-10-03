# Widget Contracts

## KanbanBoardWidget

### Properties
```dart
class KanbanBoardWidget extends StatefulWidget {
  final KanbanBoardState initialState;
  final Function(String variantId, int targetWeek) onVariantMoved;
  final Function(String variantId) onVariantTapped;
  final int visibleWeeks; // Number of weeks to show initially
  final double cardWidth; // Width of each initiative card
}
```

### Methods
```dart
// Scroll to specific week
void scrollToWeek(int weekNumber)

// Highlight specific variants (for search/filter)
void highlightVariants(List<String> variantIds)

// Update board state without full rebuild
void updateState(KanbanBoardState newState)
```

### Events
- `onVariantMoved`: Triggered when user drags variant to new week
- `onVariantTapped`: Triggered when user taps variant card
- `onWeekScrolled`: Triggered when user scrolls timeline
- `onCapacityWarningTapped`: Triggered when user taps over-allocation warning

## InitiativeCardWidget

### Properties
```dart
class InitiativeCardWidget extends StatelessWidget {
  final PlatformVariant variant;
  final Initiative initiative;
  final List<TeamMember> assignedMembers;
  final bool isOverAllocated;
  final bool isDragging;
  final Function()? onTap;
}
```

### Visual States
- **Normal**: Default appearance with platform prefix
- **Disabled**: Grayed out with error icon (no assignments)
- **Over-allocated**: Warning color with exclamation icon
- **Dragging**: Elevated shadow with preview feedback
- **Drop Target**: Highlighted border when drag hovering

## WeekColumnWidget

### Properties
```dart
class WeekColumnWidget extends StatelessWidget {
  final int weekNumber;
  final DateTime weekStartDate;
  final List<PlatformVariant> variants;
  final bool isCurrentWeek;
  final Function(String variantId, int weekNumber) onVariantDropped;
  final double minHeight; // Minimum column height
}
```

### Drop Behavior
- Accept any PlatformVariant drag
- Show drop indicator during hover
- Validate drop legality (prevent invalid drops)
- Animate card placement after successful drop

## CapacityIndicatorWidget

### Properties
```dart
class CapacityIndicatorWidget extends StatelessWidget {
  final Map<String, MemberCapacity> memberCapacities;
  final bool showDetails; // Expand to show individual allocations
  final Function(String memberId) onMemberTapped;
}
```

### Visual Elements
- **Normal Capacity**: Green progress bar
- **High Utilization** (>80%): Yellow progress bar
- **Over-allocated**: Red progress bar with warning icon
- **Member List**: Expandable list of team members with allocation details

## CreateInitiativeWidget

### Properties
```dart
class CreateInitiativeWidget extends StatefulWidget {
  final List<TeamMember> availableMembers;
  final List<PlatformType> availablePlatforms;
  final Function(CreateInitiativeRequest) onCreateInitiative;
}

class CreateInitiativeRequest {
  final String name;
  final double manWeeks;
  final List<PlatformType> requiredPlatforms;
  final Map<PlatformType, List<String>> initialAssignments; // Optional
}
```

### Form Validation
- Name: Required, non-empty, unique
- Man-weeks: Required, positive number
- Platforms: At least one selected
- Initial assignments: Optional, must match selected platforms

## MemberAssignmentWidget

### Properties
```dart
class MemberAssignmentWidget extends StatefulWidget {
  final PlatformVariant variant;
  final List<TeamMember> eligibleMembers;
  final List<Assignment> currentAssignments;
  final Function(AssignmentRequest) onAssignmentChanged;
}

class AssignmentRequest {
  final String variantId;
  final Map<String, int> memberWeekAllocations; // memberId -> weeks
}
```

### Interaction Features
- **Member Selection**: Multi-select with platform filtering
- **Week Allocation**: Slider or input for each member
- **Capacity Preview**: Live preview of capacity impact
- **Validation**: Real-time feedback on over-allocation

## Responsive Behavior

### Mobile (< 768px)
- Single column layout with horizontal scrolling
- Swipe gestures for week navigation
- Simplified card layout with essential info only
- Bottom sheet for detailed capacity view

### Tablet (768px - 1024px)
- Multi-column layout with 4-6 visible weeks
- Drag-and-drop with touch feedback
- Side panel for capacity indicators
- Modal dialogs for create/edit operations

### Desktop (> 1024px)
- Full timeline view with 8-12 visible weeks
- Mouse drag-and-drop with hover states
- Right panel for detailed capacity analysis
- Inline editing capabilities
- Keyboard shortcuts for navigation
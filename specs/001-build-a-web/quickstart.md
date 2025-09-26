# Quickstart Guide: Capacity Estimation Application

**Date**: 2025-09-23  
**Purpose**: End-to-end validation of user workflow and system functionality

## Development Setup

### Prerequisites
- Flutter 3.13+ installed
- Chrome browser for web development
- Dart extension for VS Code (recommended)

### Initial Setup
```bash
# Clone and navigate to project
cd /Users/iqbal/projects/capest_timeline

# Get Flutter dependencies
flutter pub get

# Run tests to verify setup
flutter test

# Start development server
flutter run -d chrome
```

### Project Structure Verification
```
lib/
├── main.dart                    # Application entry point
├── core/                        # Clean architecture foundation
│   ├── errors/                  # Exception types and handling
│   ├── storage/                 # Local storage abstractions
│   └── utils/                   # Shared utilities
├── features/
│   ├── capacity_planning/       # Core business logic
│   │   ├── data/               # Repositories, data sources
│   │   ├── domain/             # Entities, use cases
│   │   └── presentation/       # UI, state management
│   ├── team_management/         # Team member operations
│   └── configuration/           # App settings and preferences
└── shared/
    ├── widgets/                 # Reusable UI components
    ├── themes/                  # Material Design theming
    └── constants/               # App-wide constants

test/
├── unit/                        # Business logic tests
├── widget/                      # UI component tests
└── integration/                 # End-to-end workflow tests
```

## User Workflow Validation

### Test Scenario 1: Create New Quarter Plan
**Objective**: Validate quarter plan creation and basic setup

1. **Launch Application**
   ```bash
   flutter run -d chrome
   ```
   - ✅ Application loads without errors
   - ✅ Material Design theme applied
   - ✅ Default 13-week timeline displayed

2. **Create Quarter Plan**
   - Click "New Quarter Plan" button
   - Enter name: "Q4 2025"
   - Set date range: Oct 1 - Dec 31, 2025
   - ✅ Plan created successfully
   - ✅ Empty timeline view displayed
   - ✅ State auto-saved to local storage

### Test Scenario 2: Add Team Members
**Objective**: Validate team member management functionality

1. **Add Backend Developer**
   - Click "Add Team Member"
   - Name: "Alice Johnson"
   - Roles: Backend
   - Weekly Capacity: 1.0 (100%)
   - ✅ Member added to team roster
   - ✅ Available in role filter dropdown

2. **Add Full-Stack Developer**
   - Name: "Bob Smith"
   - Roles: Backend, Frontend
   - Weekly Capacity: 0.8 (80% - part-time)
   - ✅ Member appears in both role categories
   - ✅ Capacity correctly calculated for allocations

3. **Add Mobile Developer**
   - Name: "Carol Chen"
   - Roles: Mobile, Frontend
   - Weekly Capacity: 1.0
   - ✅ Cross-functional capabilities visible

### Test Scenario 3: Create Initiative with Role Requirements
**Objective**: Validate initiative creation and effort breakdown

1. **Create E-commerce Platform Initiative**
   - Click "New Initiative"
   - Name: "E-commerce Platform v2"
   - Description: "Complete redesign with mobile app"
   - Role Requirements:
     - Backend: 8 weeks
     - Frontend: 6 weeks
     - Mobile: 4 weeks
     - QA: 3 weeks
   - ✅ Initiative created with effort breakdown
   - ✅ Total effort calculated: 21 weeks

### Test Scenario 4: Drag-and-Drop Capacity Allocation
**Objective**: Validate core kanban-style interaction and conflict detection

1. **Allocate Backend Work**
   - Drag "Alice Johnson" to "E-commerce Platform v2" Backend row
   - Assign to weeks 1-5 (5 weeks)
   - ✅ Visual allocation block appears
   - ✅ Initiative shows 3 weeks Backend remaining

2. **Split Remaining Backend Work**
   - Drag "Bob Smith" to same initiative Backend
   - Assign to weeks 6-8 (3 weeks)
   - ✅ Initiative Backend requirement fully allocated
   - ✅ Green indicator shows complete allocation

3. **Create Overallocation Conflict**
   - Try to assign Alice to another initiative in week 3
   - ✅ Red conflict indicator appears
   - ✅ Tooltip explains overallocation details
   - ✅ Suggestion to move allocation to available weeks

4. **Resolve Conflict**
   - Drag conflicting allocation to week 9
   - ✅ Conflict indicators disappear
   - ✅ All allocations valid

### Test Scenario 5: Timeline View Adjustments
**Objective**: Validate adjustable timeline functionality

1. **Change Timeline Span**
   - Current view: 13 weeks (default)
   - Change to 26 weeks
   - ✅ Timeline expands to show longer horizon
   - ✅ Existing allocations remain visible
   - ✅ Scroll behavior works correctly

2. **Test Responsive Design**
   - Resize browser window
   - ✅ Timeline columns adjust appropriately
   - ✅ Drag-and-drop still functional
   - ✅ Mobile-responsive layout on narrow screens

### Test Scenario 6: Data Persistence and Recovery
**Objective**: Validate auto-save and state restoration

1. **Make Changes and Close**
   - Create several allocations
   - Wait 30 seconds for auto-save
   - Close browser tab
   - ✅ No unsaved changes warning needed

2. **Restore Session**
   - Reopen application
   - ✅ Previous work session restored
   - ✅ All allocations and initiatives present
   - ✅ Timeline view settings preserved

3. **Test Reset Functionality**
   - Click "Reset All Data" button
   - Confirm reset action
   - ✅ All data cleared
   - ✅ Application returns to initial state
   - ✅ Fresh start possible

### Test Scenario 7: Performance Validation
**Objective**: Ensure constitutional performance requirements

1. **Load Large Dataset**
   - Create 50 team members
   - Create 25 initiatives
   - Create 200+ allocations
   - ✅ UI remains responsive
   - ✅ Drag operations < 200ms
   - ✅ Save operations < 2s

2. **Stress Test Interactions**
   - Rapid drag-and-drop operations
   - Timeline scrolling with large dataset
   - Multiple conflict detection scenarios
   - ✅ No UI freezing or lag
   - ✅ Smooth animations maintained

## Acceptance Criteria Verification

### ✅ Functional Requirements Checklist
- [x] FR-001: Create quarterly capacity planning periods
- [x] FR-002: Define initiatives with role-specific effort estimates
- [x] FR-003: Support Backend, Frontend, Mobile, QA roles
- [x] FR-004: Break down initiative effort by role
- [x] FR-005: Split role effort among multiple team members
- [x] FR-006: Kanban-style weekly timeline with drag-and-drop
- [x] FR-007: Drag team member capacity between weeks
- [x] FR-008: Visual capacity conflict indicators
- [x] FR-009: Display allocated vs. available capacity
- [x] FR-010: Persist and modify capacity planning data
- [x] FR-011: Calculate capacity utilization percentages
- [x] FR-012: Add, edit, remove team members
- [x] FR-013: Support fractional week allocations
- [x] FR-014: Adjustable timeline views (default 13 weeks)
- [x] FR-015: Variable timeline spans (6, 13, 26 weeks)
- [x] FR-016: Single-user operation with local storage
- [x] FR-017: Automatic state saving
- [x] FR-018: State restoration on startup
- [x] FR-019: Reset functionality

### ✅ Constitutional Requirements Checklist
- [x] Code Quality: Clean architecture, typed interfaces, documented code
- [x] Test-First Development: 90%+ test coverage, TDD approach
- [x] UX Consistency: Material Design, accessibility, responsive layout
- [x] Performance Excellence: <200ms interactions, <2s data operations
- [x] Observability: Structured logging, error tracking, performance monitoring

## Integration Test Automation

### Automated Test Suite
```dart
// integration_test/app_test.dart
void main() {
  group('Capacity Planning E2E Tests', () {
    testWidgets('Complete user workflow', (tester) async {
      // Test all scenarios above programmatically
      await tester.pumpWidget(MyApp());
      
      // Scenario 1: Create quarter plan
      await createQuarterPlan(tester, 'Q4 2025');
      
      // Scenario 2: Add team members
      await addTeamMember(tester, 'Alice', [Role.backend], 1.0);
      
      // Scenario 3: Create initiative
      await createInitiative(tester, 'E-commerce v2', {
        Role.backend: 8,
        Role.frontend: 6,
      });
      
      // Scenario 4: Drag and drop allocation
      await dragAndDropAllocation(tester, 'Alice', 'E-commerce v2', 1, 5);
      
      // Scenario 5: Verify state persistence
      await verifyAutoSave(tester);
      
      // Scenario 6: Performance validation
      await validatePerformance(tester);
    });
  });
}
```

### Test Execution
```bash
# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Performance profiling
flutter run --profile -d chrome
```

## Deployment Validation

### Production Build
```bash
# Build for production
flutter build web --release

# Serve locally for testing
cd build/web
python3 -m http.server 8000

# Open http://localhost:8000
# ✅ Production build loads correctly
# ✅ Local storage functionality preserved
# ✅ Performance optimizations applied
```

### Browser Compatibility Testing
- ✅ Chrome 100+ (primary target)
- ✅ Firefox 90+ (secondary)
- ✅ Safari 14+ (secondary)
- ✅ Edge 100+ (secondary)

This quickstart guide validates all critical functionality and ensures the application meets both functional requirements and constitutional principles.
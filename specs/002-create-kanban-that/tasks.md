# Tasks: Initiative Mapping Kanban Board

**Input**: Design documents from `/specs/002-create-kanban-that/`
**Prerequisites**: plan.md (✓), research.md (✓), data-model.md (✓), contracts/ (✓)

## Execution Flow (main)
```
1. Load plan.md from feature directory ✓
   → Extract: Dart/Flutter 3.13+ (web target), provider, shared_preferences, equatable
2. Load design documents ✓:
   → data-model.md: 5 entities (Initiative, PlatformVariant, TeamMember, Assignment, CapacityPeriod)
   → contracts/: service_contracts.md, widget_contracts.md
   → quickstart.md: 7 test scenarios
3. Generate tasks by category ✓:
   → Setup: Flutter project init, dependencies, linting
   → Tests: Model tests, service tests, widget tests, integration tests
   → Core: Models, services, widgets
   → Integration: Provider state management, SharedPreferences
   → Polish: Performance, responsive design, documentation
4. Apply task rules ✓:
   → Different files = mark [P] for parallel
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...) ✓
6. Generate dependency graph ✓
7. Create parallel execution examples ✓
8. Validate task completeness ✓
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
Flutter web application (single project structure):
- **Models**: `lib/models/`
- **Services**: `lib/services/`
- **Widgets**: `lib/widgets/`
- **Screens**: `lib/screens/`
- **Tests**: `test/unit/`, `test/widget/`, `test/integration/`

## Phase 3.1: Setup
- [x] T001 Initialize Flutter web project structure with Provider and SharedPreferences dependencies
- [x] T002 Configure analysis_options.yaml and dart formatting rules
- [x] T003 [P] Set up test directory structure (unit/, widget/, integration/)

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Model Tests
- [x] T004 [P] Unit test Initiative model in test/unit/models/initiative_test.dart
- [x] T005 [P] Unit test PlatformVariant model in test/unit/models/platform_variant_test.dart
- [x] T006 [P] Unit test TeamMember model in test/unit/models/team_member_test.dart
- [x] T007 [P] Unit test Assignment model in test/unit/models/assignment_test.dart
- [x] T008 [P] Unit test CapacityPeriod model in test/unit/models/capacity_period_test.dart

### Service Contract Tests
- [x] T009 [P] Contract test KanbanService.getKanbanData() in test/unit/services/kanban_service_test.dart
- [x] T010 [P] Contract test KanbanService.moveVariantToWeek() in test/unit/services/kanban_service_test.dart
- [x] T011 [P] Contract test KanbanService.createInitiative() in test/unit/services/kanban_service_test.dart
- [x] T012 [P] Contract test CapacityService.getCapacityUtilization() in test/unit/services/capacity_service_test.dart
- [x] T013 [P] Contract test StorageService.saveKanbanState() in test/unit/services/storage_service_test.dart

### Widget Tests
- [x] T014 [P] Widget test KanbanBoardWidget drag-and-drop in test/widget/kanban_board_widget_test.dart
- [x] T015 [P] Widget test InitiativeCardWidget states in test/widget/initiative_card_widget_test.dart
- [x] T016 [P] Widget test WeekColumnWidget drop behavior in test/widget/week_column_widget_test.dart
- [x] T017 [P] Widget test CapacityIndicatorWidget warnings in test/widget/capacity_indicator_widget_test.dart
- [x] T018 [P] Widget test CreateInitiativeWidget form validation in test/widget/create_initiative_widget_test.dart

### Integration Tests (from Quickstart scenarios)
- [x] T019 [P] Integration test basic duration calculation in test/integration/duration_calculation_test.dart
- [x] T020 [P] Integration test multi-member duration reduction in test/integration/multi_member_test.dart
- [x] T021 [P] Integration test platform variant independence in test/integration/variant_independence_test.dart
- [x] T022 [P] Integration test drag-and-drop rescheduling in test/integration/drag_drop_test.dart
- [x] T023 [P] Integration test zero assignment handling in test/integration/zero_assignment_test.dart
- [x] T024 [P] Integration test capacity utilization visibility in test/integration/capacity_visibility_test.dart
- [x] T025 [P] Integration test fractional work distribution in test/integration/fractional_work_test.dart

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Data Models
- [x] T026 [P] Initiative model with Equatable in lib/models/initiative.dart
- [x] T027 [P] PlatformVariant model with validation in lib/models/platform_variant.dart
- [x] T028 [P] TeamMember model with specializations in lib/models/team_member.dart
- [x] T029 [P] Assignment model with relationships in lib/models/assignment.dart
- [x] T030 [P] CapacityPeriod model with calculations in lib/models/capacity_period.dart
- [x] T031 [P] PlatformType enum in lib/models/platform_type.dart

### Service Implementations
- [x] T032 KanbanService implementation in lib/services/kanban_service.dart
- [x] T033 CapacityService with utilization logic in lib/services/capacity_service.dart
- [x] T034 StorageService with SharedPreferences in lib/services/storage_service.dart
- [x] T035 CalculationService for duration logic in lib/services/calculation_service.dart

### State Management
- [x] T036 KanbanProvider with ChangeNotifier in lib/providers/kanban_provider.dart
- [x] T037 CapacityProvider for utilization state in lib/providers/capacity_provider.dart

## Phase 3.4: Widget Implementation (ONLY after service tests pass)

### Core Widgets
- [x] T038 KanbanBoardWidget with Draggable/DragTarget in lib/widgets/kanban_board_widget.dart
- [x] T039 InitiativeCardWidget with platform prefixes in lib/widgets/initiative_card_widget.dart
- [x] T040 WeekColumnWidget with drop zones in lib/widgets/week_column_widget.dart
- [x] T041 CapacityIndicatorWidget with warnings in lib/widgets/capacity_indicator_widget.dart
- [x] T042 CreateInitiativeWidget with form validation in lib/widgets/create_initiative_widget.dart
- [x] T043 MemberAssignmentWidget with capacity preview in lib/widgets/member_assignment_widget.dart

### Screen Integration
- [x] T044 Main Kanban screen with Provider integration in lib/screens/kanban_screen.dart
- [x] T045 Initiative creation screen in lib/screens/create_initiative_screen.dart

## Phase 3.5: Integration & Polish

### Provider Integration
- [x] T046 Connect KanbanBoardWidget to KanbanProvider
- [x] T047 Connect CapacityIndicatorWidget to CapacityProvider
- [x] T048 Implement drag-and-drop state updates

### Performance & Responsive Design
- [x] T049 [P] Optimize capacity calculation performance (<2s requirement)
- [x] T050 [P] Implement responsive layout for mobile/tablet/desktop
- [x] T051 [P] Add drag-and-drop animation and feedback (60fps target)
- [x] T052 [P] Implement horizontal scrolling for timeline

### Error Handling & Polish
- [x] T053 [P] Add over-allocation visual indicators and warnings
- [x] T054 [P] Implement disabled card states for zero assignments
- [x] T055 [P] Add error boundaries and loading states
- [x] T056 [P] Implement data persistence and recovery

### Documentation & Validation
- [x] T057 [P] Update README with kanban board feature documentation
- [x] T058 Run manual testing using quickstart.md scenarios
- [x] T059 Performance validation (drag operations <200ms)
- [x] T060 Accessibility testing with screen readers

## Dependencies
- **Setup** (T001-T003) before everything
- **All Tests** (T004-T025) before implementation (T026+) - TDD requirement
- **Models** (T026-T031) before services (T032-T035)  
- **Services** (T032-T035) before providers (T036-T037)
- **Providers** (T036-T037) before widgets (T038-T043)
- **Widgets** (T038-T043) before screens (T044-T045)
- **Core** (T026-T045) before integration (T046-T048)
- **Everything** before polish (T049-T060)

## Parallel Execution Examples

### Phase 3.2 - All Model Tests (can run simultaneously)
```
Task: "Unit test Initiative model in test/unit/models/initiative_test.dart"
Task: "Unit test PlatformVariant model in test/unit/models/platform_variant_test.dart"  
Task: "Unit test TeamMember model in test/unit/models/team_member_test.dart"
Task: "Unit test Assignment model in test/unit/models/assignment_test.dart"
Task: "Unit test CapacityPeriod model in test/unit/models/capacity_period_test.dart"
```

### Phase 3.3 - All Model Implementations (can run simultaneously)
```
Task: "Initiative model with Equatable in lib/models/initiative.dart"
Task: "PlatformVariant model with validation in lib/models/platform_variant.dart"
Task: "TeamMember model with specializations in lib/models/team_member.dart"
Task: "Assignment model with relationships in lib/models/assignment.dart"
Task: "CapacityPeriod model with calculations in lib/models/capacity_period.dart"
```

### Phase 3.4 - All Widget Tests (can run simultaneously)
```
Task: "Widget test KanbanBoardWidget drag-and-drop in test/widget/kanban_board_widget_test.dart"
Task: "Widget test InitiativeCardWidget states in test/widget/initiative_card_widget_test.dart"
Task: "Widget test WeekColumnWidget drop behavior in test/widget/week_column_widget_test.dart"
Task: "Widget test CapacityIndicatorWidget warnings in test/widget/capacity_indicator_widget_test.dart"
```

## Notes
- **[P] tasks**: Different files, no dependencies - can run in parallel
- **TDD Critical**: All tests MUST fail before implementing corresponding code
- **Flutter-specific**: Use flutter_test, mockito, Provider pattern, Material Design
- **Performance**: Target <200ms interactive, <2s calculations, 60fps animations
- **Storage**: SharedPreferences for web browser local storage
- **Accessibility**: Screen reader support, keyboard navigation

## Task Generation Rules Applied
✓ **From Data Model**: 5 entities → 5 model tasks + 5 test tasks [P]
✓ **From Service Contracts**: 3 services → 6 contract tests + 4 implementations
✓ **From Widget Contracts**: 6 widgets → 6 widget tests + 6 implementations [P]  
✓ **From Quickstart**: 7 scenarios → 7 integration tests [P]
✓ **Ordering**: Setup → Tests → Models → Services → Widgets → Integration → Polish
✓ **Dependencies**: Tests block implementations, models block services, etc.

## Validation Checklist
✓ All contracts have corresponding tests (T009-T013, T014-T018)
✓ All entities have model tasks (T026-T031)
✓ All tests come before implementation (Phase 3.2 before 3.3+)
✓ Parallel tasks truly independent (different files, no shared state)
✓ Each task specifies exact file path
✓ No task modifies same file as another [P] task
✓ TDD ordering enforced (tests must fail before implementation)
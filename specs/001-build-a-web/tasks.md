# Tasks: Capacity Estimation Web Application

**Input**: Design documents from `/specs/001-build-a-web/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory ✅
   → Tech stack: Flutter 3.13+ web, Provider, shared_preferences
   → Structure: Single project with clean architecture
2. Load design documents ✅:
   → data-model.md: 7 entities (Initiative, TeamMember, CapacityAllocation, etc.)
   → contracts/: 4 service contracts with storage and business logic
   → research.md: Flutter web decisions and architecture patterns
3. Generate tasks by category ✅:
   → Setup: Flutter project, dependencies, folder structure
   → Tests: Contract tests, widget tests, integration tests
   → Core: Models, services, repositories, use cases
   → Integration: State management, UI components, persistence
   → Polish: Performance, accessibility, documentation
4. Apply task rules ✅:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...) ✅
6. Generate dependency graph ✅
7. Create parallel execution examples ✅
8. Validate task completeness ✅:
   → All contracts have tests ✅
   → All entities have models ✅
   → All user stories have integration tests ✅
9. Return: SUCCESS (48 tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
**Single Flutter Project Structure** (per plan.md):
```
lib/
├── main.dart
├── core/
├── features/
│   ├── capacity_planning/
│   ├── team_management/
│   └── configuration/
└── shared/

test/
├── unit/
├── widget/
└── integration/
```

## Phase 3.1: Setup
- [x] T001 Create Flutter project structure with clean architecture folders
- [x] T002 Initialize Flutter web project with dependencies (provider, shared_preferences)
- [x] T003 [P] Configure analysis_options.yaml for linting and formatting
- [x] T004 [P] Set up basic Material Design theme in lib/shared/themes/app_theme.dart
- [x] T005 [P] Create core error types in lib/core/errors/exceptions.dart

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**

### Storage Contract Tests
- [x] T006 [P] Contract test QuarterPlanStorageService in test/unit/storage/quarter_plan_storage_service_test.dart
- [x] T007 [P] Contract test ApplicationStateService in test/unit/storage/application_state_service_test.dart
- [x] T008 [P] Contract test ConfigurationService in test/unit/storage/configuration_service_test.dart

### Business Logic Contract Tests
- [x] T009 [P] Contract test CapacityPlanningService in test/unit/services/capacity_planning_service_test.dart
- [x] T010 [P] Contract test TeamManagementService in test/unit/services/team_management_service_test.dart

### Entity Tests
- [x] T011 [P] Unit test Initiative entity in test/unit/entities/initiative_test.dart
- [x] T012 [P] Unit test TeamMember entity in test/unit/entities/team_member_test.dart
- [x] T013 [P] Unit test CapacityAllocation entity in test/unit/entities/capacity_allocation_test.dart
- [x] T014 [P] Unit test QuarterPlan entity in test/unit/entities/quarter_plan_test.dart
- [x] T015 [P] Unit test ApplicationState entity in test/unit/entities/application_state_test.dart

### Integration Tests
- [ ] T016 [P] Integration test quarter plan creation in test/integration/quarter_plan_creation_test.dart
- [ ] T017 [P] Integration test team member management in test/integration/team_member_management_test.dart
- [ ] T018 [P] Integration test capacity allocation workflow in test/integration/capacity_allocation_test.dart
- [ ] T019 [P] Integration test drag-and-drop operations in test/integration/drag_drop_test.dart
- [ ] T020 [P] Integration test state persistence in test/integration/state_persistence_test.dart

## Phase 3.3: Core Implementation (ONLY after tests are failing)

### Core Entities and Enums
- [x] T021 [P] Role enum in lib/core/enums/role.dart
- [x] T022 [P] Initiative entity in lib/features/capacity_planning/domain/entities/initiative.dart
- [x] T023 [P] TeamMember entity in lib/features/team_management/domain/entities/team_member.dart
- [x] T024 [P] CapacityAllocation entity in lib/features/capacity_planning/domain/entities/capacity_allocation.dart
- [x] T025 [P] QuarterPlan entity in lib/features/capacity_planning/domain/entities/quarter_plan.dart
- [x] T026 [P] ApplicationState entity in lib/features/configuration/domain/entities/application_state.dart
- [x] T027 [P] UserConfiguration entity in lib/features/configuration/domain/entities/user_configuration.dart

### Result and Exception Types
- [x] T028 [P] Result type for error handling in lib/core/types/result.dart
- [x] T029 [P] StorageException and ValidationException in lib/core/errors/exceptions.dart

### Repository Interfaces
- [x] T030 [P] QuarterPlanRepository interface in lib/features/capacity_planning/domain/repositories/quarter_plan_repository.dart
- [x] T031 [P] ApplicationStateRepository interface in lib/features/configuration/domain/repositories/application_state_repository.dart
- [x] T032 [P] ConfigurationRepository interface in lib/features/configuration/domain/repositories/configuration_repository.dart

### Use Cases
- [x] T033 [P] CreateInitiative use case in lib/features/capacity_planning/domain/usecases/create_initiative.dart
- [x] T034 [P] AddTeamMember use case in lib/features/team_management/domain/usecases/add_team_member.dart
- [x] T035 [P] CreateAllocation use case in lib/features/capacity_planning/domain/usecases/create_allocation.dart
- [x] T036 [P] CalculateUtilization use case in lib/features/capacity_planning/domain/usecases/calculate_utilization.dart
- [x] T037 [P] DetectConflicts use case in lib/features/capacity_planning/domain/usecases/detect_conflicts.dart

## Phase 3.4: Data Layer Implementation
- [x] T038 [P] Local storage data source in lib/features/configuration/data/datasources/local_storage_data_source.dart
- [x] T039 [P] QuarterPlan repository implementation in lib/features/capacity_planning/data/repositories/quarter_plan_repository_impl.dart
- [x] T040 [P] ApplicationState repository implementation in lib/features/configuration/data/repositories/application_state_repository_impl.dart
- [x] T041 [P] Configuration repository implementation in lib/features/configuration/data/repositories/configuration_repository_impl.dart

## Phase 3.5: State Management and Presentation
- [ ] T042 CapacityPlanningProvider in lib/features/capacity_planning/presentation/providers/capacity_planning_provider.dart
- [ ] T043 TeamManagementProvider in lib/features/team_management/presentation/providers/team_management_provider.dart
- [ ] T044 ConfigurationProvider in lib/features/configuration/presentation/providers/configuration_provider.dart

## Phase 3.6: UI Components and Screens
- [x] T045 [P] TimelineWidget in lib/features/capacity_planning/presentation/widgets/timeline_widget.dart
- [x] T046 [P] DragDropAllocationWidget in lib/features/capacity_planning/presentation/widgets/drag_drop_allocation_widget.dart
- [ ] T047 [P] TeamMemberCard in lib/features/team_management/presentation/widgets/team_member_card.dart
- [ ] T048 [P] InitiativeCard in lib/features/capacity_planning/presentation/widgets/initiative_card.dart
- [ ] T049 MainScreen with navigation in lib/features/capacity_planning/presentation/screens/main_screen.dart

## Phase 3.7: Integration and Wiring
- [x] T050 Dependency injection setup in lib/core/di/service_locator.dart
- [x] T051 Provider setup in main.dart
- [ ] T052 Auto-save timer implementation in lib/features/configuration/presentation/providers/auto_save_provider.dart

## Phase 3.8: Polish and Validation
- [x] T053 [P] Performance optimization for large datasets in lib/features/capacity_planning/presentation/widgets/virtualized_timeline.dart
- [ ] T054 [P] Accessibility improvements and semantic labels
- [ ] T055 [P] Error boundary widget in lib/shared/widgets/error_boundary.dart
- [ ] T056 [P] Loading states and progress indicators
- [ ] T057 Manual testing execution following quickstart.md scenarios
- [ ] T058 Performance benchmarking for <200ms drag operations

## Dependencies

### Setup Dependencies
- T001 → T002 → T003-T005 (project structure before code)

### Test Dependencies  
- T003-T005 → T006-T020 (setup before tests)

### Implementation Dependencies
- T006-T020 (all tests) → T021-T058 (implementation)
- T021 → T022-T027 (enum before entities using it)
- T028-T029 → T030-T032 (types before interfaces)
- T022-T027 → T030-T032 (entities before repositories)
- T030-T032 → T033-T037 (repositories before use cases)
- T033-T037 → T038-T041 (use cases before implementations)
- T038-T041 → T042-T044 (data layer before providers)
- T042-T044 → T045-T049 (providers before UI)
- T045-T049 → T050-T052 (UI before integration)
- T050-T052 → T053-T058 (integration before polish)

### Parallel Execution Blocks
```
Block 1 (Setup): T003, T004, T005
Block 2 (Contract Tests): T006, T007, T008, T009, T010  
Block 3 (Entity Tests): T011, T012, T013, T014, T015
Block 4 (Integration Tests): T016, T017, T018, T019, T020
Block 5 (Entities): T021, T022, T023, T024, T025, T026, T027
Block 6 (Core Types): T028, T029
Block 7 (Repositories): T030, T031, T032
Block 8 (Use Cases): T033, T034, T035, T036, T037
Block 9 (Data Layer): T038, T039, T040, T041
Block 10 (UI Components): T045, T046, T047, T048
Block 11 (Polish): T053, T054, T055, T056
```

## Parallel Example
```bash
# Block 3: Entity Tests (can run simultaneously)
Task: "Unit test Initiative entity in test/unit/entities/initiative_test.dart"
Task: "Unit test TeamMember entity in test/unit/entities/team_member_test.dart"  
Task: "Unit test CapacityAllocation entity in test/unit/entities/capacity_allocation_test.dart"
Task: "Unit test QuarterPlan entity in test/unit/entities/quarter_plan_test.dart"
Task: "Unit test ApplicationState entity in test/unit/entities/application_state_test.dart"

# Block 5: Entity Implementation (can run simultaneously after tests pass)
Task: "Initiative entity in lib/features/capacity_planning/domain/entities/initiative.dart"
Task: "TeamMember entity in lib/features/team_management/domain/entities/team_member.dart"
Task: "CapacityAllocation entity in lib/features/capacity_planning/domain/entities/capacity_allocation.dart"
Task: "QuarterPlan entity in lib/features/capacity_planning/domain/entities/quarter_plan.dart"
Task: "ApplicationState entity in lib/features/configuration/domain/entities/application_state.dart"
```

## Notes
- [P] tasks = different files, no dependencies within block
- Verify all tests fail before implementing (TDD requirement)
- Each task creates/modifies only one file to avoid conflicts
- Commit after each task completion
- 90%+ test coverage target per constitutional requirement

## Task Generation Rules Applied

1. **From Contracts**: 
   - QuarterPlanStorageService → T006 contract test
   - ApplicationStateService → T007 contract test  
   - ConfigurationService → T008 contract test
   - CapacityPlanningService → T009 contract test
   - TeamManagementService → T010 contract test

2. **From Data Model**:
   - 7 entities → T011-T015 tests + T022-T027 implementations
   - Relationships → T033-T037 use cases, T038-T041 repositories

3. **From Quickstart Scenarios**:
   - Quarter plan creation → T016 integration test
   - Team member management → T017 integration test
   - Capacity allocation → T018 integration test
   - Drag-and-drop → T019 integration test  
   - State persistence → T020 integration test

4. **Ordering Applied**:
   - Setup (T001-T005) → Tests (T006-T020) → Implementation (T021-T058)
   - Dependencies respected: entities before services, data before UI

## Validation Checklist
*GATE: Checked before execution*

- [x] All contracts have corresponding tests (T006-T010)
- [x] All entities have model tasks (T011-T015 tests, T022-T027 implementation)  
- [x] All tests come before implementation (Phase 3.2 before 3.3+)
- [x] Parallel tasks truly independent (different files)
- [x] Each task specifies exact file path
- [x] No task modifies same file as another [P] task
- [x] TDD workflow enforced (tests must fail before implementation)
- [x] Constitutional requirements addressed (90% coverage, clean architecture)

**Total Tasks**: 58 ordered tasks ready for execution
**Estimated Completion**: 2-3 weeks with parallel execution
**Critical Path**: Setup → Entity Tests → Entity Implementation → Integration
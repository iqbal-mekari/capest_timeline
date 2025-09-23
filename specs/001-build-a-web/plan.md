
# Implementation Plan: Capacity Estimation Web Application

**Branch**: `001-build-a-web` | **Date**: 2025-09-23 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-build-a-web/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
A quarterly capacity estimation web application that enables project managers to visualize and plan development team allocation across weekly timelines. Features a kanban-style drag-and-drop interface for assigning initiative requirements (Backend, Frontend, Mobile, QA roles) to team members with capacity conflict detection and automatic state persistence to local storage.

## Technical Context
**Language/Version**: Dart/Flutter 3.13+ (web target)  
**Primary Dependencies**: flutter_web, provider (state management), shared_preferences (local storage), minimal 3rd party packages as specified  
**Storage**: Browser local storage for single-user state persistence  
**Testing**: flutter_test with target 90%+ code coverage using Test-Driven Development  
**Target Platform**: Web browsers (responsive design)  
**Project Type**: web - Single-page application with clean architecture  
**Performance Goals**: <200ms for interactive operations (drag/drop), <2s for data operations (save/load)  
**Constraints**: Minimal 3rd party dependencies, assets referenced within repo, offline-capable with local storage  
**Scale/Scope**: Single-user application, up to 50 team members, 100+ initiatives per quarter, 13-52 week timeline views

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality Standards**: ✅ Flutter/Dart enforces strong typing and linting. Clean architecture with clear separation of concerns (presentation/domain/data layers). Provider pattern provides testable dependency injection. Code documentation required for complex business logic.

**Test-First Development**: ✅ TDD approach planned with 90%+ coverage target. Widget tests for UI components, unit tests for business logic, integration tests for user workflows. Flutter's testing framework supports comprehensive test strategies.

**UX Consistency**: ✅ Material Design provides consistent UI patterns. Responsive design for various screen sizes. Accessibility support through Flutter's semantics. User feedback states for loading/success/error. Drag-and-drop interactions follow platform conventions.

**Performance Excellence**: ✅ <200ms target for interactive operations (drag/drop, navigation). <2s for data operations (save/load). Local storage eliminates network latency. Flutter web optimizations for bundle size and rendering performance.

**Observability**: ✅ Structured logging for debugging user actions and data operations. Error tracking for local storage failures and data corruption. Performance monitoring for drag/drop operations and large dataset rendering. Analytics for capacity planning usage patterns.

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: Option 1 (Single project) - Flutter web application with clean architecture layers

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh copilot`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base structure
- Generate tasks from Phase 1 design artifacts following TDD principles
- Extract from data-model.md: Entity creation tasks, validation logic tasks
- Extract from api-contracts.md: Service interface tasks, storage implementation tasks
- Extract from quickstart.md: Integration test scenario tasks
- Each contract service → interface definition task [P] + implementation task
- Each entity → model class task [P] + unit test task [P]
- Each user story → integration test task + UI implementation task
- Configuration setup tasks for Flutter web, Provider, local storage

**Ordering Strategy**:
- **TDD Order**: Test tasks before implementation tasks for each component
- **Dependency Order**: 
  1. Core entities and validation (models, exceptions)
  2. Storage abstractions and services (repositories, local storage)
  3. Business logic and use cases (capacity planning, team management)
  4. UI state management (Provider setup, view models)
  5. UI components and screens (widgets, responsive layout)
  6. Integration and E2E tests (user workflow validation)
- **Parallel Execution**: Mark [P] for independent tasks (separate files/classes)
- **Critical Path**: Drag-and-drop functionality depends on data model + UI components

**Estimated Task Breakdown**:
- **Phase Setup** (3 tasks): Flutter project initialization, dependencies, folder structure
- **Core Foundation** (8 tasks): Entities, validation, exceptions, utilities [P]
- **Storage Layer** (6 tasks): Local storage service, repositories, error handling [P]
- **Business Logic** (10 tasks): Use cases, capacity calculations, conflict detection [P]
- **State Management** (5 tasks): Provider setup, view models, state persistence
- **UI Components** (12 tasks): Timeline, drag-drop, forms, responsive layout [P]
- **Integration** (4 tasks): E2E tests, performance validation, accessibility testing
- **Total Estimated**: 48 numbered, ordered tasks with dependencies clearly marked

**Testing Strategy Integration**:
- Every implementation task preceded by corresponding test task
- Widget tests for UI components (Material Design compliance)
- Unit tests for business logic (capacity calculations, validation)
- Integration tests for user workflows (quickstart scenarios)
- Performance tests for drag-and-drop operations (<200ms target)

**Constitutional Compliance Tasks**:
- Code quality: Linting setup, documentation requirements
- TDD enforcement: Test coverage reporting, test-first validation
- UX consistency: Accessibility testing, responsive design validation
- Performance: Benchmark setup, monitoring implementation
- Observability: Logging setup, error tracking integration

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [x] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [x] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*

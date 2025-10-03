
# Implementation Plan: Initiative Mapping Kanban Board

**Branch**: `002-create-kanban-that` | **Date**: October 2, 2025 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-create-kanban-that/spec.md`

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
Create a drag-and-drop Kanban board for initiative mapping that visualizes capacity allocation and timelines. The system displays initiatives as cards across weekly columns, with platform-specific variants (BE, FE, Mobile, QA) as independent cards. Duration is calculated based on man-weeks divided by assigned team members, supporting flexible work distribution. Built as a Flutter web application with Provider state management and local storage persistence.

## Technical Context
**Language/Version**: Dart/Flutter 3.13+ (web target)  
**Primary Dependencies**: flutter_web, provider (state management), shared_preferences (local storage), equatable (value equality)  
**Storage**: shared_preferences for local browser storage, in-memory state management  
**Testing**: flutter_test, mockito for mocking, build_runner for code generation  
**Target Platform**: Web browsers (Flutter Web)  
**Project Type**: single - Flutter web application  
**Performance Goals**: <200ms interactive operations (drag/drop), <2s for capacity calculations, 60fps animations  
**Constraints**: Web browser environment, local storage only, responsive design for various screen sizes  
**Scale/Scope**: Small to medium teams (10-50 members), 100+ initiatives, quarterly planning cycles

**User Arguments**: same as previous specs - following established patterns from 001-build-a-web

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Code Quality Standards**: ✅ PASS - Flutter/Dart with provider pattern supports readable, maintainable code. Equatable for value equality. Clear model separation planned.
**Test-First Development**: ✅ PASS - TDD approach planned with contract tests before implementation, flutter_test + mockito for comprehensive testing.
**UX Consistency**: ✅ PASS - Consistent drag-and-drop patterns, Material Design components, clear visual feedback for over-allocation and disabled states.
**Performance Excellence**: ✅ PASS - Performance targets defined (<200ms interactive, <2s calculations, 60fps). Flutter web optimizations planned.
**Observability**: ✅ PASS - Error states clearly defined, capacity warnings visible, state management with Provider enables debugging.

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

**Structure Decision**: Option 1 (Single project) - Flutter web application with unified codebase structure

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
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from data-model.md entities (Initiative, PlatformVariant, TeamMember, Assignment, CapacityPeriod)
- Generate tasks from service_contracts.md (KanbanService, CapacityService, StorageService)
- Generate tasks from widget_contracts.md (KanbanBoardWidget, InitiativeCardWidget, etc.)
- Generate tasks from quickstart.md scenarios (7 integration test scenarios)
- Each entity → model class + unit tests [P]
- Each service contract → interface + implementation + tests [P]
- Each widget contract → widget + widget tests [P]
- Each quickstart scenario → integration test

**Ordering Strategy**:
- Phase 1: Data models and their tests (can run in parallel)
- Phase 2: Service interfaces and their contract tests (can run in parallel)
- Phase 3: Service implementations to make contract tests pass
- Phase 4: Widget interfaces and their widget tests (can run in parallel)
- Phase 5: Widget implementations to make widget tests pass
- Phase 6: Integration tests from quickstart scenarios
- Phase 7: UI integration and styling

**Flutter-Specific Considerations**:
- Use `flutter_test` for widget and unit tests
- Use `mockito` for service mocking in tests
- Follow Provider pattern for state management
- Use `shared_preferences` for persistence
- Implement drag-and-drop with Flutter's Draggable/DragTarget widgets

**Estimated Output**: 35-40 numbered, ordered tasks in tasks.md covering:
- 5 data model tasks [P]
- 6 service contract tasks [P] 
- 6 service implementation tasks
- 8 widget contract tasks [P]
- 8 widget implementation tasks
- 7 integration test tasks
- 5 UI styling and responsive tasks

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
- [x] Complexity deviations documented (None - no violations)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*

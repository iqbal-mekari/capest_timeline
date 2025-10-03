# Phase 0: Research & Technical Decisions

## Flutter Web Drag-and-Drop Implementation

**Decision**: Use Flutter's built-in Draggable and DragTarget widgets with custom drag feedback
**Rationale**: Native Flutter drag-and-drop provides cross-browser compatibility and integrates seamlessly with Provider state management. Supports custom drag previews and drop zones.
**Alternatives considered**: 
- HTML5 drag-and-drop API (rejected: complex Flutter-Web integration)
- Custom gesture detection (rejected: more complex, less accessible)

## State Management for Kanban Board

**Decision**: Provider pattern with ChangeNotifier for initiative and capacity state
**Rationale**: Already established in codebase, supports granular UI updates, testable with mockito, fits single-project architecture
**Alternatives considered**:
- BLoC pattern (rejected: overkill for this feature scope)
- Riverpod (rejected: would require migration from existing Provider setup)

## Timeline Column Layout

**Decision**: Use Flexible/Expanded widgets in Row for responsive weekly columns
**Rationale**: Flutter's flex layout automatically handles screen size variations, maintains equal column widths, supports horizontal scrolling for many weeks
**Alternatives considered**:
- Fixed-width columns (rejected: not responsive)
- Custom ScrollView (rejected: more complex, less maintainable)

## Capacity Calculation Engine

**Decision**: Pure Dart calculation functions with immutable data structures using Equatable
**Rationale**: Deterministic calculations, easy to test, no external dependencies, leverages existing Equatable package for value equality
**Alternatives considered**:
- External calculation library (rejected: unnecessary complexity)
- Mutable state calculations (rejected: harder to debug and test)

## Local Storage Strategy

**Decision**: SharedPreferences for persistence with JSON serialization
**Rationale**: Already in pubspec.yaml, works reliably in web browsers, simple key-value storage sufficient for initiative data
**Alternatives considered**:
- IndexedDB direct access (rejected: complex, not cross-platform)
- Web-only localStorage (rejected: breaks Flutter abstraction)

## Visual Feedback for Over-allocation

**Decision**: Color-coded cards and team member indicators using Material Design color scheme
**Rationale**: Clear visual hierarchy, accessible color choices, consistent with Material Design principles
**Alternatives considered**:
- Icon-only indicators (rejected: less immediately visible)
- Text-only warnings (rejected: clutters card layout)

## Platform Variant Card Grouping

**Decision**: Independent cards with platform prefix tags, no visual grouping
**Rationale**: Aligns with clarification that variants are independent, simplifies drag-and-drop logic, clearer for capacity allocation
**Alternatives considered**:
- Grouped card containers (rejected: conflicts with independence requirement)
- Nested card structure (rejected: complex drag-and-drop handling)

## Responsive Design Approach

**Decision**: Adaptive layout with horizontal scrolling for timeline, vertical scrolling for many initiatives
**Rationale**: Maintains usability on different screen sizes, preserves timeline visualization integrity
**Alternatives considered**:
- Collapsible columns (rejected: loses timeline overview)
- Multi-row timeline (rejected: confusing temporal relationships)

## Testing Strategy

**Decision**: Widget tests for UI components, unit tests for calculation logic, integration tests for user scenarios
**Rationale**: Comprehensive coverage of interactive features, testable with existing flutter_test and mockito setup
**Alternatives considered**:
- Golden file tests only (rejected: brittle for interactive features)
- Manual testing only (rejected: violates TDD constitution requirement)
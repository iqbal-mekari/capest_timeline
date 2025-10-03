# Feature Specification: Initiative Mapping Kanban Board

**Feature Branch**: `002-create-kanban-that`  
**Created**: October 2, 2025  
**Status**: Draft  
**Input**: User description: "create kanban that gives visibility initiative mapping, how many weeks, and who are assigned to that initiative based on capacity. User should be able to drag and drop initative on the kanban. For example, if the initative takes 4 manweeks, and  and only 1 member assigned, it will span over 4 weeks thus 4 column. If 2 members assigned, then it only span over 2 weeks. For each platform assigned to an init, there will be variant of init - platform. For example, initiative reimbursement needs BE, FE, Mobile, and QA. on kanban there will be [BE] Reimbursement, [FE] Reimbursement, etc."

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## Clarifications

### Session 2025-10-02
- Q: How should the system handle initiatives with zero assigned team members? → A: Show as disabled kanban item with error message
- Q: What is the minimum time unit for scheduling? → A: 1 week
- Q: How should fractional man-week requirements be handled? → A: Always use integer for weeks
- Q: How should the system handle capacity over-allocation when dragging initiatives? → A: Allow move and mark affected members as over-allocated
- Q: How should dependencies between platform-specific variants of the same initiative be handled? → A: No dependency enforcement - variants are independent
- Q: What specific information should be displayed on each initiative card? → A: Name, assigned members, duration only
- Q: How should the system handle rounding when calculating initiative duration from fractional results? → A: Distribute work across members with different durations (e.g., 2 weeks 2 members + 1 week 1 member)

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a project manager or team lead, I want to visualize initiative assignments and timelines on a drag-and-drop Kanban board, so I can understand resource allocation, capacity utilization, and timeline spans across different platforms and team members.

### Acceptance Scenarios
1. **Given** I have an initiative requiring 4 man-weeks with 1 team member assigned, **When** I view the Kanban board, **Then** the initiative should span across 4 weekly columns
2. **Given** I have an initiative requiring 4 man-weeks with 2 team members assigned, **When** I view the Kanban board, **Then** the initiative should span across 2 weekly columns
3. **Given** I have a "Reimbursement" initiative requiring Backend, Frontend, Mobile, and QA platforms, **When** I view the Kanban board, **Then** I should see separate cards for "[BE] Reimbursement", "[FE] Reimbursement", "[Mobile] Reimbursement", and "[QA] Reimbursement"
4. **Given** I want to reschedule an initiative, **When** I drag and drop the initiative card to a different time period, **Then** the initiative should be moved to the new timeline and update its scheduling
5. **Given** I need to see team capacity utilization, **When** I view the Kanban board, **Then** I should see how many weeks each initiative spans and which team members are assigned

### Edge Cases
- What happens when an initiative has no team members assigned? → Initiative appears as disabled card with error message
- How does the system handle initiatives with fractional man-week requirements? → Distribute across members with different durations
- What occurs when dragging an initiative to a time period where assigned team members are over-capacity? → Allow move and mark members as over-allocated
- How are dependencies between platform-specific variants of the same initiative handled? → No dependencies - variants are independent

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: System MUST display initiatives as cards on a Kanban board with weekly columns
- **FR-002**: System MUST calculate initiative duration based on total man-weeks divided by number of assigned team members
- **FR-003**: System MUST create separate cards for each platform variant of an initiative (e.g., "[BE] Reimbursement", "[FE] Reimbursement")
- **FR-004**: Users MUST be able to drag and drop initiative cards between weekly columns to reschedule them
- **FR-005**: System MUST show which team members are assigned to each initiative card
- **FR-006**: System MUST display the span of weeks an initiative occupies based on its capacity calculation
- **FR-015**: System MUST display only initiative name, assigned members, and duration on each Kanban card
- **FR-007**: System MUST allow initiative moves that cause over-allocation and visually mark affected team members as over-allocated
- **FR-008**: System MUST persist initiative scheduling changes when cards are moved
- **FR-009**: System MUST display platform prefixes clearly on initiative cards (e.g., "[BE]", "[FE]", "[Mobile]", "[QA]")
- **FR-010**: System MUST allow users to view capacity utilization across team members and time periods
- **FR-011**: System MUST handle initiatives with multiple platform requirements by creating independent variant cards with no dependency enforcement
- **FR-012**: System MUST display initiatives with zero assigned team members as disabled kanban items with error message indicating missing assignments
- **FR-013**: System MUST use 1 week as the minimum time unit for all scheduling calculations and display
- **FR-014**: System MUST always use integer weeks for all calculations, distributing fractional man-week requirements across team members with different durations (e.g., 5 man-weeks ÷ 3 members = 2 weeks for 2 members + 1 week for 1 member)
- **FR-016**: System MUST allow flexible work distribution where team members can have different duration assignments for the same initiative

### Key Entities *(include if feature involves data)*
- **Initiative**: Represents a work item with estimated effort (man-weeks), required platforms, and timeline
- **Team Member**: Individual contributor with capacity and platform specialization
- **Platform Variant**: Specific implementation of an initiative for a particular platform (BE, FE, Mobile, QA)
- **Weekly Column**: Time period container representing one week in the Kanban timeline
- **Assignment**: Relationship between team members and initiatives with capacity allocation
- **Capacity**: Available work hours/effort for team members within specific time periods

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [x] No implementation details (languages, frameworks, APIs)
- [x] Focused on user value and business needs
- [x] Written for non-technical stakeholders
- [x] All mandatory sections completed

### Requirement Completeness
- [x] No [NEEDS CLARIFICATION] markers remain
- [x] Requirements are testable and unambiguous  
- [x] Success criteria are measurable
- [x] Scope is clearly bounded
- [x] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [x] Review checklist passed

---

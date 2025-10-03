# Quickstart: Initiative Mapping Kanban

## User Story Validation

This quickstart guide validates the core user scenarios from the specification through step-by-step interactions.

## Prerequisites

- Flutter web application running locally
- Test data: 3 team members, 2 initiatives with multiple platforms
- Browser with drag-and-drop support (Chrome, Firefox, Safari)

## Test Scenario 1: Basic Initiative Duration Calculation

**Goal**: Verify that initiative duration spans correct number of weeks based on team assignment

### Setup
1. Create initiative "Feature A" with 4 man-weeks effort
2. Create platform variants: [BE] Feature A, [FE] Feature A
3. Assign 1 team member to [BE] Feature A
4. Assign 1 team member to [FE] Feature A

### Expected Behavior
- [BE] Feature A should span 4 weekly columns (4 man-weeks ÷ 1 member = 4 weeks)
- [FE] Feature A should span 4 weekly columns (4 man-weeks ÷ 1 member = 4 weeks)
- Both variants appear as separate, independent cards

### Validation Steps
1. Open kanban board
2. Locate [BE] Feature A card
3. Verify card displays: name, assigned member, 4-week duration
4. Count visual span across weekly columns (should be 4 columns)
5. Repeat for [FE] Feature A card
6. Confirm both cards can be moved independently

## Test Scenario 2: Multi-Member Duration Reduction

**Goal**: Verify that adding team members reduces initiative duration

### Setup
1. Use existing "Feature A" from Scenario 1
2. Assign second team member to [BE] Feature A (total: 2 members)
3. Keep [FE] Feature A with 1 member

### Expected Behavior
- [BE] Feature A now spans 2 weekly columns (4 man-weeks ÷ 2 members = 2 weeks)
- [FE] Feature A still spans 4 weekly columns (unchanged)

### Validation Steps
1. Add second member to [BE] Feature A through assignment interface
2. Observe card duration update automatically
3. Verify [BE] Feature A now spans 2 columns instead of 4
4. Confirm [FE] Feature A remains unchanged at 4 columns
5. Check that both members are displayed on [BE] Feature A card

## Test Scenario 3: Platform Variant Independence

**Goal**: Verify platform variants are independent and can be scheduled separately

### Setup
1. Create initiative "Reimbursement System" requiring BE, FE, Mobile, QA platforms
2. Assign team members to each platform variant
3. System should create 4 independent cards

### Expected Behavior
- Four separate cards: [BE] Reimbursement, [FE] Reimbursement, [Mobile] Reimbursement, [QA] Reimbursement
- Each card can be dragged to different weeks independently
- No visual connections or dependencies between cards

### Validation Steps
1. Create "Reimbursement System" initiative with all 4 platforms
2. Verify 4 separate cards appear on kanban board
3. Drag [BE] Reimbursement to Week 1
4. Drag [FE] Reimbursement to Week 3
5. Drag [Mobile] Reimbursement to Week 2
6. Drag [QA] Reimbursement to Week 4
7. Confirm all moves are accepted and cards display in different weeks

## Test Scenario 4: Drag-and-Drop Rescheduling

**Goal**: Verify drag-and-drop moves initiatives and updates scheduling

### Setup
1. Use cards from previous scenarios positioned in various weeks
2. Attempt to move cards to different time periods

### Expected Behavior
- Cards can be dragged between weekly columns
- Drop zones highlight during drag
- Successful drops update card position and persist changes
- Over-allocation warnings appear when capacity exceeded

### Validation Steps
1. Start dragging [BE] Feature A card
2. Observe drag feedback (card elevation, preview)
3. Hover over target week column
4. Observe drop zone highlighting
5. Release to drop in new week
6. Verify card appears in new position
7. Refresh page and confirm position persisted
8. Try moving card to week where assigned member is over-allocated
9. Verify over-allocation warning appears but move is allowed

## Test Scenario 5: Zero Assignment Handling

**Goal**: Verify initiatives with no team members show as disabled

### Setup
1. Create initiative "Future Project" with BE and FE platforms
2. Do not assign any team members to either platform variant

### Expected Behavior
- [BE] Future Project appears as disabled card with error message
- [FE] Future Project appears as disabled card with error message
- Cards are visually distinct (grayed out, error icon)
- Cards cannot be dragged or moved

### Validation Steps
1. Create "Future Project" without assignments
2. Verify both platform variant cards appear on board
3. Confirm cards are visually disabled (grayed out appearance)
4. Check for error message indicating missing assignments
5. Try to drag disabled cards (should not respond to drag attempts)
6. Assign team member to one variant
7. Verify that variant becomes enabled while other remains disabled

## Test Scenario 6: Capacity Utilization Visibility

**Goal**: Verify users can see team capacity utilization and over-allocation warnings

### Setup
1. Use scenarios above to create multiple overlapping assignments
2. Intentionally over-allocate at least one team member

### Expected Behavior
- Capacity indicators show utilization per team member per week
- Over-allocated members highlighted with warning colors/icons
- Capacity information updates as cards are moved

### Validation Steps
1. View capacity indicators on kanban board
2. Identify team member with multiple assignments in same week
3. Verify capacity bar shows utilization percentage
4. Look for over-allocation warning (red color/warning icon)
5. Move one assignment to different week
6. Observe capacity indicators update in real-time
7. Confirm over-allocation warning disappears when capacity normalized

## Test Scenario 7: Fractional Work Distribution

**Goal**: Verify flexible work distribution across team members

### Setup
1. Create initiative "Complex Feature" with 5 man-weeks effort
2. Assign 3 team members to same platform variant

### Expected Behavior
- System distributes work as 2 weeks for 2 members + 1 week for 1 member
- All three members appear on card
- Duration calculation uses integer weeks only

### Validation Steps
1. Create initiative with 5 man-weeks effort
2. Assign 3 team members to single platform variant
3. Verify card shows all 3 assigned members
4. Check duration calculation (should be distributed as 2+2+1 weeks or similar)
5. Confirm no fractional week displays anywhere in UI
6. Verify total effort still equals 5 man-weeks when summed

## Performance Validation

### Interaction Responsiveness
- Drag operations start within 100ms of mouse/touch
- Drop feedback appears within 50ms of hover
- Card position updates complete within 200ms
- Capacity recalculations complete within 500ms

### Data Operations
- Board loading completes within 2 seconds with 100+ initiatives
- Save operations complete within 1 second
- Search/filter operations respond within 300ms

## Accessibility Validation

### Keyboard Navigation
- All cards reachable via Tab key
- Arrow keys move focus between weeks
- Enter key opens card details
- Escape key cancels drag operations

### Screen Reader Support
- Cards announce initiative name, platform, assigned members
- Capacity warnings announced clearly
- Drag-and-drop operations have audio feedback
- Time periods clearly labeled and navigable

## Success Criteria

All test scenarios pass without errors, performance targets met, accessibility requirements satisfied. User can successfully:

1. ✅ Create initiatives with multiple platform variants
2. ✅ View duration calculations based on team assignments  
3. ✅ Drag and drop cards to reschedule initiatives
4. ✅ See capacity utilization and over-allocation warnings
5. ✅ Handle edge cases (zero assignments, fractional calculations)
6. ✅ Use the system responsively across device types
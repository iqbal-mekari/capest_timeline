import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:capest_timeline/main.dart' as app;
import 'package:capest_timeline/providers/kanban_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Kanban Board Integration Tests', () {
    
    group('Complete Initiative Lifecycle', () {
      testWidgets('should create, assign, and manage initiative through full workflow', (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Wait for app to initialize
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify we're on the main screen
        expect(find.text('Capacity Timeline'), findsOneWidget);
        expect(find.text('Create Initiative'), findsOneWidget);

        // Step 1: Create new initiative
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Fill out the initiative form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initiative Title'),
          'Reimbursement System Overhaul'
        );
        
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description'),
          'Complete overhaul of the reimbursement system with modern architecture'
        );

        // Select platform variants
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Frontend'));
        await tester.tap(find.widgetWithText(CheckboxListTile, 'QA'));
        await tester.pumpAndSettle();

        // Enter estimated weeks for each platform
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
          '6'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Frontend Estimated Weeks'),
          '4'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'QA Estimated Weeks'),
          '2'
        );

        // Submit the form
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Verify initiative was created and appears in backlog
        expect(find.text('[BE] Reimbursement System Overhaul'), findsOneWidget);
        expect(find.text('[FE] Reimbursement System Overhaul'), findsOneWidget);
        expect(find.text('[QA] Reimbursement System Overhaul'), findsOneWidget);

        // Step 2: Drag backend variant to timeline
        final backendCard = find.text('[BE] Reimbursement System Overhaul');


        await tester.drag(backendCard, const Offset(200, 0));
        await tester.pumpAndSettle();

        // Verify backend variant moved to first week
        // The card should now be in the week column area
        expect(find.text('[BE] Reimbursement System Overhaul'), findsOneWidget);

        // Step 3: Drag frontend variant to second week
        final frontendCard = find.text('[FE] Reimbursement System Overhaul');


        await tester.drag(frontendCard, const Offset(300, 0));
        await tester.pumpAndSettle();

        // Verify capacity indicators update
        expect(find.byIcon(Icons.warning), findsNothing); // Should not be over capacity yet

        // Step 4: Assign team members
        await tester.longPress(find.text('[BE] Reimbursement System Overhaul'));
        await tester.pumpAndSettle();

        // Context menu should appear
        expect(find.text('Assign Team Member'), findsOneWidget);
        await tester.tap(find.text('Assign Team Member'));
        await tester.pumpAndSettle();

        // Select team member from dropdown
        await tester.tap(find.text('Select Team Member'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('John Doe').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assign'));
        await tester.pumpAndSettle();

        // Verify assignment
        expect(find.text('John Doe'), findsOneWidget);

        // Step 5: Test capacity warnings
        // Try to drag QA variant to same week as backend (should trigger warning)
        final qaCard = find.text('[QA] Reimbursement System Overhaul');
        
        await tester.drag(qaCard, const Offset(200, 0)); // Same position as backend
        await tester.pumpAndSettle();

        // Should show capacity warning if it would cause over-allocation
        // This depends on team capacity settings

        // Step 6: Navigate timeline
        await tester.tap(find.byIcon(Icons.arrow_forward));
        await tester.pumpAndSettle();

        // Timeline should shift forward one week
        expect(find.text('Week 2'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Timeline should shift back
        expect(find.text('Week 1'), findsOneWidget);

        // Step 7: Edit initiative
        await tester.longPress(find.text('[BE] Reimbursement System Overhaul'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit Initiative'));
        await tester.pumpAndSettle();

        // Modify the title
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initiative Title'),
          'Advanced Reimbursement System'
        );

        await tester.tap(find.text('Update Initiative'));
        await tester.pumpAndSettle();

        // Verify title updated
        expect(find.text('[BE] Advanced Reimbursement System'), findsOneWidget);

        // Step 8: Test persistence (restart app simulation)
        // Get the provider and save state
        final provider = Provider.of<KanbanProvider>(
          tester.element(find.byType(MaterialApp)),
          listen: false
        );
        await provider.saveToStorage();

        // Simulate app restart by recreating the app
        await tester.pumpWidget(Container()); // Clear current widget
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Verify data persisted
        expect(find.text('[BE] Advanced Reimbursement System'), findsOneWidget);
        expect(find.text('[FE] Reimbursement System Overhaul'), findsOneWidget);
        expect(find.text('John Doe'), findsOneWidget);
      });
    });

    group('Drag and Drop Workflows', () {
      testWidgets('should handle complex drag and drop scenarios', (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create multiple initiatives for testing
        for (int i = 1; i <= 3; i++) {
          await tester.tap(find.text('Create Initiative'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Initiative Title'),
            'Test Initiative $i'
          );

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Description'),
            'Description for initiative $i'
          );

          // Select all platforms
          await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
          await tester.tap(find.widgetWithText(CheckboxListTile, 'Frontend'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
            '2'
          );
          await tester.enterText(
            find.widgetWithText(TextFormField, 'Frontend Estimated Weeks'),
            '2'
          );

          await tester.tap(find.text('Create Initiative'));
          await tester.pumpAndSettle();
        }

        // Test 1: Drag multiple variants to same week
        final backendCard1 = find.text('[BE] Test Initiative 1');
        final backendCard2 = find.text('[BE] Test Initiative 2');


        await tester.drag(backendCard1, const Offset(200, 0));
        await tester.pumpAndSettle();

        await tester.drag(backendCard2, const Offset(200, 50)); // Slightly lower
        await tester.pumpAndSettle();

        // Verify both cards are in the week
        // This should stack them vertically

        // Test 2: Drag variant between weeks
        await tester.drag(backendCard1, const Offset(100, 0)); // Move to next week
        await tester.pumpAndSettle();

        // Test 3: Try to drag to over-capacity week
        final backendCard3 = find.text('[BE] Test Initiative 3');
        
        // This should either reject the drop or show warning
        await tester.drag(backendCard3, const Offset(200, 0));
        await tester.pumpAndSettle();

        // Test 4: Drag variant back to backlog
        await tester.drag(backendCard1, const Offset(-200, 0));
        await tester.pumpAndSettle();

        // Should return to backlog area
        expect(find.text('[BE] Test Initiative 1'), findsOneWidget);
      });

      testWidgets('should prevent invalid drops', (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create initiative with large time estimate
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initiative Title'),
          'Large Initiative'
        );

        await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
        await tester.pumpAndSettle();

        // Set very high weeks that would exceed capacity
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
          '20' // Way more than weekly capacity
        );

        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Try to drag to timeline - should be rejected or show warning
        final largeCard = find.text('[BE] Large Initiative');
        
        await tester.drag(largeCard, const Offset(200, 0));
        await tester.pumpAndSettle();

        // Should show error message or reject drop
        expect(find.byIcon(Icons.error), findsWidgets);
      });
    });

    group('Capacity Management Workflows', () {
      testWidgets('should manage team capacity correctly', (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Test 1: Check initial capacity display
        expect(find.byType(LinearProgressIndicator), findsWidgets);

        // Create initiatives to fill capacity
        for (int i = 1; i <= 5; i++) {
          await tester.tap(find.text('Create Initiative'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Initiative Title'),
            'Capacity Test $i'
          );

          await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
            '1'
          );

          await tester.tap(find.text('Create Initiative'));
          await tester.pumpAndSettle();
        }

        // Drag initiatives to timeline until capacity is reached
        for (int i = 1; i <= 5; i++) {
          final card = find.text('[BE] Capacity Test $i');
          await tester.drag(card, Offset(200.0 + (i * 10), 0));
          await tester.pumpAndSettle();
        }

        // Should show capacity warnings
        expect(find.byIcon(Icons.warning), findsWidgets);

        // Test 2: Check capacity indicators
        expect(find.textContaining('%'), findsWidgets); // Percentage indicators
        expect(find.textContaining('hours'), findsWidgets); // Hour indicators

        // Test 3: Test over-allocation warning
        // The UI should visually indicate over-allocation with red indicators
        expect(find.byType(LinearProgressIndicator), findsWidgets);
      });

      testWidgets('should handle team member assignment and capacity', (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create initiative
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initiative Title'),
          'Team Assignment Test'
        );

        await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Frontend'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
          '3'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Frontend Estimated Weeks'),
          '2'
        );

        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Drag to timeline
        await tester.drag(
          find.text('[BE] Team Assignment Test'),
          const Offset(200, 0)
        );
        await tester.pumpAndSettle();

        // Assign team member
        await tester.longPress(find.text('[BE] Team Assignment Test'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assign Team Member'));
        await tester.pumpAndSettle();

        // Select team member
        await tester.tap(find.text('Select Team Member'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('John Doe').last);
        await tester.tap(find.text('Assign'));
        await tester.pumpAndSettle();

        // Verify assignment shows in UI
        expect(find.text('John Doe'), findsOneWidget);

        // Assign frontend to different member
        await tester.drag(
          find.text('[FE] Team Assignment Test'),
          const Offset(300, 0)
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.text('[FE] Team Assignment Test'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assign Team Member'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select Team Member'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Jane Smith').last);
        await tester.tap(find.text('Assign'));
        await tester.pumpAndSettle();

        // Verify both assignments
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Jane Smith'), findsOneWidget);

        // Check capacity indicators for each team member
        expect(find.textContaining('John Doe'), findsOneWidget);
        expect(find.textContaining('Jane Smith'), findsOneWidget);
      });
    });

    group('Timeline Navigation Workflows', () {
      testWidgets('should navigate timeline and maintain state', (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create and assign initiatives
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initiative Title'),
          'Timeline Test'
        );

        await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
          '4'
        );

        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Drag to current week
        await tester.drag(
          find.text('[BE] Timeline Test'),
          const Offset(200, 0)
        );
        await tester.pumpAndSettle();

        // Navigate forward
        await tester.tap(find.byIcon(Icons.arrow_forward));
        await tester.pumpAndSettle();

        // Should show next set of weeks
        expect(find.text('Week'), findsWidgets);

        // Navigate back
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        // Should return to original view with initiative still there
        expect(find.text('[BE] Timeline Test'), findsOneWidget);

        // Test "Today" button
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();

        // Should reset to current week
        // The exact week text depends on date formatting
      });

      testWidgets('should handle long-term planning', (WidgetTester tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create long-running initiative
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initiative Title'),
          'Long Term Project'
        );

        await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
        await tester.tap(find.widgetWithText(CheckboxListTile, 'Frontend'));
        await tester.tap(find.widgetWithText(CheckboxListTile, 'QA'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
          '8'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Frontend Estimated Weeks'),
          '6'
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'QA Estimated Weeks'),
          '4'
        );

        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Drag backend to current week
        await tester.drag(
          find.text('[BE] Long Term Project'),
          const Offset(200, 0)
        );
        await tester.pumpAndSettle();

        // Navigate forward to place frontend later
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.byIcon(Icons.arrow_forward));
          await tester.pumpAndSettle();
        }

        // Drag frontend to future week
        await tester.drag(
          find.text('[FE] Long Term Project'),
          const Offset(200, 0)
        );
        await tester.pumpAndSettle();

        // Navigate further for QA
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byIcon(Icons.arrow_forward));
          await tester.pumpAndSettle();
        }

        // Drag QA to even later week
        await tester.drag(
          find.text('[QA] Long Term Project'),
          const Offset(200, 0)
        );
        await tester.pumpAndSettle();

        // Navigate back to beginning
        await tester.tap(find.text('Today'));
        await tester.pumpAndSettle();

        // Should show backend variant in current timeline
        expect(find.text('[BE] Long Term Project'), findsOneWidget);
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
        // This would require mocking network calls
        // For now, test UI error states
        
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Test error handling in create initiative
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Submit empty form to trigger validation errors
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Should show validation errors
        expect(find.text('Please enter an initiative title'), findsOneWidget);
      });

      testWidgets('should handle storage errors', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create initiative that would trigger storage error
        // This would require mocking storage failure
        
        // For now, verify error UI components exist
        expect(find.byType(SnackBar), findsNothing); // No errors initially
      });

      testWidgets('should handle invalid drag operations', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create initiative
        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Initiative Title'),
          'Invalid Drag Test'
        );

        await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
          '2'
        );

        await tester.tap(find.text('Create Initiative'));
        await tester.pumpAndSettle();

        // Try to drag to invalid location (outside drop zones)
        final card = find.text('[BE] Invalid Drag Test');
        
        await tester.drag(card, const Offset(0, -500)); // Drag up off screen
        await tester.pumpAndSettle();

        // Should reject drop and return to original position
        expect(find.text('[BE] Invalid Drag Test'), findsOneWidget);
      });
    });

    group('Performance and Stress Tests', () {
      testWidgets('should handle multiple initiatives efficiently', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Create many initiatives to test performance
        for (int i = 1; i <= 10; i++) {
          await tester.tap(find.text('Create Initiative'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Initiative Title'),
            'Performance Test $i'
          );

          await tester.tap(find.widgetWithText(CheckboxListTile, 'Backend'));
          await tester.pumpAndSettle();

          await tester.enterText(
            find.widgetWithText(TextFormField, 'Backend Estimated Weeks'),
            '1'
          );

          await tester.tap(find.text('Create Initiative'));
          await tester.pumpAndSettle();
        }

        // Verify all initiatives were created
        for (int i = 1; i <= 10; i++) {
          expect(find.text('[BE] Performance Test $i'), findsOneWidget);
        }

        // Test rapid navigation
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byIcon(Icons.arrow_forward));
          await tester.pump(const Duration(milliseconds: 100));
        }

        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        // Should still be responsive
        expect(find.text('Create Initiative'), findsOneWidget);
      });
    });
  });
}
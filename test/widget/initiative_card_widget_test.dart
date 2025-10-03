import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/widgets/initiative_card_widget.dart';
import 'package:capest_timeline/models/models.dart';

void main() {
  group('InitiativeCardWidget Tests', () {
    Widget createTestWidget(InitiativeCardWidget widget) {
      return MaterialApp(
        home: Scaffold(
          body: widget,
        ),
      );
    }

    group('Display States', () {
      testWidgets('should display platform type badge correctly', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'Backend Authentication',
          estimatedWeeks: 3,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('BACKEND'), findsOneWidget);
        expect(find.text('Backend Authentication'), findsOneWidget);
      });

      testWidgets('should display different platform types with correct styling', (WidgetTester tester) async {
        for (final platformType in PlatformType.values) {
          // Arrange
          final variant = PlatformVariant(
            id: 'var-${platformType.name}',
            initiativeId: 'init-1',
            platformType: platformType,
            title: '${platformType.displayName} Task',
            estimatedWeeks: 2,
            currentWeek: DateTime.now(),
            isAssigned: false,
          );

          // Act
          await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
          await tester.pumpAndSettle();

          // Assert
          expect(find.text(platformType.displayName.toUpperCase()), findsOneWidget);
          expect(find.text('${platformType.displayName} Task'), findsOneWidget);
          
          // Check that platform-specific styling is applied (color border)
          final cardWidget = tester.widget<Container>(find.byType(Container).first);
          expect(cardWidget.decoration, isNotNull);
        }
      });

      testWidgets('should display estimated weeks correctly', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.frontend,
          title: 'Frontend Dashboard',
          estimatedWeeks: 5,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('5w'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
      });

      testWidgets('should show assignment status when assigned', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.mobile,
          title: 'Mobile App Feature',
          estimatedWeeks: 4,
          currentWeek: DateTime.now(),
          isAssigned: true,
          assignedMemberId: 'member-1',
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Assigned'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('should not show assignment status when unassigned', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.qa,
          title: 'QA Testing Suite',
          estimatedWeeks: 2,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Assigned'), findsNothing);
        expect(find.byIcon(Icons.person), findsNothing);
      });
    });

    group('Text Overflow and Layout', () {
      testWidgets('should handle long titles gracefully', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'This is a very long initiative title that should be truncated properly to avoid layout issues',
          estimatedWeeks: 3,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(InitiativeCardWidget), findsOneWidget);
        
        // Find the title text widget and verify it has overflow handling
        final titleFinder = find.text(variant.title);
        expect(titleFinder, findsOneWidget);
        
        final textWidget = tester.widget<Text>(titleFinder);
        expect(textWidget.maxLines, equals(2));
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should display short titles without truncation', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.frontend,
          title: 'Short Title',
          estimatedWeeks: 1,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Short Title'), findsOneWidget);
        expect(find.byType(InitiativeCardWidget), findsOneWidget);
      });
    });

    group('Drag Feedback Mode', () {
      testWidgets('should apply drag feedback styling when isDragFeedback is true', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'Drag Test',
          estimatedWeeks: 2,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          InitiativeCardWidget(variant: variant, isDragFeedback: true),
        ));
        await tester.pumpAndSettle();

        // Assert
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);
        
        final cardWidget = tester.widget<Card>(cardFinder);
        expect(cardWidget.elevation, equals(8)); // Higher elevation for drag feedback
      });

      testWidgets('should apply normal styling when isDragFeedback is false', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.frontend,
          title: 'Normal Test',
          estimatedWeeks: 2,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(
          InitiativeCardWidget(variant: variant, isDragFeedback: false),
        ));
        await tester.pumpAndSettle();

        // Assert
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);
        
        final cardWidget = tester.widget<Card>(cardFinder);
        expect(cardWidget.elevation, equals(2)); // Normal elevation
      });
    });

    group('Platform Color Coding', () {
      testWidgets('should use blue color for Backend platform', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'Backend Task',
          estimatedWeeks: 3,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert - Check that the border color is applied
        final containerWithBorder = find.byType(Container).first;
        final container = tester.widget<Container>(containerWithBorder);
        final boxDecoration = container.decoration as BoxDecoration;
        expect(boxDecoration.border, isNotNull);
        
        final border = boxDecoration.border as Border;
        expect(border.left.color, equals(Colors.blue));
      });

      testWidgets('should use green color for Frontend platform', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.frontend,
          title: 'Frontend Task',
          estimatedWeeks: 3,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        final containerWithBorder = find.byType(Container).first;
        final container = tester.widget<Container>(containerWithBorder);
        final boxDecoration = container.decoration as BoxDecoration;
        
        final border = boxDecoration.border as Border;
        expect(border.left.color, equals(Colors.green));
      });

      testWidgets('should use orange color for Mobile platform', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.mobile,
          title: 'Mobile Task',
          estimatedWeeks: 3,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        final containerWithBorder = find.byType(Container).first;
        final container = tester.widget<Container>(containerWithBorder);
        final boxDecoration = container.decoration as BoxDecoration;
        
        final border = boxDecoration.border as Border;
        expect(border.left.color, equals(Colors.orange));
      });

      testWidgets('should use red color for QA platform', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.qa,
          title: 'QA Task',
          estimatedWeeks: 3,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        final containerWithBorder = find.byType(Container).first;
        final container = tester.widget<Container>(containerWithBorder);
        final boxDecoration = container.decoration as BoxDecoration;
        
        final border = boxDecoration.border as Border;
        expect(border.left.color, equals(Colors.red));
      });
    });

    group('Widget Structure', () {
      testWidgets('should have proper card structure', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'Structure Test',
          estimatedWeeks: 2,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert - Check widget hierarchy
        expect(find.byType(Card), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(find.byType(Column), findsAtLeastNWidgets(1));
        expect(find.byType(Row), findsAtLeastNWidgets(1));
      });

      testWidgets('should have proper spacing and padding', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.frontend,
          title: 'Spacing Test',
          estimatedWeeks: 2,
          currentWeek: DateTime.now(),
          isAssigned: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert - Check for SizedBox spacers
        expect(find.byType(SizedBox), findsAtLeastNWidgets(2));
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle zero estimated weeks', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'Zero Weeks Test',
          estimatedWeeks: 0,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('0w'), findsOneWidget);
        expect(find.byType(InitiativeCardWidget), findsOneWidget);
      });

      testWidgets('should handle very large estimated weeks', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.mobile,
          title: 'Large Weeks Test',
          estimatedWeeks: 999,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('999w'), findsOneWidget);
        expect(find.byType(InitiativeCardWidget), findsOneWidget);
      });

      testWidgets('should handle empty title gracefully', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.qa,
          title: '', // Empty title
          estimatedWeeks: 1,
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert - Widget should still render without errors
        expect(find.byType(InitiativeCardWidget), findsOneWidget);
        expect(find.text('QA'), findsOneWidget); // Platform badge should still show
      });
    });

    group('Accessibility', () {
      testWidgets('should provide proper semantic information', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'Accessibility Test',
          estimatedWeeks: 3,
          currentWeek: DateTime.now(),
          isAssigned: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert - Check that text elements are present for screen readers
        expect(find.text('BACKEND'), findsOneWidget);
        expect(find.text('Accessibility Test'), findsOneWidget);
        expect(find.text('3w'), findsOneWidget);
        expect(find.text('Assigned'), findsOneWidget);
      });

      testWidgets('should have proper contrast for assigned state', (WidgetTester tester) async {
        // Arrange
        final variant = PlatformVariant(
          id: 'var-1',
          initiativeId: 'init-1',
          platformType: PlatformType.frontend,
          title: 'Contrast Test',
          estimatedWeeks: 2,
          currentWeek: DateTime.now(),
          isAssigned: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(InitiativeCardWidget(variant: variant)));
        await tester.pumpAndSettle();

        // Assert - Check that assigned status is visually distinct
        expect(find.text('Assigned'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
        
        // Verify the assigned text has proper theming
        final assignedTextFinder = find.text('Assigned');
        final assignedText = tester.widget<Text>(assignedTextFinder);
        expect(assignedText.style, isNotNull);
      });
    });
  });
}
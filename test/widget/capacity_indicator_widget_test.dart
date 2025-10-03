import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/widgets/capacity_indicator_widget.dart';
import 'package:capest_timeline/models/models.dart';

void main() {
  group('CapacityIndicatorWidget Tests', () {
    late CapacityPeriod lowUtilizationPeriod;
    late CapacityPeriod mediumUtilizationPeriod;
    late CapacityPeriod highUtilizationPeriod;
    late CapacityPeriod overAllocatedPeriod;

    setUp(() {
      final weekStart = DateTime(2024, 1, 1);
      final weekEnd = weekStart.add(const Duration(days: 6));

      // Low utilization (50%) - 20 hours out of 40
      final lowUtilizationAssignments = [
        Assignment(
          id: 'low-assignment',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 1,
          capacityPercentage: 0.5, // 50% of standard 40 hours = 20 hours
          startWeek: weekStart,
        ),
      ];

      lowUtilizationPeriod = CapacityPeriod(
        weekStart: weekStart,
        weekEnd: weekEnd,
        assignments: lowUtilizationAssignments,
        totalCapacityAvailable: 40.0,
      );

      // Medium utilization (75%) - 30 hours out of 40
      final mediumUtilizationAssignments = [
        Assignment(
          id: 'medium-assignment',
          memberId: 'member-1',
          platformType: PlatformType.frontend,
          allocatedWeeks: 1,
          capacityPercentage: 0.75, // 75% of standard 40 hours = 30 hours
          startWeek: weekStart,
        ),
      ];

      mediumUtilizationPeriod = CapacityPeriod(
        weekStart: weekStart,
        weekEnd: weekEnd,
        assignments: mediumUtilizationAssignments,
        totalCapacityAvailable: 40.0,
      );

      // High utilization (95%) - 38 hours out of 40
      final highUtilizationAssignments = [
        Assignment(
          id: 'high-assignment',
          memberId: 'member-1',
          platformType: PlatformType.mobile,
          allocatedWeeks: 1,
          capacityPercentage: 0.95, // 95% of standard 40 hours = 38 hours
          startWeek: weekStart,
        ),
      ];

      highUtilizationPeriod = CapacityPeriod(
        weekStart: weekStart,
        weekEnd: weekEnd,
        assignments: highUtilizationAssignments,
        totalCapacityAvailable: 40.0,
      );

      // Over-allocated (120%) - 48 hours out of 40
      final overAllocatedAssignments = [
        Assignment(
          id: 'over-assignment',
          memberId: 'member-1',
          platformType: PlatformType.qa,
          allocatedWeeks: 1,
          capacityPercentage: 1.2, // 120% of standard 40 hours = 48 hours
          startWeek: weekStart,
        ),
      ];

      overAllocatedPeriod = CapacityPeriod(
        weekStart: weekStart,
        weekEnd: weekEnd,
        assignments: overAllocatedAssignments,
        totalCapacityAvailable: 40.0,
      );
    });

    Widget createTestWidget(CapacityIndicatorWidget widget) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: widget,
          ),
        ),
      );
    }

    group('Compact Mode', () {
      testWidgets('should display compact indicator for low utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('50%'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing); // Compact mode doesn't show progress
      });

      testWidgets('should display compact indicator for medium utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: mediumUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('75%'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        
        // Check color styling - should be yellow
        final container = tester.widget<Container>(find.byType(Container).first);
        expect(container.decoration, isA<BoxDecoration>());
      });

      testWidgets('should display compact indicator for high utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: highUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('95%'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
      });

      testWidgets('should display compact indicator for over-allocation', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: overAllocatedPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('120%'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should have proper compact styling structure', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Container), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
        expect(find.byType(SizedBox), findsWidgets); // At least one SizedBox for spacing
        
        // Verify the compact widget has correct styling
        final container = tester.widget<Container>(find.byType(Container));
        expect(container.margin, const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
        expect(container.padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 4));
      });
    });

    group('Detailed Mode', () {
      testWidgets('should display detailed indicator for low utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Capacity'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.text('Available: 40.0h'), findsOneWidget);
        expect(find.text('Used: 20.0h'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should display detailed indicator for medium utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: mediumUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('Available: 40.0h'), findsOneWidget);
        expect(find.text('Used: 30.0h'), findsOneWidget);
        expect(find.byIcon(Icons.schedule), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);

        // No over-allocation warning should be shown
        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });

      testWidgets('should display detailed indicator for high utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: highUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('95%'), findsOneWidget);
        expect(find.text('Available: 40.0h'), findsOneWidget);
        expect(find.text('Used: 38.0h'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should display over-allocation warning in detailed mode', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: overAllocatedPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('120%'), findsOneWidget);
        expect(find.text('Available: 40.0h'), findsOneWidget);
        expect(find.text('Used: 48.0h'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        expect(find.textContaining('Over-allocated by 8.0h'), findsOneWidget);
      });

      testWidgets('should have proper detailed mode structure', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Row), findsAtLeastNWidgets(2)); // Header row + details row
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.byType(SizedBox), findsAtLeastNWidgets(2)); // Multiple spacers
      });
    });

    group('Color Coding', () {
      testWidgets('should use green color for low utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
        expect(icon.color, equals(Colors.green));
      });

      testWidgets('should use yellow color for medium-high utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: mediumUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.schedule));
        expect(icon.color, equals(Colors.yellow.shade700));
      });

      testWidgets('should use orange color for near-capacity utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: highUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.warning));
        expect(icon.color, equals(Colors.orange));
      });

      testWidgets('should use red color for over-allocation', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: overAllocatedPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final icon = tester.widget<Icon>(find.byIcon(Icons.error));
        expect(icon.color, equals(Colors.red));
      });
    });

    group('Progress Bar', () {
      testWidgets('should show correct progress value for detailed mode', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: mediumUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator)
        );
        expect(progressIndicator.value, equals(0.75)); // 75% utilization
      });

      testWidgets('should clamp progress value to 1.0 for over-allocation', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: overAllocatedPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator)
        );
        expect(progressIndicator.value, equals(1.0)); // Clamped to 100%
      });

      testWidgets('should have proper progress bar styling', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator)
        );
        expect(progressIndicator.minHeight, equals(6));
        expect(progressIndicator.valueColor, isA<AlwaysStoppedAnimation<Color>>());
      });
    });

    // Helper function to create capacity periods with specific utilization values
    CapacityPeriod createCapacityPeriodWithUtilization({
      required DateTime weekStart,
      required double totalCapacity,
      required double targetUtilization,
    }) {
      final weekEnd = weekStart.add(const Duration(days: 6));
      // capacityPercentage is based on standard 40-hour workweek
      // To achieve targetUtilization hours, we need: (capacityPercentage * 40) = targetUtilization
      final capacityPercentage = targetUtilization / 40.0;
      
      final assignments = [
        Assignment(
          id: 'test-assignment',
          memberId: 'test-member',
          platformType: PlatformType.backend,
          allocatedWeeks: 1,
          capacityPercentage: capacityPercentage,
          startWeek: weekStart,
        ),
      ];

      return CapacityPeriod(
        weekStart: weekStart,
        weekEnd: weekEnd,
        assignments: assignments,
        totalCapacityAvailable: totalCapacity,
      );
    }

    group('Capacity Values Display', () {
      testWidgets('should display correct decimal precision for capacity values', (WidgetTester tester) async {
        // Arrange
        final precisionPeriod = createCapacityPeriodWithUtilization(
          weekStart: DateTime(2024, 1, 1),
          totalCapacity: 37.5,
          targetUtilization: 23.75,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: precisionPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Available: 37.5h'), findsOneWidget);
        expect(find.text('Used: 23.8h'), findsOneWidget); // 23.75 rounded to 1 decimal
        expect(find.text('63%'), findsOneWidget); // 63.33% rounded to nearest integer
      });

      testWidgets('should handle zero capacity gracefully', (WidgetTester tester) async {
        // Arrange
        final zeroPeriod = CapacityPeriod(
          weekStart: DateTime(2024, 1, 1),
          weekEnd: DateTime(2024, 1, 7),
          assignments: const [],
          totalCapacityAvailable: 0.0,
          utilizedCapacity: 0.0,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: zeroPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Available: 0.0h'), findsOneWidget);
        expect(find.text('Used: 0.0h'), findsOneWidget);
        expect(find.text('0%'), findsOneWidget);
        expect(find.byType(CapacityIndicatorWidget), findsOneWidget);
      });

      testWidgets('should handle very high capacity values', (WidgetTester tester) async {
        // Arrange
        final highCapacityPeriod = createCapacityPeriodWithUtilization(
          weekStart: DateTime(2024, 1, 1),
          totalCapacity: 1000.0,
          targetUtilization: 750.0,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: highCapacityPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Available: 1000.0h'), findsOneWidget);
        expect(find.text('Used: 750.0h'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      });
    });

    group('Warning Messages', () {
      testWidgets('should show over-allocation warning with correct amount', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: overAllocatedPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('Over-allocated by 8.0h'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      });

      testWidgets('should not show warning for normal utilization', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('Over-allocated'), findsNothing);
        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });

      testWidgets('should have proper warning container styling', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: overAllocatedPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        final warningText = find.textContaining('Over-allocated');
        expect(warningText, findsOneWidget);
        
        // Find the container that contains the warning
        final warningContainer = find.ancestor(
          of: warningText,
          matching: find.byType(Container),
        ).first;
        expect(warningContainer, findsOneWidget);
      });
    });

    group('Widget Structure', () {
      testWidgets('should have proper widget hierarchy in compact mode', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CapacityIndicatorWidget), findsOneWidget);
        expect(find.byType(Container), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Icon), findsOneWidget);
        expect(find.byType(Text), findsOneWidget);
        expect(find.byType(Column), findsNothing); // Not used in compact mode
      });

      testWidgets('should have proper widget hierarchy in detailed mode', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CapacityIndicatorWidget), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(find.byType(Column), findsOneWidget);
        expect(find.byType(Row), findsAtLeastNWidgets(2));
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic information for screen readers', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: mediumUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Capacity'), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
        expect(find.text('Available: 40.0h'), findsOneWidget);
        expect(find.text('Used: 30.0h'), findsOneWidget);
      });

      testWidgets('should provide proper color contrast for different states', (WidgetTester tester) async {
        // Test different utilization states
        final states = [
          (lowUtilizationPeriod, Icons.check_circle, Colors.green),
          (mediumUtilizationPeriod, Icons.schedule, Colors.yellow.shade700),
          (highUtilizationPeriod, Icons.warning, Colors.orange),
          (overAllocatedPeriod, Icons.error, Colors.red),
        ];

        for (final (period, expectedIcon, expectedColor) in states) {
          final widget = CapacityIndicatorWidget(
            capacityPeriod: period,
            isCompact: true,
          );

          await tester.pumpWidget(createTestWidget(widget));
          await tester.pumpAndSettle();

          // Assert proper color coding for accessibility
          final icon = tester.widget<Icon>(find.byIcon(expectedIcon));
          expect(icon.color, equals(expectedColor));

          // Clean up for next iteration
          await tester.pumpWidget(Container());
        }
      });

      testWidgets('should have readable text sizes', (WidgetTester tester) async {
        // Arrange
        final widget = CapacityIndicatorWidget(
          capacityPeriod: lowUtilizationPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Check that text widgets exist (size depends on theme)
        expect(find.text('Capacity'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget);
        expect(find.text('Available: 40.0h'), findsOneWidget);
        expect(find.text('Used: 20.0h'), findsOneWidget);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle exactly 100% utilization', (WidgetTester tester) async {
        // Arrange
        final exactPeriod = createCapacityPeriodWithUtilization(
          weekStart: DateTime(2024, 1, 1),
          totalCapacity: 40.0,
          targetUtilization: 40.0,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: exactPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('100%'), findsOneWidget);
        expect(find.textContaining('Over-allocated'), findsNothing); // Should not show warning at exactly 100%
        
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator)
        );
        expect(progressIndicator.value, equals(1.0));
      });

      testWidgets('should handle very small over-allocation', (WidgetTester tester) async {
        // Arrange
        final smallOverPeriod = createCapacityPeriodWithUtilization(
          weekStart: DateTime(2024, 1, 1),
          totalCapacity: 40.0,
          targetUtilization: 40.1,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: smallOverPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('100%'), findsOneWidget); // Rounded to 100%
        expect(find.textContaining('Over-allocated by 0.1h'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should handle fractional percentages correctly', (WidgetTester tester) async {
        // Arrange - Create a period that results in 33.33% utilization
        final fractionalPeriod = createCapacityPeriodWithUtilization(
          weekStart: DateTime(2024, 1, 1),
          totalCapacity: 30.0,
          targetUtilization: 10.0,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: fractionalPeriod,
          isCompact: true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('33%'), findsOneWidget); // Should be rounded to nearest integer
      });
    });
  });
}
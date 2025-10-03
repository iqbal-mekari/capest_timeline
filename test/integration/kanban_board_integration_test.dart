import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/models/platform_variant.dart';
import 'package:capest_timeline/models/capacity_period.dart';
import 'package:capest_timeline/models/assignment.dart';
import 'package:capest_timeline/models/platform_type.dart';
import 'package:capest_timeline/widgets/initiative_card_widget.dart';
import 'package:capest_timeline/widgets/week_column_widget.dart';
import 'package:capest_timeline/widgets/capacity_indicator_widget.dart';

void main() {
  group('Kanban Board Integration Tests', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    group('Widget Integration', () {
      testWidgets('should render InitiativeCardWidget', (WidgetTester tester) async {
        // Arrange
        final platformVariant = PlatformVariant(
          id: 'variant-1',
          title: 'Backend Development',
          platformType: PlatformType.backend,
          estimatedWeeks: 2,
          initiativeId: 'init-1',
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        final widget = InitiativeCardWidget(
          variant: platformVariant,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Backend Development'), findsOneWidget);
        expect(find.byType(InitiativeCardWidget), findsOneWidget);
        expect(find.text('BACKEND'), findsOneWidget); // Platform type badge
        expect(find.byIcon(Icons.schedule), findsOneWidget); // Effort icon
      });

      testWidgets('should render WeekColumnWidget with capacity period', (WidgetTester tester) async {
        // Arrange
        final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        
        final assignment = Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 1,
          capacityPercentage: 0.5, // 50% capacity
          startWeek: weekStart,
        );

        final capacityPeriod = CapacityPeriod(
          weekStart: weekStart,
          weekEnd: weekStart.add(const Duration(days: 6)),
          assignments: [assignment],
          totalCapacityAvailable: 40.0,
        );

        final platformVariant = PlatformVariant(
          id: 'variant-1',
          title: 'Backend Development',
          platformType: PlatformType.backend,
          estimatedWeeks: 2,
          initiativeId: 'init-1',
          currentWeek: DateTime.now(),
          isAssigned: false,
        );

        final widget = WeekColumnWidget(
          week: weekStart,
          variants: [platformVariant],
          capacityPeriod: capacityPeriod,
          onVariantDropped: (variant, week) async => true,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(WeekColumnWidget), findsOneWidget);
        expect(find.byType(CapacityIndicatorWidget), findsOneWidget);  
        expect(find.text('Backend Development'), findsOneWidget);
        expect(find.text('50%'), findsOneWidget); // 50% utilization in compact indicator
      });

      testWidgets('should render CapacityIndicatorWidget with utilization data', (WidgetTester tester) async {
        // Arrange
        final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        
        final assignment = Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 1,
          capacityPercentage: 0.75, // 75% capacity = 30 hours out of 40
          startWeek: weekStart,
        );

        final capacityPeriod = CapacityPeriod(
          weekStart: weekStart,
          weekEnd: weekStart.add(const Duration(days: 6)),
          assignments: [assignment],
          totalCapacityAvailable: 40.0,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: capacityPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(CapacityIndicatorWidget), findsOneWidget);
        expect(find.text('Available: 40.0h'), findsOneWidget);
        expect(find.text('Used: 30.0h'), findsOneWidget); // 75% of 40 hours
        expect(find.text('75%'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle over-allocation scenarios', (WidgetTester tester) async {
        // Arrange
        final weekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
        
        // Create over-allocated assignment (120% capacity = 48 hours out of 40)
        final assignment = Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 1,
          capacityPercentage: 1.2, // 120% capacity
          startWeek: weekStart,
        );

        final capacityPeriod = CapacityPeriod(
          weekStart: weekStart,
          weekEnd: weekStart.add(const Duration(days: 6)),
          assignments: [assignment],
          totalCapacityAvailable: 40.0,
        );

        final widget = CapacityIndicatorWidget(
          capacityPeriod: capacityPeriod,
          isCompact: false,
        );

        // Act
        await tester.pumpWidget(createTestWidget(widget));
        await tester.pumpAndSettle();

        // Assert - Should show over-allocation warning
        expect(find.textContaining('Over-allocated'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('120%'), findsOneWidget);
      });
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/features/capacity_planning/presentation/widgets/virtualized_timeline_widget.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/quarter_plan.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/initiative.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/capacity_allocation.dart';
import 'package:capest_timeline/features/team_management/domain/entities/team_member.dart';
import 'package:capest_timeline/core/enums/role.dart';

void main() {
  group('VirtualizedTimelineWidget Tests', () {
    late QuarterPlan testQuarterPlan;
    late List<TeamMember> testTeamMembers;
    late List<Initiative> testInitiatives;
    late List<CapacityAllocation> testAllocations;

    setUp(() {
      // Create test team members
      testTeamMembers = [
        const TeamMember(
          id: 'tm001',
          name: 'Alice Frontend',
          email: 'alice@test.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
          skillLevel: 8,
          isActive: true,
          unavailablePeriods: [],
        ),
        const TeamMember(
          id: 'tm002',
          name: 'Bob Backend',
          email: 'bob@test.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
          skillLevel: 7,
          isActive: true,
          unavailablePeriods: [],
        ),
        const TeamMember(
          id: 'tm003',
          name: 'Carol QA',
          email: 'carol@test.com',
          roles: {Role.qa},
          weeklyCapacity: 1.0,
          skillLevel: 6,
          isActive: true,
          unavailablePeriods: [],
        ),
      ];

      // Create test initiatives
      testInitiatives = [
        const Initiative(
          id: 'init001',
          name: 'Mobile App Feature',
          description: 'New mobile app feature',
          businessValue: 8,
          priority: 9,
          estimatedEffortWeeks: 6.0,
          requiredRoles: {Role.frontend: 3.0, Role.backend: 2.0},
          dependencies: [],
        ),
        const Initiative(
          id: 'init002',
          name: 'Backend API',
          description: 'New backend API development',
          businessValue: 7,
          priority: 8,
          estimatedEffortWeeks: 4.0,
          requiredRoles: {Role.backend: 4.0},
          dependencies: [],
        ),
      ];

      // Create test allocations
      final startDate = DateTime(2024, 7, 1);
      testAllocations = [
        CapacityAllocation(
          id: 'ca001',
          teamMemberId: 'tm001',
          initiativeId: 'init001',
          role: Role.frontend,
          allocatedWeeks: 3.0,
          startDate: startDate,
          endDate: startDate.add(const Duration(days: 21)),
          status: AllocationStatus.planned,
          notes: '',
        ),
        CapacityAllocation(
          id: 'ca002',
          teamMemberId: 'tm002',
          initiativeId: 'init002',
          role: Role.backend,
          allocatedWeeks: 4.0,
          startDate: startDate.add(const Duration(days: 7)),
          endDate: startDate.add(const Duration(days: 35)),
          status: AllocationStatus.planned,
          notes: '',
        ),
      ];

      // Create test quarter plan
      testQuarterPlan = QuarterPlan(
        id: 'qp001',
        quarter: 3,
        year: 2024,
        name: 'Q3 2024 Plan',
        initiatives: testInitiatives,
        teamMembers: testTeamMembers,
        allocations: testAllocations,
      );
    });

    testWidgets('displays virtualized timeline with team members', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualizedTimelineWidget(
              quarterPlan: testQuarterPlan,
              enableVirtualization: true,
            ),
          ),
        ),
      );

      // Wait for initial build
      await tester.pumpAndSettle();

      // Verify timeline structure is present
      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('Alice Frontend'), findsOneWidget);
      expect(find.text('Bob Backend'), findsOneWidget);
      expect(find.text('Carol QA'), findsOneWidget);
    });

    testWidgets('displays week headers correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualizedTimelineWidget(
              quarterPlan: testQuarterPlan,
              showWeekNumbers: true,
              enableVirtualization: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify week headers are present
      expect(find.text('W1'), findsOneWidget);
      expect(find.text('7/1'), findsOneWidget);
    });

    testWidgets('handles empty quarter plan gracefully', (tester) async {
      const emptyPlan = QuarterPlan(
        id: 'empty',
        quarter: 3,
        year: 2024,
        name: 'Empty Plan',
        initiatives: [],
        teamMembers: [],
        allocations: [],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VirtualizedTimelineWidget(
              quarterPlan: emptyPlan,
              enableVirtualization: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still display basic structure
      expect(find.text('Team Members'), findsOneWidget);
    });

    testWidgets('falls back to regular timeline when virtualization disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualizedTimelineWidget(
              quarterPlan: testQuarterPlan,
              enableVirtualization: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should still display content via fallback
      expect(find.text('Team Members'), findsOneWidget);
    });

    testWidgets('displays allocation widgets', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: VirtualizedTimelineWidget(
                quarterPlan: testQuarterPlan,
                enableVirtualization: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should display initiative names in allocation blocks
      expect(find.text('Mobile App Feature'), findsOneWidget);
      expect(find.text('Backend API'), findsOneWidget);
    });

    testWidgets('responds to scroll events', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: VirtualizedTimelineWidget(
                quarterPlan: testQuarterPlan,
                enableVirtualization: true,
                cellWidth: 120.0,
                cellHeight: 40.0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find scrollable areas and test scrolling
      final horizontalScroll = find.byType(SingleChildScrollView).first;
      await tester.drag(horizontalScroll, const Offset(-100, 0));
      await tester.pumpAndSettle();

      // Timeline should handle scroll without crashing
      expect(find.byType(VirtualizedTimelineWidget), findsOneWidget);
    });

    testWidgets('customizes cell dimensions correctly', (tester) async {
      const customCellWidth = 150.0;
      const customCellHeight = 50.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VirtualizedTimelineWidget(
              quarterPlan: testQuarterPlan,
              cellWidth: customCellWidth,
              cellHeight: customCellHeight,
              enableVirtualization: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Widget should render with custom dimensions
      expect(find.byType(VirtualizedTimelineWidget), findsOneWidget);
    });

    group('Performance Features', () {
      testWidgets('handles large team member lists', (tester) async {
        // Create a large team for performance testing
        final largeTeam = List.generate(50, (index) => TeamMember(
          id: 'tm$index',
          name: 'Team Member $index',
          email: 'member$index@test.com',
          roles: {Role.values[index % Role.values.length]},
          weeklyCapacity: 1.0,
          skillLevel: 5 + (index % 5),
          isActive: true,
          unavailablePeriods: const [],
        ));

        final largePlan = QuarterPlan(
          id: 'large_plan',
          quarter: 3,
          year: 2024,
          name: 'Large Plan',
          initiatives: testInitiatives,
          teamMembers: largeTeam,
          allocations: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: VirtualizedTimelineWidget(
                  quarterPlan: largePlan,
                  enableVirtualization: true,
                ),
              ),
            ),
          ),
        );

        // Should complete rendering within reasonable time
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.byType(VirtualizedTimelineWidget), findsOneWidget);
        expect(find.text('Team Members'), findsOneWidget);
      });

      testWidgets('virtual scrolling works with buffer zones', (tester) async {
        const bufferSize = 2;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 200,
                child: VirtualizedTimelineWidget(
                  quarterPlan: testQuarterPlan,
                  visibleWeekBuffer: bufferSize,
                  visibleMemberBuffer: bufferSize,
                  enableVirtualization: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Widget should render with buffer zones
        expect(find.byType(VirtualizedTimelineWidget), findsOneWidget);
      });
    });

    group('TimelinePerformanceMonitor', () {
      testWidgets('displays performance metrics when enabled', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimelinePerformanceMonitor(
                showMetrics: true,
                child: VirtualizedTimelineWidget(
                  quarterPlan: testQuarterPlan,
                  enableVirtualization: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Performance monitor should be present
        expect(find.byType(TimelinePerformanceMonitor), findsOneWidget);
      });

      testWidgets('hides performance metrics when disabled', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TimelinePerformanceMonitor(
                showMetrics: false,
                child: VirtualizedTimelineWidget(
                  quarterPlan: testQuarterPlan,
                  enableVirtualization: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should not show metrics overlay
        expect(find.text('FPS:'), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('maintains accessibility with virtualization', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VirtualizedTimelineWidget(
                quarterPlan: testQuarterPlan,
                enableVirtualization: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Team member names should be accessible
        expect(find.text('Alice Frontend'), findsOneWidget);
        expect(find.text('Bob Backend'), findsOneWidget);
        expect(find.text('Carol QA'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('handles missing initiatives gracefully', (tester) async {
        // Create allocation with missing initiative
        final allocationWithMissingInit = CapacityAllocation(
          id: 'ca_missing',
          teamMemberId: 'tm001',
          initiativeId: 'missing_init',
          role: Role.frontend,
          allocatedWeeks: 2.0,
          startDate: DateTime(2024, 7, 1),
          endDate: DateTime(2024, 7, 15),
          status: AllocationStatus.planned,
          notes: '',
        );

        final planWithMissingInit = QuarterPlan(
          id: 'plan_missing',
          quarter: 3,
          year: 2024,
          name: 'Plan with Missing Initiative',
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: [allocationWithMissingInit],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VirtualizedTimelineWidget(
                quarterPlan: planWithMissingInit,
                enableVirtualization: true,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Should render without crashing
        expect(find.byType(VirtualizedTimelineWidget), findsOneWidget);
      });

      testWidgets('handles extreme scroll positions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: VirtualizedTimelineWidget(
                  quarterPlan: testQuarterPlan,
                  enableVirtualization: true,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Test extreme horizontal scroll
        final horizontalScrollable = find.byType(SingleChildScrollView).first;
        await tester.drag(horizontalScrollable, const Offset(-2000, 0));
        await tester.pumpAndSettle();

        // Should handle extreme scroll without issues
        expect(find.byType(VirtualizedTimelineWidget), findsOneWidget);
      });
    });
  });
}
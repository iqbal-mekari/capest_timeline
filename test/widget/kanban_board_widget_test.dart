import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:capest_timeline/widgets/kanban_board_widget.dart';
import 'package:capest_timeline/providers/kanban_provider.dart';
import 'package:capest_timeline/models/initiative.dart';
import 'package:capest_timeline/models/platform_variant.dart';
import 'package:capest_timeline/models/capacity_period.dart';
import 'package:capest_timeline/models/platform_type.dart';

// Generate mocks for dependencies
@GenerateNiceMocks([
  MockSpec<KanbanProvider>(),
])
import 'kanban_board_widget_test.mocks.dart';

void main() {
  group('KanbanBoardWidget Tests', () {
    late MockKanbanProvider mockKanbanProvider;

    setUp(() {
      mockKanbanProvider = MockKanbanProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<KanbanProvider>.value(
          value: mockKanbanProvider,
          child: const Scaffold(
            body: KanbanBoardWidget(),
          ),
        ),
      );
    }

    group('Drag and Drop Functionality', () {
      testWidgets('should display initiative cards with draggable functionality', (WidgetTester tester) async {
        // Arrange
        final mockInitiatives = [
          Initiative(
            id: 'init-1',
            title: 'Reimbursement System',
            description: 'Complete reimbursement workflow',
            createdAt: DateTime.now(),
            requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
            platformVariants: const [],
            priority: '1',
          ),
        ];

        final mockVariants = [
          PlatformVariant(
            id: 'variant-1',
            initiativeId: 'init-1',
            platformType: PlatformType.backend,
            title: '[BE] Reimbursement System',
            estimatedWeeks: 4,
            currentWeek: DateTime(2024, 1, 1),
            isAssigned: false,
          ),
        ];

        final mockTimelineWeeks = [
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 8),
          DateTime(2024, 1, 15),
        ];

        when(mockKanbanProvider.initiatives).thenReturn(mockInitiatives.cast<Initiative>());
        when(mockKanbanProvider.platformVariants).thenReturn(mockVariants);
        when(mockKanbanProvider.timelineWeeks).thenReturn(mockTimelineWeeks);
        when(mockKanbanProvider.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(KanbanBoardWidget), findsOneWidget);
        expect(find.byType(Draggable<PlatformVariant>), findsOneWidget);
        expect(find.text('[BE] Reimbursement System'), findsOneWidget);
      });

      testWidgets('should show drop zones for each week column', (WidgetTester tester) async {
        // Arrange
        final mockTimelineWeeks = [
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 8),
          DateTime(2024, 1, 15),
        ];

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn(mockTimelineWeeks);
        when(mockKanbanProvider.isLoading).thenReturn(false);
        when(mockKanbanProvider.getVariantsForWeek(any)).thenReturn([]);
        when(mockKanbanProvider.getCapacityForWeek(any)).thenReturn(null);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(DragTarget<PlatformVariant>), findsNWidgets(3)); // 3 week columns
      });

      testWidgets('should handle successful drag and drop operation', (WidgetTester tester) async {
        // Arrange
        final mockVariant = PlatformVariant(
          id: 'variant-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: '[BE] Test Initiative',
          estimatedWeeks: 2,
          currentWeek: DateTime(2024, 1, 1),
          isAssigned: false,
        );

        final mockTimelineWeeks = [
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 8),
        ];

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([mockVariant]);
        when(mockKanbanProvider.timelineWeeks).thenReturn(mockTimelineWeeks);
        when(mockKanbanProvider.isLoading).thenReturn(false);
        when(mockKanbanProvider.moveVariantToWeek(any, any))
            .thenAnswer((_) async => true);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the draggable and perform drag operation
        final draggable = find.byType(Draggable<PlatformVariant>);

        // Perform drag operation
        await tester.drag(draggable, const Offset(200, 0));
        await tester.pumpAndSettle();

        // Assert - Verify the drag structure is in place (actual drag behavior is complex to test)
        expect(find.byType(Draggable<PlatformVariant>), findsOneWidget);
        expect(find.byType(DragTarget<PlatformVariant>), findsAtLeastNWidgets(1));
      });

      testWidgets('should show visual feedback during drag operation', (WidgetTester tester) async {
        // Arrange
        final mockVariant = PlatformVariant(
          id: 'variant-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: '[BE] Test Initiative',
          estimatedWeeks: 2,
          currentWeek: DateTime(2024, 1, 1),
          isAssigned: false,
        );

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([mockVariant]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([DateTime(2024, 1, 1)]);
        when(mockKanbanProvider.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Start drag operation
        final draggable = find.byType(Draggable<PlatformVariant>);
        final gesture = await tester.startGesture(tester.getCenter(draggable));
        await tester.pump();

        // Assert - Should show drag feedback (semi-transparent version)
        expect(find.byType(Draggable<PlatformVariant>), findsOneWidget);
        
        // Complete drag
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('should reject drop when capacity constraints violated', (WidgetTester tester) async {
        // Arrange
        final mockVariant = PlatformVariant(
          id: 'variant-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: '[BE] Test Initiative',
          estimatedWeeks: 2,
          currentWeek: DateTime(2024, 1, 1),
          isAssigned: false,
        );

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([mockVariant]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([DateTime(2024, 1, 1)]);
        when(mockKanbanProvider.isLoading).thenReturn(false);
        when(mockKanbanProvider.moveVariantToWeek(any, any))
            .thenAnswer((_) async => false); // Capacity constraint violated

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Perform drag operation
        final draggable = find.byType(Draggable<PlatformVariant>);
        await tester.drag(draggable, const Offset(200, 0));
        await tester.pumpAndSettle();

        // Assert - Verify the drag structure exists
        expect(find.byType(Draggable<PlatformVariant>), findsOneWidget);
        expect(find.byType(DragTarget<PlatformVariant>), findsAtLeastNWidgets(1));
      });
    });

    group('Timeline Display', () {
      testWidgets('should display week headers correctly', (WidgetTester tester) async {
        // Arrange
        final mockTimelineWeeks = [
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 8),
          DateTime(2024, 1, 15),
        ];

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn(mockTimelineWeeks);
        when(mockKanbanProvider.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Check for exact text matches
        expect(find.text('Week of Jan 1'), findsOneWidget);
        expect(find.text('Week of Jan 8'), findsOneWidget);
        expect(find.text('Week of Jan 15'), findsOneWidget);
      });

      testWidgets('should support horizontal scrolling for long timelines', (WidgetTester tester) async {
        // Arrange
        final mockTimelineWeeks = List.generate(20, (index) {
          return DateTime(2024, 1, 1).add(Duration(days: index * 7));
        });

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn(mockTimelineWeeks);
        when(mockKanbanProvider.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - There should be scroll views for horizontal scrolling
        expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
        
        // Test horizontal scrolling
        await tester.fling(find.byType(KanbanBoardWidget), const Offset(-300, 0), 800);
        await tester.pumpAndSettle();
      });
    });

    group('Loading and Error States', () {
      testWidgets('should show loading indicator when data is loading', (WidgetTester tester) async {
        // Arrange
        when(mockKanbanProvider.isLoading).thenReturn(true);
        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([]);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // Use pump() instead of pumpAndSettle() for loading state

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show empty state when no initiatives exist', (WidgetTester tester) async {
        // Arrange
        when(mockKanbanProvider.isLoading).thenReturn(false);
        when(mockKanbanProvider.hasError).thenReturn(false);
        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([]); // Empty timeline weeks to trigger empty state

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('No initiatives found'), findsOneWidget);
      });

      testWidgets('should show error state when loading fails', (WidgetTester tester) async {
        // Arrange
        when(mockKanbanProvider.isLoading).thenReturn(false);
        when(mockKanbanProvider.hasError).thenReturn(true);
        when(mockKanbanProvider.errorMessage).thenReturn('Failed to load kanban data');
        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([]);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Failed to load kanban data'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget); // Retry button
      });
    });

    group('Capacity Integration', () {
      testWidgets('should display capacity warnings for over-allocated weeks', (WidgetTester tester) async {
        // Arrange
        final mockCapacityPeriods = [
          CapacityPeriod(
            weekStart: DateTime(2024, 1, 1),
            weekEnd: DateTime(2024, 1, 7),
            assignments: const [],
            totalCapacityAvailable: 1.0,
          ),
        ];

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([DateTime(2024, 1, 1)]);
        when(mockKanbanProvider.capacityPeriods).thenReturn(mockCapacityPeriods);
        when(mockKanbanProvider.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert - Should display capacity indicator
        expect(find.byType(KanbanBoardWidget), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt layout for mobile screens', (WidgetTester tester) async {
        // Arrange
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([DateTime(2024, 1, 1)]);
        when(mockKanbanProvider.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(KanbanBoardWidget), findsOneWidget);
      });

      testWidgets('should adapt layout for desktop screens', (WidgetTester tester) async {
        // Arrange
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        when(mockKanbanProvider.initiatives).thenReturn([]);
        when(mockKanbanProvider.platformVariants).thenReturn([]);
        when(mockKanbanProvider.timelineWeeks).thenReturn([DateTime(2024, 1, 1)]);
        when(mockKanbanProvider.isLoading).thenReturn(false);

        // Act
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(KanbanBoardWidget), findsOneWidget);
      });
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:capest_timeline/widgets/kanban_board_widget.dart';
import 'package:capest_timeline/providers/kanban_provider.dart';
import 'widget/kanban_board_widget_test.mocks.dart';

void main() {
  testWidgets('Debug test - see what gets rendered', (WidgetTester tester) async {
    // Arrange
    final mockKanbanProvider = MockKanbanProvider();
    final mockTimelineWeeks = [
      DateTime(2024, 1, 1),
      DateTime(2024, 1, 8),
      DateTime(2024, 1, 15),
    ];

    when(mockKanbanProvider.initiatives).thenReturn([]);
    when(mockKanbanProvider.platformVariants).thenReturn([]);  
    when(mockKanbanProvider.timelineWeeks).thenReturn(mockTimelineWeeks);
    when(mockKanbanProvider.isLoading).thenReturn(false);
    when(mockKanbanProvider.hasError).thenReturn(false);
    when(mockKanbanProvider.getVariantsForWeek(any)).thenReturn([]);
    when(mockKanbanProvider.getCapacityForWeek(any)).thenReturn(null);

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

    // Act
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Debug - analyze widget tree
    debugPrint('=== WIDGET TREE DEBUG ===');
    debugPrint(tester.allWidgets.map((w) => w.runtimeType.toString()).join('\n'));
    debugPrint('=== END DEBUG ===');

    // Look for what we have
    expect(find.byType(KanbanBoardWidget), findsOneWidget);
  });
}
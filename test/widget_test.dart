// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:capest_timeline/main.dart';

void main() {
  testWidgets('Capacity Timeline app starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CapacityTimelineApp());

    // Wait for initialization to complete
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('Capacity Timeline'), findsOneWidget);

    // Verify that navigation destinations are present
    expect(find.text('Planning'), findsOneWidget);
    expect(find.text('Team'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}

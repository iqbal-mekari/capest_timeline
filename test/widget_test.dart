// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic app smoke test', (WidgetTester tester) async {
    // Build a simple counter app to verify Flutter testing works
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Test App'),
          ),
          body: const Center(
            child: Text('Welcome to Capacity Timeline'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );

    // Verify that our test widget renders correctly
    expect(find.text('Test App'), findsOneWidget);
    expect(find.text('Welcome to Capacity Timeline'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}

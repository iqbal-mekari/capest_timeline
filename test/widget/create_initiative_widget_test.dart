import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:capest_timeline/widgets/create_initiative_widget.dart';
import 'package:capest_timeline/providers/kanban_provider.dart';
import 'package:capest_timeline/services/kanban_service.dart';

import 'package:capest_timeline/services/storage_service.dart';
import 'package:capest_timeline/models/models.dart';

void main() {
  group('CreateInitiativeWidget Tests', () {
    late KanbanProvider testProvider;

    setUp(() {
      // Create test provider with minimal mock services using noSuchMethod
      testProvider = KanbanProvider(
        kanbanService: TestKanbanService(),
        storageService: TestStorageService(),
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600, // Constrain height for testing
            child: ChangeNotifierProvider<KanbanProvider>(
              create: (_) => testProvider,
              child: const CreateInitiativeWidget(),
            ),
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render essential form elements', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for main form elements
        expect(find.text('Initiative Title'), findsOneWidget);
        expect(find.text('Description'), findsOneWidget);
        expect(find.text('Platform Variants'), findsOneWidget);

        // Check for platform checkboxes
        expect(find.text('Backend'), findsOneWidget);
        expect(find.text('Frontend'), findsOneWidget);
        expect(find.text('Mobile'), findsOneWidget);
        expect(find.text('QA'), findsOneWidget);
      });

      testWidgets('should have proper form structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for form widget
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(2));

        // Check for checkboxes
        expect(find.byType(CheckboxListTile), findsNWidgets(4));

        // Check for submit button
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Platform Selection', () {
      testWidgets('should show weeks input when platform is selected', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Initially no weeks input should be visible
        expect(find.text('Backend Estimated Weeks'), findsNothing);

        // Select Backend platform
        await tester.tap(find.text('Backend'));
        await tester.pumpAndSettle();

        // Now weeks input should be visible
        expect(find.text('Backend Estimated Weeks'), findsOneWidget);
      });

      testWidgets('should show preview when platform is selected', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter title first
        await tester.enterText(find.widgetWithText(TextFormField, 'Initiative Title'), 'Test Initiative');
        await tester.pumpAndSettle();

        // Select Backend platform
        await tester.tap(find.text('Backend'));
        await tester.pumpAndSettle();

        // Should show preview section
        expect(find.textContaining('platform variants will be created'), findsOneWidget);
        expect(find.text('[BE] Test Initiative'), findsOneWidget);
      });
    });

    group('Form Fields', () {
      testWidgets('should accept text input in form fields', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Enter title
        await tester.enterText(find.widgetWithText(TextFormField, 'Initiative Title'), 'Test Initiative');
        await tester.pumpAndSettle();

        // Verify title was entered
        expect(find.text('Test Initiative'), findsOneWidget);

        // Enter description
        await tester.enterText(find.widgetWithText(TextFormField, 'Description'), 'Test Description');
        await tester.pumpAndSettle();

        // Verify description was entered
        expect(find.text('Test Description'), findsOneWidget);
      });
    });

    group('Interactive Elements', () {
      testWidgets('should toggle platform checkboxes', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Find the Backend checkbox
        final backendCheckbox = find.text('Backend');
        expect(backendCheckbox, findsOneWidget);

        // Tap to select Backend
        await tester.tap(backendCheckbox);
        await tester.pumpAndSettle();

        // Should show weeks input field
        expect(find.text('Backend Estimated Weeks'), findsOneWidget);

        // Tap again to deselect
        await tester.tap(backendCheckbox);
        await tester.pumpAndSettle();

        // Weeks input should be gone
        expect(find.text('Backend Estimated Weeks'), findsNothing);
      });
    });

    group('Widget Structure', () {
      testWidgets('should have proper widget hierarchy', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Check for proper widget structure
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(Column), findsWidgets);
        expect(find.byType(Semantics), findsWidgets);
      });
    });
  });
}

// Mock services using noSuchMethod to handle all interface methods
class TestKanbanService implements KanbanService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return appropriate default values based on return type
    if (invocation.memberName == #createInitiative) {
      return Future.value(Initiative(
        id: 'test-id',
        title: 'Test Initiative',
        description: 'Test Description',
        createdAt: DateTime.now(),
        platformVariants: const [],
        requiredPlatforms: const [],
      ));
    }
    return super.noSuchMethod(invocation);
  }
}



class TestStorageService implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return appropriate default values based on method
    if (invocation.memberName == #loadData) {
      return Future.value(null);
    }
    if (invocation.memberName == #hasData) {
      return Future.value(false);
    }
    // For void methods, return null
    return super.noSuchMethod(invocation);
  }
}
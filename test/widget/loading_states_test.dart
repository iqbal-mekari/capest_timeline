import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/shared/widgets/loading_states.dart';

void main() {
  group('Loading States Tests', () {
         // Verify shimmer is applied
        expect(find.byType(AnimatedBuilder), findsWidgets); testWidgets('CTALoadingIndicator displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CTALoadingIndicator(
              message: 'Loading test data...',
              size: 32.0,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading test data...'), findsOneWidget);
    });

    testWidgets('CTAPageLoading displays full screen loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CTAPageLoading(
            message: 'Initializing application...',
          ),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing application...'), findsOneWidget);
    });

    testWidgets('CTAEmptyState displays with action button', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CTAEmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'No items found in your inbox',
              actionLabel: 'Add Item',
              onAction: () {
                actionCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('No items found in your inbox'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      expect(actionCalled, true);
    });

    testWidgets('CTAErrorState displays with retry functionality', (tester) async {
      bool retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CTAErrorState(
              title: 'Connection Failed',
              message: 'Unable to connect to server',
              onRetry: () {
                retryCalled = true;
              },
              retryLabel: 'Try Again',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Connection Failed'), findsOneWidget);
      expect(find.text('Unable to connect to server'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryCalled, true);
    });

    testWidgets('CTASkeletonLoader displays multiple skeleton items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CTASkeletonLoader(
              itemCount: 3,
              itemHeight: 100.0,
            ),
          ),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
      // Should find skeleton items (cards with shimmer effect)
      expect(find.byType(Card), findsNWidgets(3));
    });

    testWidgets('CTATimelineLoader displays timeline skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CTATimelineLoader(
              weekCount: 4,
              memberCount: 2,
            ),
          ),
        ),
      );

      // Should display timeline structure with shimmer effects
      expect(find.byType(CTAShimmer), findsWidgets);
    });

    testWidgets('CTAInlineLoader displays with message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CTAInlineLoader(
              size: 20.0,
              message: 'Saving...',
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Saving...'), findsOneWidget);
    });

    testWidgets('CTALoadingOverlay shows and hides correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CTALoadingOverlay(
              isLoading: true,
              message: 'Processing...',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Processing...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Test with loading disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CTALoadingOverlay(
              isLoading: false,
              message: 'Processing...',
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Processing...'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('CTACardLoader displays customizable skeleton', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CTACardLoader(
              width: 200,
              height: 150,
              hasAvatar: true,
              hasTitle: true,
              hasSubtitle: true,
              hasActions: true,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(CTAShimmer), findsOneWidget);
    });

    testWidgets('CTAShimmer animation works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CTAShimmer(
              enabled: true,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      // Verify shimmer is applied
      expect(find.byType(AnimatedBuilder), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);

      // Test with shimmer disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CTAShimmer(
              enabled: false,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      // Should not have shimmer when disabled
      expect(find.byType(ShaderMask), findsNothing);
    });

    group('Loading State Animations', () {
      testWidgets('Skeleton items animate correctly', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CTASkeletonLoader(itemCount: 1),
            ),
          ),
        );

        // Pump several frames to test animation
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 1000));

        // Animation should be running
        expect(find.byType(AnimatedBuilder), findsWidgets);
      });

      testWidgets('Shimmer effect cycles correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CTAShimmer(
                child: Container(
                  width: 100,
                  height: 50,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
        );

        // Test animation cycle
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 750)); // Half cycle
        await tester.pump(const Duration(milliseconds: 750)); // Full cycle

        expect(find.byType(ShaderMask), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('Loading indicators have proper semantics', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CTALoadingIndicator(
                message: 'Loading content for screen reader',
              ),
            ),
          ),
        );

        // Check that loading message is accessible
        expect(find.text('Loading content for screen reader'), findsOneWidget);
      });

      testWidgets('Empty state actions are accessible', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CTAEmptyState(
                icon: Icons.inbox,
                title: 'Empty Inbox',
                message: 'No messages to display',
                actionLabel: 'Compose Message',
                onAction: () {},
              ),
            ),
          ),
        );

        final button = find.byType(ElevatedButton);
        expect(button, findsWidgets);
        
        // Verify button is focusable and has proper label
        expect(find.text('Compose Message'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('Loading states handle null values gracefully', (tester) async {
        // Test CTALoadingIndicator without message
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CTALoadingIndicator(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byType(Text), findsNothing); // No message text
      });

      testWidgets('Empty state works without action', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: CTAEmptyState(
                icon: Icons.folder_open,
                title: 'Empty Folder',
                message: 'This folder is empty',
                // No action provided
              ),
            ),
          ),
        );

        expect(find.text('Empty Folder'), findsOneWidget);
        expect(find.text('This folder is empty'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsNothing);
      });
    });
  });
}
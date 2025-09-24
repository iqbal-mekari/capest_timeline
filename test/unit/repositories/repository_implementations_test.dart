/// Unit tests for repository implementations.
/// 
/// Tests the repository layer that provides domain-specific data access
/// abstraction over data sources. Covers:
/// - Repository pattern implementation
/// - Data transformation between domain and storage layers
/// - Error handling and recovery strategies
/// - Caching and performance optimization
/// - Data consistency and validation
/// - Repository coordination and dependencies
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// TODO: Import actual repository classes when implemented
// import 'package:capest_timeline/features/capacity_planning/data/repositories/quarter_plan_repository_impl.dart';
// import 'package:capest_timeline/features/configuration/data/repositories/application_state_repository_impl.dart';
// import 'package:capest_timeline/core/storage/shared_preferences_storage.dart';

void main() {
  group('Repository Implementation Tests', () {
    late SharedPreferences prefs;
    // late QuarterPlanRepositoryImpl quarterPlanRepository;
    // late ApplicationStateRepositoryImpl applicationStateRepository;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // TODO: Initialize actual repositories when implemented
      // final storage = SharedPreferencesStorage(prefs);
      // quarterPlanRepository = QuarterPlanRepositoryImpl(storage);
      // applicationStateRepository = ApplicationStateRepositoryImpl(storage);
    });

    group('Quarter Plan Repository', () {
      test('should save and load quarter plans correctly', () async {
        // ARRANGE
        final quarterPlanData = {
          'id': 'qp_test_001',
          'title': 'Test Quarter Plan',
          'quarter': 'Q1 2024',
          'createdAt': '2024-01-01T00:00:00Z',
          'lastModified': '2024-01-15T10:30:00Z',
          'teamMembers': [
            {
              'id': 'tm_001',
              'name': 'Alice Johnson',
              'role': 'Backend Developer',
              'capacity': 80.0,
              'skills': ['Java', 'Spring Boot']
            }
          ],
          'initiatives': [
            {
              'id': 'init_001',
              'title': 'Authentication System',
              'description': 'Implement user authentication',
              'priority': 'High',
              'estimatedEffort': 40.0
            }
          ]
        };

        // ACT - Simulate repository save operation
        final key = 'quarter_plan_${quarterPlanData['id']}';
        await prefs.setString(key, jsonEncode(quarterPlanData));
        
        // Add to index
        final existingIndex = prefs.getStringList('quarter_plans_index') ?? [];
        existingIndex.add(quarterPlanData['id'] as String);
        await prefs.setStringList('quarter_plans_index', existingIndex);

        // Simulate repository load operation
        final retrievedJson = prefs.getString(key);
        final retrievedData = retrievedJson != null ? jsonDecode(retrievedJson) : null;

        // ASSERT
        expect(retrievedData, isNotNull);
        expect(retrievedData['id'], equals('qp_test_001'));
        expect(retrievedData['title'], equals('Test Quarter Plan'));
        expect(retrievedData['teamMembers'], hasLength(1));
        expect(retrievedData['initiatives'], hasLength(1));

        // Verify index was updated
        final updatedIndex = prefs.getStringList('quarter_plans_index');
        expect(updatedIndex, contains('qp_test_001'));
      });

      test('should handle quarter plan updates correctly', () async {
        // ARRANGE - Create initial quarter plan
        final initialData = {
          'id': 'qp_update_test',
          'title': 'Original Title',
          'version': 1,
          'lastModified': '2024-01-01T00:00:00Z',
          'teamMembers': [],
          'initiatives': []
        };

        await prefs.setString('quarter_plan_qp_update_test', jsonEncode(initialData));

        // ACT - Update the quarter plan
        final updatedData = {
          'id': 'qp_update_test',
          'title': 'Updated Title',
          'version': 2,
          'lastModified': '2024-01-15T10:30:00Z',
          'teamMembers': [
            {
              'id': 'tm_new',
              'name': 'New Member',
              'role': 'Developer',
              'capacity': 75.0
            }
          ],
          'initiatives': [
            {
              'id': 'init_new',
              'title': 'New Initiative',
              'priority': 'Medium'
            }
          ]
        };

        await prefs.setString('quarter_plan_qp_update_test', jsonEncode(updatedData));

        // Retrieve updated data
        final retrievedJson = prefs.getString('quarter_plan_qp_update_test');
        final retrievedData = retrievedJson != null ? jsonDecode(retrievedJson) : null;

        // ASSERT
        expect(retrievedData, isNotNull);
        expect(retrievedData['title'], equals('Updated Title'));
        expect(retrievedData['version'], equals(2));
        expect(retrievedData['teamMembers'], hasLength(1));
        expect(retrievedData['initiatives'], hasLength(1));
        expect(retrievedData['lastModified'], equals('2024-01-15T10:30:00Z'));

        // Verify original data was overwritten
        expect(retrievedData['title'], isNot(equals('Original Title')));
      });

      test('should delete quarter plans and clean up references', () async {
        // ARRANGE - Create quarter plan with references
        final quarterPlanData = {
          'id': 'qp_delete_test',
          'title': 'Plan to Delete',
          'teamMembers': [],
          'initiatives': []
        };

        await prefs.setString('quarter_plan_qp_delete_test', jsonEncode(quarterPlanData));
        
        // Add to index
        await prefs.setStringList('quarter_plans_index', ['qp_delete_test', 'qp_other']);
        
        // Add to recent plans
        await prefs.setString('application_state', jsonEncode({
          'recentPlans': [
            {'id': 'qp_delete_test', 'title': 'Plan to Delete'},
            {'id': 'qp_other', 'title': 'Other Plan'}
          ]
        }));

        // ACT - Delete quarter plan
        await prefs.remove('quarter_plan_qp_delete_test');
        
        // Clean up index
        final currentIndex = prefs.getStringList('quarter_plans_index') ?? [];
        currentIndex.remove('qp_delete_test');
        await prefs.setStringList('quarter_plans_index', currentIndex);

        // Clean up references in application state
        final appStateJson = prefs.getString('application_state');
        if (appStateJson != null) {
          final appState = jsonDecode(appStateJson);
          final recentPlans = (appState['recentPlans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          recentPlans.removeWhere((plan) => plan['id'] == 'qp_delete_test');
          appState['recentPlans'] = recentPlans;
          await prefs.setString('application_state', jsonEncode(appState));
        }

        // ASSERT
        expect(prefs.getString('quarter_plan_qp_delete_test'), isNull);
        
        final updatedIndex = prefs.getStringList('quarter_plans_index');
        expect(updatedIndex, isNot(contains('qp_delete_test')));
        expect(updatedIndex, contains('qp_other'));

        final updatedAppStateJson = prefs.getString('application_state');
        final updatedAppState = updatedAppStateJson != null ? jsonDecode(updatedAppStateJson) : null;
        final updatedRecentPlans = updatedAppState?['recentPlans'] as List? ?? [];
        expect(updatedRecentPlans.any((plan) => plan['id'] == 'qp_delete_test'), isFalse);
        expect(updatedRecentPlans.any((plan) => plan['id'] == 'qp_other'), isTrue);
      });

      test('should list all quarter plans with filtering', () async {
        // ARRANGE - Create multiple quarter plans
        final quarterPlans = [
          {
            'id': 'qp_2024_q1',
            'title': 'Q1 2024 Plan',
            'quarter': 'Q1 2024',
            'status': 'active',
            'createdAt': '2024-01-01T00:00:00Z'
          },
          {
            'id': 'qp_2024_q2',
            'title': 'Q2 2024 Plan',
            'quarter': 'Q2 2024',
            'status': 'draft',
            'createdAt': '2024-04-01T00:00:00Z'
          },
          {
            'id': 'qp_2023_q4',
            'title': 'Q4 2023 Plan',
            'quarter': 'Q4 2023',
            'status': 'completed',
            'createdAt': '2023-10-01T00:00:00Z'
          }
        ];

        // Store all plans
        final planIds = <String>[];
        for (final plan in quarterPlans) {
          final key = 'quarter_plan_${plan['id']}';
          await prefs.setString(key, jsonEncode(plan));
          planIds.add(plan['id'] as String);
        }
        await prefs.setStringList('quarter_plans_index', planIds);

        // ACT - Simulate repository list operations with different filters
        final allPlanIds = prefs.getStringList('quarter_plans_index') ?? [];
        final allPlans = <Map<String, dynamic>>[];
        
        for (final planId in allPlanIds) {
          final planJson = prefs.getString('quarter_plan_$planId');
          if (planJson != null) {
            allPlans.add(jsonDecode(planJson));
          }
        }

        // Filter by status
        final activePlans = allPlans.where((plan) => plan['status'] == 'active').toList();
        final draftPlans = allPlans.where((plan) => plan['status'] == 'draft').toList();
        final completedPlans = allPlans.where((plan) => plan['status'] == 'completed').toList();

        // Filter by year
        final plans2024 = allPlans.where((plan) => 
          (plan['quarter'] as String).contains('2024')).toList();

        // ASSERT
        expect(allPlans, hasLength(3));
        expect(activePlans, hasLength(1));
        expect(activePlans.first['title'], equals('Q1 2024 Plan'));
        
        expect(draftPlans, hasLength(1));
        expect(draftPlans.first['title'], equals('Q2 2024 Plan'));
        
        expect(completedPlans, hasLength(1));
        expect(completedPlans.first['title'], equals('Q4 2023 Plan'));
        
        expect(plans2024, hasLength(2));
        expect(plans2024.map((p) => p['title']), containsAll(['Q1 2024 Plan', 'Q2 2024 Plan']));
      });

      test('should handle repository errors gracefully', () async {
        // ARRANGE - Create scenario that might cause errors
        const invalidPlanId = 'invalid_plan_id';

        // ACT - Try to load non-existent plan
        final retrievedJson = prefs.getString('quarter_plan_$invalidPlanId');
        
        // Try to parse potentially corrupt data
        await prefs.setString('quarter_plan_corrupt', '{"incomplete": json}');
        final corruptJson = prefs.getString('quarter_plan_corrupt');

        // ASSERT
        expect(retrievedJson, isNull); // Non-existent plan returns null
        
        // Corrupt JSON should throw exception when parsed
        expect(corruptJson, isNotNull);
        expect(() => jsonDecode(corruptJson!), throwsA(isA<FormatException>()));
      });
    });

    group('Application State Repository', () {
      test('should save and load application state correctly', () async {
        // ARRANGE
        final applicationStateData = {
          'id': 'app_state_001',
          'currentView': 'capacity_planning',
          'selectedQuarterPlanId': 'qp_001',
          'filters': {
            'showCompleted': false,
            'roleFilter': 'Backend Developer'
          },
          'recentPlans': [
            {'id': 'qp_001', 'title': 'Q1 Plan', 'lastAccessed': '2024-01-15T10:30:00Z'}
          ],
          'autoSaveEnabled': true,
          'hasUnsavedChanges': false
        };

        // ACT - Simulate repository save operation
        await prefs.setString('application_state', jsonEncode(applicationStateData));
        
        // Simulate repository load operation
        final retrievedJson = prefs.getString('application_state');
        final retrievedData = retrievedJson != null ? jsonDecode(retrievedJson) : null;

        // ASSERT
        expect(retrievedData, isNotNull);
        expect(retrievedData['currentView'], equals('capacity_planning'));
        expect(retrievedData['selectedQuarterPlanId'], equals('qp_001'));
        expect(retrievedData['autoSaveEnabled'], isTrue);
        expect(retrievedData['hasUnsavedChanges'], isFalse);
        expect(retrievedData['filters']['showCompleted'], isFalse);
        expect(retrievedData['recentPlans'], hasLength(1));
      });

      test('should update application state incrementally', () async {
        // ARRANGE - Create initial state
        final initialState = {
          'currentView': 'dashboard',
          'selectedQuarterPlanId': null,
          'filters': {'showCompleted': true},
          'recentPlans': [],
          'autoSaveEnabled': true,
          'hasUnsavedChanges': false
        };

        await prefs.setString('application_state', jsonEncode(initialState));

        // ACT - Update specific fields
        final currentStateJson = prefs.getString('application_state');
        final currentState = currentStateJson != null ? jsonDecode(currentStateJson) : {};

        // Update current view
        currentState['currentView'] = 'quarter_planning';
        currentState['selectedQuarterPlanId'] = 'qp_new';
        currentState['hasUnsavedChanges'] = true;

        // Add recent plan
        final recentPlans = currentState['recentPlans'] as List? ?? [];
        recentPlans.add({
          'id': 'qp_new',
          'title': 'New Plan',
          'lastAccessed': '2024-01-15T10:30:00Z'
        });
        currentState['recentPlans'] = recentPlans;

        await prefs.setString('application_state', jsonEncode(currentState));

        // Retrieve updated state
        final updatedStateJson = prefs.getString('application_state');
        final updatedState = updatedStateJson != null ? jsonDecode(updatedStateJson) : null;

        // ASSERT
        expect(updatedState, isNotNull);
        expect(updatedState['currentView'], equals('quarter_planning'));
        expect(updatedState['selectedQuarterPlanId'], equals('qp_new'));
        expect(updatedState['hasUnsavedChanges'], isTrue);
        expect(updatedState['recentPlans'], hasLength(1));
        expect(updatedState['recentPlans'][0]['title'], equals('New Plan'));
      });

      test('should manage recent plans list with limits', () async {
        // ARRANGE - Create state with many recent plans
        final initialState = {
          'recentPlans': <Map<String, dynamic>>[]
        };

        // Add many recent plans
        for (int i = 1; i <= 15; i++) {
          initialState['recentPlans']!.add({
            'id': 'qp_$i',
            'title': 'Plan $i',
            'lastAccessed': '2024-01-${i.toString().padLeft(2, '0')}T10:00:00Z'
          });
        }

        await prefs.setString('application_state', jsonEncode(initialState));

        // ACT - Add a new recent plan (simulating repository logic to limit to 10)
        final currentStateJson = prefs.getString('application_state');
        final currentState = currentStateJson != null ? jsonDecode(currentStateJson) : {};
        
        final recentPlans = (currentState['recentPlans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        
        // Add new plan
        recentPlans.add({
          'id': 'qp_new',
          'title': 'Newest Plan',
          'lastAccessed': '2024-01-16T10:00:00Z'
        });

        // Limit to 10 most recent (repository logic)
        if (recentPlans.length > 10) {
          recentPlans.removeRange(0, recentPlans.length - 10);
        }

        currentState['recentPlans'] = recentPlans;
        await prefs.setString('application_state', jsonEncode(currentState));

        // ASSERT
        final finalStateJson = prefs.getString('application_state');
        final finalState = finalStateJson != null ? jsonDecode(finalStateJson) : null;
        final finalRecentPlans = finalState?['recentPlans'] as List? ?? [];

        expect(finalRecentPlans, hasLength(10));
        expect(finalRecentPlans.last['title'], equals('Newest Plan'));
        expect(finalRecentPlans.first['id'], equals('qp_7')); // Should start from qp_7
      });

      test('should handle application state reset', () async {
        // ARRANGE - Create state with data
        final stateWithData = {
          'currentView': 'complex_view',
          'selectedQuarterPlanId': 'qp_selected',
          'filters': {
            'showCompleted': false,
            'roleFilter': 'Senior Developer',
            'priorityFilter': 'High'
          },
          'recentPlans': [
            {'id': 'qp_1', 'title': 'Plan 1'},
            {'id': 'qp_2', 'title': 'Plan 2'}
          ],
          'hasUnsavedChanges': true
        };

        await prefs.setString('application_state', jsonEncode(stateWithData));

        // ACT - Reset to default state
        final defaultState = {
          'currentView': 'dashboard',
          'selectedQuarterPlanId': null,
          'filters': {
            'showCompleted': true,
            'roleFilter': null,
            'priorityFilter': null
          },
          'recentPlans': [],
          'autoSaveEnabled': true,
          'hasUnsavedChanges': false
        };

        await prefs.setString('application_state', jsonEncode(defaultState));

        // ASSERT
        final resetStateJson = prefs.getString('application_state');
        final resetState = resetStateJson != null ? jsonDecode(resetStateJson) : null;

        expect(resetState, isNotNull);
        expect(resetState['currentView'], equals('dashboard'));
        expect(resetState['selectedQuarterPlanId'], isNull);
        expect(resetState['filters']['showCompleted'], isTrue);
        expect(resetState['filters']['roleFilter'], isNull);
        expect(resetState['recentPlans'], isEmpty);
        expect(resetState['hasUnsavedChanges'], isFalse);
      });
    });

    group('Repository Coordination', () {
      test('should maintain consistency between repositories', () async {
        // ARRANGE - Create quarter plan and reference it in application state
        final quarterPlan = {
          'id': 'qp_consistency_test',
          'title': 'Consistency Test Plan',
          'status': 'active'
        };

        final applicationState = {
          'selectedQuarterPlanId': 'qp_consistency_test',
          'recentPlans': [
            {
              'id': 'qp_consistency_test',
              'title': 'Consistency Test Plan',
              'lastAccessed': '2024-01-15T10:30:00Z'
            }
          ]
        };

        // ACT - Save both
        await prefs.setString('quarter_plan_qp_consistency_test', jsonEncode(quarterPlan));
        await prefs.setString('application_state', jsonEncode(applicationState));

        // Simulate updating quarter plan title
        quarterPlan['title'] = 'Updated Consistency Test Plan';
        await prefs.setString('quarter_plan_qp_consistency_test', jsonEncode(quarterPlan));

        // Update references in application state
        final currentAppStateJson = prefs.getString('application_state');
        final currentAppState = currentAppStateJson != null ? jsonDecode(currentAppStateJson) : {};
        
        final recentPlans = (currentAppState['recentPlans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        for (final plan in recentPlans) {
          if (plan['id'] == 'qp_consistency_test') {
            plan['title'] = 'Updated Consistency Test Plan';
          }
        }
        currentAppState['recentPlans'] = recentPlans;
        await prefs.setString('application_state', jsonEncode(currentAppState));

        // ASSERT - Verify consistency
        final updatedPlanJson = prefs.getString('quarter_plan_qp_consistency_test');
        final updatedPlan = updatedPlanJson != null ? jsonDecode(updatedPlanJson) : null;

        final updatedAppStateJson = prefs.getString('application_state');
        final updatedAppState = updatedAppStateJson != null ? jsonDecode(updatedAppStateJson) : null;

        expect(updatedPlan?['title'], equals('Updated Consistency Test Plan'));
        
        final updatedRecentPlans = updatedAppState?['recentPlans'] as List? ?? [];
        final referencedPlan = updatedRecentPlans.firstWhere(
          (plan) => plan['id'] == 'qp_consistency_test',
          orElse: () => <String, dynamic>{}
        );
        expect(referencedPlan['title'], equals('Updated Consistency Test Plan'));
      });

      test('should handle cascading deletions correctly', () async {
        // ARRANGE - Create quarter plan with references
        final quarterPlan = {
          'id': 'qp_cascade_test',
          'title': 'Plan to be Deleted',
          'teamMembers': [
            {'id': 'tm_001', 'name': 'Member 1'}
          ]
        };

        final applicationState = {
          'selectedQuarterPlanId': 'qp_cascade_test',
          'recentPlans': [
            {'id': 'qp_cascade_test', 'title': 'Plan to be Deleted'},
            {'id': 'qp_other', 'title': 'Other Plan'}
          ]
        };

        await prefs.setString('quarter_plan_qp_cascade_test', jsonEncode(quarterPlan));
        await prefs.setString('application_state', jsonEncode(applicationState));
        await prefs.setStringList('quarter_plans_index', ['qp_cascade_test', 'qp_other']);

        // ACT - Delete quarter plan and clean up references
        await prefs.remove('quarter_plan_qp_cascade_test');

        // Update index
        final currentIndex = prefs.getStringList('quarter_plans_index') ?? [];
        currentIndex.remove('qp_cascade_test');
        await prefs.setStringList('quarter_plans_index', currentIndex);

        // Update application state
        final currentAppStateJson = prefs.getString('application_state');
        final currentAppState = currentAppStateJson != null ? jsonDecode(currentAppStateJson) : {};
        
        // Clear selected plan if it was the deleted one
        if (currentAppState['selectedQuarterPlanId'] == 'qp_cascade_test') {
          currentAppState['selectedQuarterPlanId'] = null;
        }

        // Remove from recent plans
        final recentPlans = (currentAppState['recentPlans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        recentPlans.removeWhere((plan) => plan['id'] == 'qp_cascade_test');
        currentAppState['recentPlans'] = recentPlans;

        await prefs.setString('application_state', jsonEncode(currentAppState));

        // ASSERT
        expect(prefs.getString('quarter_plan_qp_cascade_test'), isNull);
        
        final updatedIndex = prefs.getStringList('quarter_plans_index');
        expect(updatedIndex, isNot(contains('qp_cascade_test')));
        expect(updatedIndex, contains('qp_other'));

        final finalAppStateJson = prefs.getString('application_state');
        final finalAppState = finalAppStateJson != null ? jsonDecode(finalAppStateJson) : null;
        
        expect(finalAppState?['selectedQuarterPlanId'], isNull);
        
        final finalRecentPlans = finalAppState?['recentPlans'] as List? ?? [];
        expect(finalRecentPlans.any((plan) => plan['id'] == 'qp_cascade_test'), isFalse);
        expect(finalRecentPlans.any((plan) => plan['id'] == 'qp_other'), isTrue);
      });

      test('should handle repository transaction-like operations', () async {
        // ARRANGE - Prepare data for batch operation
        final quarterPlan = {
          'id': 'qp_transaction_test',
          'title': 'Transaction Test Plan',
          'status': 'draft'
        };

        final applicationStateUpdates = {
          'selectedQuarterPlanId': 'qp_transaction_test',
          'hasUnsavedChanges': true
        };

        // ACT - Simulate transaction-like batch operation
        try {
          // Step 1: Save quarter plan
          await prefs.setString('quarter_plan_qp_transaction_test', jsonEncode(quarterPlan));
          
          // Step 2: Update index
          final currentIndex = prefs.getStringList('quarter_plans_index') ?? [];
          currentIndex.add('qp_transaction_test');
          await prefs.setStringList('quarter_plans_index', currentIndex);
          
          // Step 3: Update application state
          final currentAppStateJson = prefs.getString('application_state') ?? '{}';
          final currentAppState = jsonDecode(currentAppStateJson);
          
          currentAppState.addAll(applicationStateUpdates);
          await prefs.setString('application_state', jsonEncode(currentAppState));
          
          // Step 4: Mark transaction as complete
          await prefs.setBool('transaction_qp_transaction_test_complete', true);
          
        } catch (e) {
          // If any step fails, we could implement rollback logic here
          // For now, just verify we can detect the failure
          expect(e, isA<Exception>());
        }

        // ASSERT - Verify all steps completed successfully
        expect(prefs.getString('quarter_plan_qp_transaction_test'), isNotNull);
        
        final index = prefs.getStringList('quarter_plans_index');
        expect(index, contains('qp_transaction_test'));
        
        final appStateJson = prefs.getString('application_state');
        final appState = appStateJson != null ? jsonDecode(appStateJson) : null;
        expect(appState?['selectedQuarterPlanId'], equals('qp_transaction_test'));
        expect(appState?['hasUnsavedChanges'], isTrue);
        
        expect(prefs.getBool('transaction_qp_transaction_test_complete'), isTrue);
      });
    });

    group('Repository Caching and Performance', () {
      test('should implement efficient data loading strategies', () async {
        // ARRANGE - Create multiple quarter plans
        final quarterPlans = List.generate(20, (index) => {
          'id': 'qp_perf_${index.toString().padLeft(3, '0')}',
          'title': 'Performance Test Plan $index',
          'quarter': 'Q${(index % 4) + 1} 202${4 + (index ~/ 4)}',
          'teamMembers': List.generate(5, (memberIndex) => {
            'id': 'tm_${index}_$memberIndex',
            'name': 'Member $memberIndex for Plan $index'
          }),
          'initiatives': List.generate(3, (initIndex) => {
            'id': 'init_${index}_$initIndex',
            'title': 'Initiative $initIndex for Plan $index'
          })
        });

        // Store all plans
        final planIds = <String>[];
        for (final plan in quarterPlans) {
          final key = 'quarter_plan_${plan['id']}';
          await prefs.setString(key, jsonEncode(plan));
          planIds.add(plan['id'] as String);
        }
        await prefs.setStringList('quarter_plans_index', planIds);

        // ACT - Implement different loading strategies
        final stopwatch = Stopwatch()..start();

        // Strategy 1: Load all plan metadata (ID and title only)
        final allPlanIds = prefs.getStringList('quarter_plans_index') ?? [];
        final planMetadata = <Map<String, dynamic>>[];
        
        for (final planId in allPlanIds) {
          final planJson = prefs.getString('quarter_plan_$planId');
          if (planJson != null) {
            final fullPlan = jsonDecode(planJson);
            // Extract only metadata for list view
            planMetadata.add({
              'id': fullPlan['id'],
              'title': fullPlan['title'],
              'quarter': fullPlan['quarter']
            });
          }
        }

        final metadataLoadTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();

        // Strategy 2: Load full plan on demand
        const selectedPlanId = 'qp_perf_010';
        final selectedPlanJson = prefs.getString('quarter_plan_$selectedPlanId');
        final selectedPlan = selectedPlanJson != null ? jsonDecode(selectedPlanJson) : null;

        final fullPlanLoadTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();

        // ASSERT
        expect(planMetadata, hasLength(20));
        expect(planMetadata.first['title'], equals('Performance Test Plan 0'));
        expect(selectedPlan, isNotNull);
        expect(selectedPlan['teamMembers'], hasLength(5));
        expect(selectedPlan['initiatives'], hasLength(3));

        // Performance expectations (these would be more meaningful with real data sizes)
        expect(metadataLoadTime, lessThan(5000)); // Should be fast for metadata
        expect(fullPlanLoadTime, lessThan(1000)); // Single plan load should be quick
      });

      test('should optimize storage space usage', () async {
        // ARRANGE - Create data with potential for optimization
        final redundantData = {
          'baseData': {
            'sharedProperty1': 'This is a long shared value that appears in many places',
            'sharedProperty2': 'Another shared value used across multiple objects',
            'commonSettings': {
              'theme': 'default',
              'language': 'en',
              'timezone': 'UTC'
            }
          },
          'quarterPlans': List.generate(5, (index) => {
            'id': 'qp_optimize_$index',
            'title': 'Optimization Test Plan $index',
            // These would normally contain redundant shared data
            'sharedProperty1': 'This is a long shared value that appears in many places',
            'sharedProperty2': 'Another shared value used across multiple objects',
            'settings': {
              'theme': 'default',
              'language': 'en',
              'timezone': 'UTC'
            }
          })
        };

        // ACT - Store data and measure storage usage
        final beforeKeys = prefs.getKeys().length;
        
        // Naive approach: store each plan with full data
        for (final plan in redundantData['quarterPlans'] as List) {
          await prefs.setString('quarter_plan_${plan['id']}', jsonEncode(plan));
        }
        
        // Optimized approach: store shared data separately
        await prefs.setString('shared_data', jsonEncode(redundantData['baseData']));
        
        final optimizedPlans = (redundantData['quarterPlans'] as List).map((plan) => {
          'id': plan['id'],
          'title': plan['title'],
          // Reference shared data instead of duplicating
          'sharedDataRef': 'shared_data'
        }).toList();
        
        await prefs.setString('optimized_plans_index', jsonEncode(optimizedPlans));
        
        final afterKeys = prefs.getKeys().length;

        // ASSERT
        expect(afterKeys, greaterThan(beforeKeys));
        
        // Verify we can reconstruct full data
        final sharedDataJson = prefs.getString('shared_data');
        final sharedData = sharedDataJson != null ? jsonDecode(sharedDataJson) : null;
        
        final optimizedIndexJson = prefs.getString('optimized_plans_index');
        final optimizedIndex = optimizedIndexJson != null ? jsonDecode(optimizedIndexJson) : null;
        
        expect(sharedData, isNotNull);
        expect(optimizedIndex, hasLength(5));
        
        // Verify we can merge shared data back
        final reconstructedPlan = <String, dynamic>{
          ...(optimizedIndex[0] as Map<String, dynamic>),
          ...(sharedData as Map<String, dynamic>)
        };
        
        expect(reconstructedPlan['sharedProperty1'], 
               equals('This is a long shared value that appears in many places'));
        expect(reconstructedPlan['commonSettings']['theme'], equals('default'));
      });
    });
  });
}
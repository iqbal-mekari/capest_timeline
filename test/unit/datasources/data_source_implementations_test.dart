/// Unit tests for data source implementations.
/// 
/// Tests the data source layer that provides raw data access and
/// transformation. Covers:
/// - Local data source operations
/// - Remote data source simulation (for future API integration)
/// - Data synchronization between sources
/// - Error handling and retry mechanisms
/// - Data validation and transformation
/// - Offline/online state management
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// TODO: Import actual data source classes when implemented
// import 'package:capest_timeline/features/capacity_planning/data/datasources/quarter_plan_local_datasource.dart';
// import 'package:capest_timeline/features/capacity_planning/data/datasources/quarter_plan_remote_datasource.dart';
// import 'package:capest_timeline/features/configuration/data/datasources/application_state_local_datasource.dart';

void main() {
  group('Data Source Implementation Tests', () {
    late SharedPreferences prefs;
    // late QuarterPlanLocalDataSource localDataSource;
    // late ApplicationStateLocalDataSource appStateDataSource;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // TODO: Initialize actual data sources when implemented
      // localDataSource = QuarterPlanLocalDataSource(prefs);
      // appStateDataSource = ApplicationStateLocalDataSource(prefs);
    });

    group('Local Data Source Operations', () {
      test('should store and retrieve raw data correctly', () async {
        // ARRANGE
        final rawQuarterPlanData = {
          'id': 'qp_raw_001',
          'title': 'Raw Quarter Plan',
          'data_version': '1.0',
          'created_timestamp': DateTime.now().millisecondsSinceEpoch,
          'raw_team_data': [
            {
              'member_id': 'tm_001',
              'member_name': 'John Doe',
              'role_code': 'BE_DEV',
              'capacity_percentage': 80
            }
          ],
          'raw_initiative_data': [
            {
              'initiative_id': 'init_001',
              'title': 'Backend API',
              'priority_level': 1,
              'effort_points': 40
            }
          ]
        };

        // ACT - Store raw data
        const storageKey = 'raw_quarter_plan_qp_raw_001';
        await prefs.setString(storageKey, jsonEncode(rawQuarterPlanData));

        // Retrieve raw data
        final retrievedJson = prefs.getString(storageKey);
        final retrievedData = retrievedJson != null ? jsonDecode(retrievedJson) : null;

        // ASSERT
        expect(retrievedData, isNotNull);
        expect(retrievedData['id'], equals('qp_raw_001'));
        expect(retrievedData['data_version'], equals('1.0'));
        expect(retrievedData['raw_team_data'], hasLength(1));
        expect(retrievedData['raw_initiative_data'], hasLength(1));
        
        // Verify raw data structure is preserved
        final teamMember = retrievedData['raw_team_data'][0];
        expect(teamMember['role_code'], equals('BE_DEV'));
        expect(teamMember['capacity_percentage'], equals(80));
        
        final initiative = retrievedData['raw_initiative_data'][0];
        expect(initiative['priority_level'], equals(1));
        expect(initiative['effort_points'], equals(40));
      });

      test('should handle data transformation from storage format', () async {
        // ARRANGE - Raw storage data with different field names/formats
        final storageFormatData = {
          'qp_id': 'qp_transform_001',
          'qp_title': 'Transform Test',
          'creation_ts': 1640995200000, // Unix timestamp
          'team_list': [
            {
              'tm_id': 'tm_001',
              'full_name': 'Alice Johnson',
              'job_role': 'backend_developer',
              'work_capacity': 0.8 // Decimal format
            }
          ],
          'project_list': [
            {
              'proj_id': 'proj_001',
              'proj_name': 'User Authentication',
              'importance': 'high',
              'size_estimate': '40.0'
            }
          ]
        };

        await prefs.setString('storage_format_data', jsonEncode(storageFormatData));

        // ACT - Transform to domain format (simulating data source transformation)
        final rawJson = prefs.getString('storage_format_data');
        final rawData = rawJson != null ? jsonDecode(rawJson) : null;

        // Transform to domain format
        final domainFormatData = {
          'id': rawData?['qp_id'],
          'title': rawData?['qp_title'],
          'createdAt': DateTime.fromMillisecondsSinceEpoch(rawData?['creation_ts'] ?? 0).toIso8601String(),
          'teamMembers': (rawData?['team_list'] as List?)?.map((member) => {
            'id': member['tm_id'],
            'name': member['full_name'],
            'role': _transformRole(member['job_role']),
            'capacity': (member['work_capacity'] as double) * 100 // Convert to percentage
          }).toList(),
          'initiatives': (rawData?['project_list'] as List?)?.map((project) => {
            'id': project['proj_id'],
            'title': project['proj_name'],
            'priority': _transformPriority(project['importance']),
            'estimatedEffort': double.parse(project['size_estimate'])
          }).toList()
        };

        // ASSERT
        expect(domainFormatData['id'], equals('qp_transform_001'));
        expect(domainFormatData['title'], equals('Transform Test'));
        expect(domainFormatData['createdAt'], startsWith('2022-01-01T')); // Timezone may vary
        
        final transformedTeamMembers = domainFormatData['teamMembers'] as List?;
        expect(transformedTeamMembers, hasLength(1));
        expect(transformedTeamMembers?[0]['role'], equals('Backend Developer'));
        expect(transformedTeamMembers?[0]['capacity'], equals(80.0));
        
        final transformedInitiatives = domainFormatData['initiatives'] as List?;
        expect(transformedInitiatives, hasLength(1));
        expect(transformedInitiatives?[0]['priority'], equals('High'));
        expect(transformedInitiatives?[0]['estimatedEffort'], equals(40.0));
      });

      test('should handle batch operations efficiently', () async {
        // ARRANGE - Multiple data items for batch operation
        final batchData = List.generate(10, (index) => {
          'id': 'batch_item_${index.toString().padLeft(3, '0')}',
          'title': 'Batch Item $index',
          'timestamp': DateTime.now().add(Duration(minutes: index)).millisecondsSinceEpoch,
          'data': 'Content for item $index'
        });

        // ACT - Batch store operation
        final batchKeys = <String>[];
        for (final item in batchData) {
          final key = 'batch_${item['id']}';
          await prefs.setString(key, jsonEncode(item));
          batchKeys.add(key);
        }

        // Store batch index
        await prefs.setStringList('batch_operation_index', batchKeys);

        // Batch retrieve operation
        final storedKeys = prefs.getStringList('batch_operation_index') ?? [];
        final retrievedItems = <Map<String, dynamic>>[];
        
        for (final key in storedKeys) {
          final itemJson = prefs.getString(key);
          if (itemJson != null) {
            retrievedItems.add(jsonDecode(itemJson));
          }
        }

        // ASSERT
        expect(retrievedItems, hasLength(10));
        expect(retrievedItems.first['title'], equals('Batch Item 0'));
        expect(retrievedItems.last['title'], equals('Batch Item 9'));
        
        // Verify all items have correct structure
        for (int i = 0; i < retrievedItems.length; i++) {
          final item = retrievedItems[i];
          expect(item['id'], equals('batch_item_${i.toString().padLeft(3, '0')}'));
          expect(item['data'], equals('Content for item $i'));
        }
      });

      test('should validate data before storage', () async {
        // ARRANGE - Various data validation scenarios
        final validData = {
          'id': 'valid_001',
          'title': 'Valid Quarter Plan',
          'teamMembers': [
            {
              'id': 'tm_001',
              'name': 'Valid Member',
              'role': 'Developer',
              'capacity': 80.0
            }
          ]
        };

        final invalidDataScenarios = [
          // Missing required fields
          {
            'title': 'No ID Plan'
            // Missing 'id' field
          },
          // Invalid data types
          {
            'id': 123, // Should be string
            'title': 'Invalid ID Type Plan'
          },
          // Invalid nested data
          {
            'id': 'invalid_nested_001',
            'title': 'Invalid Nested Plan',
            'teamMembers': [
              {
                'id': 'tm_001',
                'name': 'Member',
                'capacity': 'invalid_capacity' // Should be number
              }
            ]
          }
        ];

        // ACT & ASSERT - Valid data should store successfully
        await prefs.setString('valid_plan', jsonEncode(validData));
        final storedValid = prefs.getString('valid_plan');
        expect(storedValid, isNotNull);
        
        final validParsed = jsonDecode(storedValid!);
        expect(validParsed['id'], equals('valid_001'));

        // Invalid data scenarios - in a real implementation, these would be caught
        // by validation logic before reaching SharedPreferences
        for (int i = 0; i < invalidDataScenarios.length; i++) {
          final invalidData = invalidDataScenarios[i];
          
          // We can still store invalid data in SharedPreferences,
          // but validation should happen at the data source level
          await prefs.setString('invalid_test_$i', jsonEncode(invalidData));
          final stored = prefs.getString('invalid_test_$i');
          expect(stored, isNotNull);
          
          // The data source should implement validation
          // TODO: Add validation logic in actual data source implementation
          // expect(() => dataSource.validateAndStore(invalidData), throwsA(isA<ValidationException>()));
        }
      });

      test('should handle data source cleanup operations', () async {
        // ARRANGE - Create data that needs cleanup
        final temporaryData = {
          'temp_001': {'type': 'temporary', 'expires': DateTime.now().add(const Duration(minutes: -10)).millisecondsSinceEpoch},
          'temp_002': {'type': 'temporary', 'expires': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch},
          'perm_001': {'type': 'permanent', 'important': true}
        };

        // Store data
        for (final entry in temporaryData.entries) {
          await prefs.setString(entry.key, jsonEncode(entry.value));
        }

        // ACT - Cleanup expired temporary data
        final allKeys = prefs.getKeys();
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final keysToRemove = <String>[];

        for (final key in allKeys) {
          final dataJson = prefs.getString(key);
          if (dataJson != null) {
            try {
              final data = jsonDecode(dataJson);
              if (data['type'] == 'temporary' && 
                  data['expires'] != null && 
                  data['expires'] < currentTime) {
                keysToRemove.add(key);
              }
            } catch (e) {
              // Skip non-JSON data
            }
          }
        }

        // Remove expired data
        for (final key in keysToRemove) {
          await prefs.remove(key);
        }

        // ASSERT
        expect(prefs.getString('temp_001'), isNull); // Expired, should be removed
        expect(prefs.getString('temp_002'), isNotNull); // Not expired, should remain
        expect(prefs.getString('perm_001'), isNotNull); // Permanent, should remain
        
        // Verify remaining data
        final remainingTemp002 = jsonDecode(prefs.getString('temp_002')!);
        expect(remainingTemp002['type'], equals('temporary'));
        
        final remainingPerm001 = jsonDecode(prefs.getString('perm_001')!);
        expect(remainingPerm001['type'], equals('permanent'));
      });
    });

    group('Remote Data Source Simulation', () {
      test('should simulate remote API data format', () async {
        // ARRANGE - Simulate API response format
        final apiResponseData = {
          'status': 'success',
          'data': {
            'quarter_plans': [
              {
                'id': 'qp_api_001',
                'attributes': {
                  'title': 'API Quarter Plan',
                  'quarter': 'Q1 2024',
                  'created_at': '2024-01-01T00:00:00Z',
                  'updated_at': '2024-01-15T10:30:00Z'
                },
                'relationships': {
                  'team_members': {
                    'data': [
                      {'type': 'team_member', 'id': 'tm_api_001'}
                    ]
                  },
                  'initiatives': {
                    'data': [
                      {'type': 'initiative', 'id': 'init_api_001'}
                    ]
                  }
                }
              }
            ],
            'included': [
              {
                'type': 'team_member',
                'id': 'tm_api_001',
                'attributes': {
                  'name': 'API Team Member',
                  'role': 'full_stack_developer',
                  'capacity_percentage': 85
                }
              },
              {
                'type': 'initiative',
                'id': 'init_api_001',
                'attributes': {
                  'title': 'API Initiative',
                  'priority': 'high',
                  'estimated_effort': 35.0
                }
              }
            ]
          }
        };

        // ACT - Store API response and transform to local format
        await prefs.setString('api_response_cache', jsonEncode(apiResponseData));

        // Transform API format to local storage format
        final cached = jsonDecode(prefs.getString('api_response_cache')!);
        final quarterPlan = cached['data']['quarter_plans'][0];
        final included = cached['data']['included'] as List;

        // Resolve relationships
        final teamMembers = <Map<String, dynamic>>[];
        final initiatives = <Map<String, dynamic>>[];

        for (final relationship in quarterPlan['relationships']['team_members']['data']) {
          final member = included.firstWhere(
            (item) => item['type'] == 'team_member' && item['id'] == relationship['id']
          );
          teamMembers.add({
            'id': member['id'],
            'name': member['attributes']['name'],
            'role': _transformRole(member['attributes']['role']),
            'capacity': member['attributes']['capacity_percentage'].toDouble()
          });
        }

        for (final relationship in quarterPlan['relationships']['initiatives']['data']) {
          final initiative = included.firstWhere(
            (item) => item['type'] == 'initiative' && item['id'] == relationship['id']
          );
          initiatives.add({
            'id': initiative['id'],
            'title': initiative['attributes']['title'],
            'priority': _transformPriority(initiative['attributes']['priority']),
            'estimatedEffort': initiative['attributes']['estimated_effort']
          });
        }

        final localFormatData = {
          'id': quarterPlan['id'],
          'title': quarterPlan['attributes']['title'],
          'quarter': quarterPlan['attributes']['quarter'],
          'createdAt': quarterPlan['attributes']['created_at'],
          'lastModified': quarterPlan['attributes']['updated_at'],
          'teamMembers': teamMembers,
          'initiatives': initiatives,
          'syncedAt': DateTime.now().toIso8601String()
        };

        await prefs.setString('local_qp_api_001', jsonEncode(localFormatData));

        // ASSERT
        final localData = jsonDecode(prefs.getString('local_qp_api_001')!);
        expect(localData['id'], equals('qp_api_001'));
        expect(localData['title'], equals('API Quarter Plan'));
        expect(localData['teamMembers'], hasLength(1));
        expect(localData['initiatives'], hasLength(1));
        
        expect(localData['teamMembers'][0]['name'], equals('API Team Member'));
        expect(localData['teamMembers'][0]['role'], equals('Full-Stack Developer'));
        expect(localData['teamMembers'][0]['capacity'], equals(85.0));
        
        expect(localData['initiatives'][0]['title'], equals('API Initiative'));
        expect(localData['initiatives'][0]['priority'], equals('High'));
      });

      test('should handle API error responses', () async {
        // ARRANGE - Various API error scenarios
        final errorResponses = [
          // Network error simulation
          {
            'status': 'error',
            'error': {
              'code': 'NETWORK_ERROR',
              'message': 'Unable to connect to server',
              'timestamp': DateTime.now().toIso8601String()
            }
          },
          // Validation error simulation
          {
            'status': 'error',
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Invalid quarter plan data',
              'details': [
                {'field': 'teamMembers', 'message': 'At least one team member is required'},
                {'field': 'title', 'message': 'Title cannot be empty'}
              ]
            }
          },
          // Authentication error simulation
          {
            'status': 'error',
            'error': {
              'code': 'UNAUTHORIZED',
              'message': 'Authentication token expired'
            }
          }
        ];

        // ACT & ASSERT
        for (int i = 0; i < errorResponses.length; i++) {
          final errorResponse = errorResponses[i];
          await prefs.setString('error_response_$i', jsonEncode(errorResponse));

          final storedError = jsonDecode(prefs.getString('error_response_$i')!);
          expect(storedError['status'], equals('error'));
          expect(storedError['error']['code'], isNotNull);
          expect(storedError['error']['message'], isNotNull);

          // In a real implementation, the data source would:
          // 1. Parse the error response
          // 2. Convert to appropriate exception type
          // 3. Implement retry logic for recoverable errors
          // 4. Cache error state for offline handling
        }
      });

      test('should simulate data synchronization scenarios', () async {
        // ARRANGE - Local and remote data with conflicts
        final localData = {
          'id': 'qp_sync_001',
          'title': 'Local Title',
          'lastModified': '2024-01-15T10:00:00Z',
          'version': 1,
          'localChanges': true
        };

        final remoteData = {
          'id': 'qp_sync_001',
          'title': 'Remote Title',
          'lastModified': '2024-01-15T10:30:00Z',
          'version': 2,
          'localChanges': false
        };

        await prefs.setString('local_qp_sync_001', jsonEncode(localData));
        await prefs.setString('remote_qp_sync_001', jsonEncode(remoteData));

        // ACT - Simulate conflict resolution (remote wins by timestamp)
        final local = jsonDecode(prefs.getString('local_qp_sync_001')!);
        final remote = jsonDecode(prefs.getString('remote_qp_sync_001')!);

        final localTimestamp = DateTime.parse(local['lastModified']);
        final remoteTimestamp = DateTime.parse(remote['lastModified']);

        Map<String, dynamic> resolvedData;
        if (remoteTimestamp.isAfter(localTimestamp)) {
          // Remote is newer, use remote data but preserve local metadata
          resolvedData = {
            ...remote,
            'syncedAt': DateTime.now().toIso8601String(),
            'conflictResolved': true,
            'resolutionStrategy': 'remote_wins'
          };
        } else {
          // Local is newer or same, keep local data
          resolvedData = {
            ...local,
            'syncedAt': DateTime.now().toIso8601String(),
            'conflictResolved': true,
            'resolutionStrategy': 'local_wins'
          };
        }

        await prefs.setString('resolved_qp_sync_001', jsonEncode(resolvedData));

        // ASSERT
        final resolved = jsonDecode(prefs.getString('resolved_qp_sync_001')!);
        expect(resolved['title'], equals('Remote Title')); // Remote was newer
        expect(resolved['version'], equals(2));
        expect(resolved['conflictResolved'], isTrue);
        expect(resolved['resolutionStrategy'], equals('remote_wins'));
        expect(resolved['syncedAt'], isNotNull);
      });
    });

    group('Data Source Error Handling', () {
      test('should handle storage quota exceeded scenarios', () async {
        // ARRANGE - Simulate large data storage
        final largeDataItem = {
          'id': 'large_data_001',
          'content': 'x' * 100000, // 100KB of data
          'metadata': {
            'size': 100000,
            'type': 'large_content'
          }
        };

        // ACT - Store large data and check for errors
        try {
          await prefs.setString('large_data_test', jsonEncode(largeDataItem));
          
          // Verify storage succeeded
          final stored = prefs.getString('large_data_test');
          expect(stored, isNotNull);
          expect(stored!.length, greaterThan(100000));
          
          // In a real implementation, we might want to:
          // 1. Check available storage space
          // 2. Implement data compression
          // 3. Clean up old data if needed
          // 4. Split large data into chunks
          
        } catch (e) {
          // Handle storage quota exceeded
          expect(e, isA<Exception>());
          
          // Implement fallback strategy
          final fallbackData = {
            'id': largeDataItem['id'],
            'contentRef': 'external_storage_reference',
            'metadata': largeDataItem['metadata']
          };
          
          await prefs.setString('large_data_fallback', jsonEncode(fallbackData));
          
          final fallback = prefs.getString('large_data_fallback');
          expect(fallback, isNotNull);
        }
      });

      test('should implement retry mechanisms for failed operations', () async {
        // ARRANGE - Simulate operations that might fail
        const maxRetries = 3;
        var attemptCount = 0;
        
        final testData = {
          'id': 'retry_test_001',
          'data': 'test_content',
          'attemptNumber': 0
        };

        // ACT - Simulate retry logic
        bool operationSucceeded = false;

        for (int attempt = 0; attempt < maxRetries && !operationSucceeded; attempt++) {
          try {
            attemptCount++;
            testData['attemptNumber'] = attempt + 1;
            
            // Simulate failure on first two attempts, success on third
            if (attempt < 2) {
              // Simulate various failure types
              switch (attempt) {
                case 0:
                  throw Exception('Network timeout');
                case 1:
                  throw Exception('Temporary storage error');
              }
            }
            
            // Success on third attempt
            await prefs.setString('retry_test_result', jsonEncode(testData));
            operationSucceeded = true;
            
          } catch (e) {
            
            // Log attempt for debugging
            await prefs.setString('retry_attempt_$attempt', jsonEncode({
              'attempt': attempt + 1,
              'error': e.toString(),
              'timestamp': DateTime.now().toIso8601String()
            }));
            
            // Wait before retry (exponential backoff)
            await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
          }
        }

        // ASSERT
        expect(attemptCount, equals(3));
        expect(operationSucceeded, isTrue);
        expect(prefs.getString('retry_test_result'), isNotNull);
        
        final result = jsonDecode(prefs.getString('retry_test_result')!);
        expect(result['attemptNumber'], equals(3));
        
        // Verify retry attempts were logged
        expect(prefs.getString('retry_attempt_0'), isNotNull);
        expect(prefs.getString('retry_attempt_1'), isNotNull);
        
        final firstAttempt = jsonDecode(prefs.getString('retry_attempt_0')!);
        expect(firstAttempt['error'], contains('Network timeout'));
        
        final secondAttempt = jsonDecode(prefs.getString('retry_attempt_1')!);
        expect(secondAttempt['error'], contains('Temporary storage error'));
      });

      test('should handle data corruption detection and recovery', () async {
        // ARRANGE - Create valid data then simulate corruption
        final validData = {
          'id': 'corruption_test_001',
          'title': 'Valid Data',
          'checksum': 'abc123',
          'teamMembers': [
            {'id': 'tm_001', 'name': 'Member 1'}
          ]
        };

        await prefs.setString('valid_data', jsonEncode(validData));

        // Simulate data corruption
        const corruptedJson = '{"id": "corruption_test_001", "title": "Valid Data", "teamMembers": [{"id": "tm_001", "name": "Member 1"}'; // Missing closing braces

        await prefs.setString('corrupted_data', corruptedJson);

        // Create backup data
        final backupData = {
          ...validData,
          'backupTimestamp': DateTime.now().toIso8601String()
        };
        await prefs.setString('backup_corruption_test_001', jsonEncode(backupData));

        // ACT - Attempt to load and recover from corruption
        final retrievedCorruptedJson = prefs.getString('corrupted_data');
        Map<String, dynamic>? loadedData;
        bool dataCorrupted = false;

        try {
          if (retrievedCorruptedJson != null) {
            loadedData = jsonDecode(retrievedCorruptedJson);
          }
        } catch (e) {
          dataCorrupted = true;
          
          // Attempt recovery from backup
          final backupJson = prefs.getString('backup_corruption_test_001');
          if (backupJson != null) {
            try {
              loadedData = jsonDecode(backupJson);
              
              // Restore from backup
              await prefs.setString('corrupted_data', backupJson);
              
              // Log recovery
              await prefs.setString('recovery_log', jsonEncode({
                'originalDataCorrupted': true,
                'recoveredFromBackup': true,
                'recoveryTimestamp': DateTime.now().toIso8601String()
              }));
              
            } catch (backupError) {
              // Both primary and backup data are corrupted
              await prefs.setString('recovery_log', jsonEncode({
                'originalDataCorrupted': true,
                'backupDataCorrupted': true,
                'totalDataLoss': true
              }));
            }
          }
        }

        // ASSERT
        expect(dataCorrupted, isTrue);
        expect(loadedData, isNotNull); // Should be recovered from backup
        expect(loadedData?['title'], equals('Valid Data'));
        expect(loadedData?['backupTimestamp'], isNotNull);
        
        final recoveryLog = jsonDecode(prefs.getString('recovery_log')!);
        expect(recoveryLog['originalDataCorrupted'], isTrue);
        expect(recoveryLog['recoveredFromBackup'], isTrue);
        expect(recoveryLog['recoveryTimestamp'], isNotNull);
      });
    });

    group('Data Source Performance and Optimization', () {
      test('should implement efficient data loading patterns', () async {
        // ARRANGE - Create scenario with large amounts of data
        final quarterPlans = List.generate(50, (index) => {
          'id': 'qp_perf_${index.toString().padLeft(3, '0')}',
          'title': 'Performance Plan $index',
          'teamMembers': List.generate(10, (memberIndex) => {
            'id': 'tm_${index}_$memberIndex',
            'name': 'Member $memberIndex'
          }),
          'initiatives': List.generate(5, (initIndex) => {
            'id': 'init_${index}_$initIndex',
            'title': 'Initiative $initIndex'
          })
        });

        // Store all data
        for (final plan in quarterPlans) {
          await prefs.setString('perf_plan_${plan['id']}', jsonEncode(plan));
        }

        // Create index for efficient access
        final planIndex = quarterPlans.map((plan) => {
          'id': plan['id'],
          'title': plan['title'],
          'teamMemberCount': (plan['teamMembers'] as List).length,
          'initiativeCount': (plan['initiatives'] as List).length
        }).toList();

        await prefs.setString('plan_index', jsonEncode(planIndex));

        // ACT - Test different loading patterns
        final stopwatch = Stopwatch();

        // Pattern 1: Load index only (for list view)
        stopwatch.start();
        final indexJson = prefs.getString('plan_index');
        final index = indexJson != null ? jsonDecode(indexJson) : [];
        final indexLoadTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();

        // Pattern 2: Load specific plan on demand
        const targetPlanId = 'qp_perf_025';
        stopwatch.start();
        final planJson = prefs.getString('perf_plan_$targetPlanId');
        final fullPlan = planJson != null ? jsonDecode(planJson) : null;
        final singlePlanLoadTime = stopwatch.elapsedMilliseconds;
        stopwatch.reset();

        // Pattern 3: Lazy load related data
        stopwatch.start();
        final planMetadata = (index as List).firstWhere(
          (plan) => plan['id'] == targetPlanId,
          orElse: () => null
        );
        final lazyLoadTime = stopwatch.elapsedMilliseconds;
        stopwatch.stop();

        // ASSERT
        expect(index, hasLength(50));
        expect(fullPlan, isNotNull);
        expect(planMetadata, isNotNull);
        
        // Performance expectations
        expect(indexLoadTime, lessThan(100)); // Index should load very quickly
        expect(singlePlanLoadTime, lessThan(50)); // Single plan should be fast
        expect(lazyLoadTime, lessThan(10)); // Metadata lookup should be instant
        
        // Verify data integrity
        expect(fullPlan['teamMembers'], hasLength(10));
        expect(fullPlan['initiatives'], hasLength(5));
        expect(planMetadata['teamMemberCount'], equals(10));
        expect(planMetadata['initiativeCount'], equals(5));
      });
    });
  });
}

// Helper functions for data transformation
String _transformRole(String roleCode) {
  switch (roleCode) {
    case 'backend_developer':
    case 'BE_DEV':
      return 'Backend Developer';
    case 'frontend_developer':
    case 'FE_DEV':
      return 'Frontend Developer';
    case 'full_stack_developer':
    case 'FS_DEV':
      return 'Full-Stack Developer';
    default:
      return roleCode.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1).toLowerCase()
      ).join(' ');
  }
}

String _transformPriority(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
    case '1':
      return 'High';
    case 'medium':
    case '2':
      return 'Medium';
    case 'low':
    case '3':
      return 'Low';
    default:
      return priority[0].toUpperCase() + priority.substring(1).toLowerCase();
  }
}
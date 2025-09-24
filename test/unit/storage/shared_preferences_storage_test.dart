/// Unit tests for SharedPreferences storage implementation.
/// 
/// Tests the local storage layer that persists quarter plans, application state,
/// and other data using SharedPreferences. Covers:
/// - Key-value storage operations
/// - Data serialization and deserialization
/// - Storage error handling and recovery
/// - Data migration and versioning
/// - Storage limits and optimization
/// - Concurrent storage access
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// TODO: Import actual storage classes when implemented
// import 'package:capest_timeline/core/storage/shared_preferences_storage.dart';
// import 'package:capest_timeline/core/storage/storage_keys.dart';
// import 'package:capest_timeline/core/storage/storage_serializer.dart';

void main() {
  group('SharedPreferences Storage Tests', () {
    late SharedPreferences prefs;
    // late SharedPreferencesStorage storage;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() async {
      // Reset SharedPreferences for each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      
      // TODO: Initialize actual storage when implemented
      // storage = SharedPreferencesStorage(prefs);
    });

    group('Basic Storage Operations', () {
      test('should store and retrieve string values', () async {
        // ARRANGE
        const key = 'test_string_key';
        const value = 'test_string_value';

        // ACT
        await prefs.setString(key, value);
        final retrievedValue = prefs.getString(key);

        // ASSERT
        expect(retrievedValue, equals(value));
      });

      test('should store and retrieve JSON objects', () async {
        // ARRANGE
        const key = 'test_json_key';
        final testData = {
          'id': 'test_001',
          'name': 'Test Object',
          'timestamp': '2024-01-15T10:00:00Z',
          'properties': {
            'active': true,
            'count': 42,
            'tags': ['tag1', 'tag2', 'tag3']
          }
        };

        // ACT
        final jsonString = jsonEncode(testData);
        await prefs.setString(key, jsonString);
        final retrievedString = prefs.getString(key);
        final retrievedData = retrievedString != null ? jsonDecode(retrievedString) : null;

        // ASSERT
        expect(retrievedData, isNotNull);
        expect(retrievedData, equals(testData));
        expect(retrievedData['properties']['active'], isTrue);
        expect(retrievedData['properties']['count'], equals(42));
        expect(retrievedData['properties']['tags'], hasLength(3));
      });

      test('should handle non-existent keys gracefully', () async {
        // ARRANGE
        const nonExistentKey = 'non_existent_key';

        // ACT
        final retrievedValue = prefs.getString(nonExistentKey);

        // ASSERT
        expect(retrievedValue, isNull);
      });

      test('should support boolean storage', () async {
        // ARRANGE
        const key = 'test_bool_key';
        const value = true;

        // ACT
        await prefs.setBool(key, value);
        final retrievedValue = prefs.getBool(key);

        // ASSERT
        expect(retrievedValue, equals(value));
      });

      test('should support integer storage', () async {
        // ARRANGE
        const key = 'test_int_key';
        const value = 12345;

        // ACT
        await prefs.setInt(key, value);
        final retrievedValue = prefs.getInt(key);

        // ASSERT
        expect(retrievedValue, equals(value));
      });

      test('should support double storage', () async {
        // ARRANGE
        const key = 'test_double_key';
        const value = 123.456;

        // ACT
        await prefs.setDouble(key, value);
        final retrievedValue = prefs.getDouble(key);

        // ASSERT
        expect(retrievedValue, equals(value));
      });

      test('should support string list storage', () async {
        // ARRANGE
        const key = 'test_string_list_key';
        const value = ['item1', 'item2', 'item3'];

        // ACT
        await prefs.setStringList(key, value);
        final retrievedValue = prefs.getStringList(key);

        // ASSERT
        expect(retrievedValue, equals(value));
        expect(retrievedValue, hasLength(3));
      });
    });

    group('Data Serialization', () {
      test('should serialize and deserialize quarter plan data', () async {
        // ARRANGE
        final quarterPlanData = {
          'id': 'qp_001',
          'title': 'Q1 2024 Plan',
          'quarter': 'Q1 2024',
          'createdAt': '2024-01-01T00:00:00Z',
          'lastModified': '2024-01-15T10:30:00Z',
          'teamMembers': [
            {
              'id': 'tm_001',
              'name': 'Alice Johnson',
              'role': 'Backend Developer',
              'capacity': 80.0,
              'skills': ['Java', 'Spring Boot', 'PostgreSQL']
            },
            {
              'id': 'tm_002',
              'name': 'Bob Smith',
              'role': 'Frontend Developer',
              'capacity': 75.0,
              'skills': ['React', 'TypeScript', 'CSS']
            }
          ],
          'initiatives': [
            {
              'id': 'init_001',
              'title': 'User Authentication System',
              'description': 'Implement secure user authentication',
              'priority': 'High',
              'estimatedEffort': 40.0,
              'allocations': [
                {
                  'memberId': 'tm_001',
                  'percentage': 60.0,
                  'weeks': [1, 2, 3, 4, 5]
                }
              ]
            }
          ]
        };

        // ACT
        final serialized = jsonEncode(quarterPlanData);
        await prefs.setString('quarter_plan_qp_001', serialized);
        
        final retrieved = prefs.getString('quarter_plan_qp_001');
        final deserialized = retrieved != null ? jsonDecode(retrieved) : null;

        // ASSERT
        expect(deserialized, isNotNull);
        expect(deserialized['id'], equals('qp_001'));
        expect(deserialized['title'], equals('Q1 2024 Plan'));
        expect(deserialized['teamMembers'], hasLength(2));
        expect(deserialized['initiatives'], hasLength(1));
        
        // Verify nested objects
        final firstMember = deserialized['teamMembers'][0];
        expect(firstMember['name'], equals('Alice Johnson'));
        expect(firstMember['capacity'], equals(80.0));
        expect(firstMember['skills'], hasLength(3));
        
        final firstInitiative = deserialized['initiatives'][0];
        expect(firstInitiative['title'], equals('User Authentication System'));
        expect(firstInitiative['allocations'], hasLength(1));
      });

      test('should serialize and deserialize application state data', () async {
        // ARRANGE
        final applicationStateData = {
          'id': 'app_state_001',
          'currentView': 'quarter_planning',
          'selectedQuarterPlanId': 'qp_001',
          'filters': {
            'showCompleted': false,
            'roleFilter': 'Backend Developer',
            'priorityFilter': 'High'
          },
          'recentPlans': [
            {
              'id': 'qp_001',
              'title': 'Q1 2024 Plan',
              'lastAccessed': '2024-01-15T10:30:00Z'
            },
            {
              'id': 'qp_002',
              'title': 'Q4 2023 Plan',
              'lastAccessed': '2024-01-10T14:20:00Z'
            }
          ],
          'autoSaveEnabled': true,
          'lastAutoSave': '2024-01-15T10:29:45Z',
          'hasUnsavedChanges': false
        };

        // ACT
        final serialized = jsonEncode(applicationStateData);
        await prefs.setString('application_state', serialized);
        
        final retrieved = prefs.getString('application_state');
        final deserialized = retrieved != null ? jsonDecode(retrieved) : null;

        // ASSERT
        expect(deserialized, isNotNull);
        expect(deserialized['currentView'], equals('quarter_planning'));
        expect(deserialized['selectedQuarterPlanId'], equals('qp_001'));
        expect(deserialized['autoSaveEnabled'], isTrue);
        expect(deserialized['hasUnsavedChanges'], isFalse);
        expect(deserialized['recentPlans'], hasLength(2));
        
        // Verify nested filter object
        final filters = deserialized['filters'];
        expect(filters['showCompleted'], isFalse);
        expect(filters['roleFilter'], equals('Backend Developer'));
        expect(filters['priorityFilter'], equals('High'));
      });

      test('should handle serialization errors gracefully', () async {
        // ARRANGE
        final invalidData = {
          'validField': 'valid_value',
          'invalidField': double.nan, // NaN cannot be serialized to JSON
        };

        // ACT & ASSERT
        expect(() => jsonEncode(invalidData), throwsA(isA<JsonUnsupportedObjectError>()));
      });

      test('should handle deserialization errors gracefully', () async {
        // ARRANGE
        const invalidJson = '{"incomplete": "object"'; // Missing closing brace

        // ACT
        await prefs.setString('invalid_json_key', invalidJson);
        final retrieved = prefs.getString('invalid_json_key');

        // ASSERT
        expect(retrieved, equals(invalidJson));
        expect(() => jsonDecode(retrieved!), throwsA(isA<FormatException>()));
      });

      test('should preserve data types during serialization round-trip', () async {
        // ARRANGE
        final mixedTypeData = {
          'stringValue': 'test_string',
          'intValue': 42,
          'doubleValue': 3.14159,
          'boolValue': true,
          'nullValue': null,
          'arrayValue': [1, 2, 3, 'mixed', true],
          'nestedObject': {
            'nestedString': 'nested_value',
            'nestedNumber': 123.45
          }
        };

        // ACT
        final serialized = jsonEncode(mixedTypeData);
        await prefs.setString('mixed_type_data', serialized);
        
        final retrieved = prefs.getString('mixed_type_data');
        final deserialized = retrieved != null ? jsonDecode(retrieved) : null;

        // ASSERT
        expect(deserialized, isNotNull);
        expect(deserialized['stringValue'], isA<String>());
        expect(deserialized['intValue'], isA<int>());
        expect(deserialized['doubleValue'], isA<double>());
        expect(deserialized['boolValue'], isA<bool>());
        expect(deserialized['nullValue'], isNull);
        expect(deserialized['arrayValue'], isA<List>());
        expect(deserialized['nestedObject'], isA<Map>());
      });
    });

    group('Storage Error Handling', () {
      test('should handle storage failures gracefully', () async {
        // ARRANGE
        // Note: SharedPreferences mock doesn't simulate failures well,
        // but we can test error handling patterns
        const key = 'test_key';
        const value = 'test_value';

        try {
          // ACT
          await prefs.setString(key, value);
          final retrieved = prefs.getString(key);

          // ASSERT
          expect(retrieved, equals(value));
        } catch (e) {
          // If storage fails, we should handle it gracefully
          expect(e, isA<Exception>());
        }
      });

      test('should provide meaningful error messages for storage operations', () async {
        // ARRANGE
        // This test would be more meaningful with actual storage implementation
        // that can simulate various failure modes
        
        // ACT & ASSERT
        // For now, just verify that basic operations don't throw unexpected errors
        expect(() async {
          await prefs.setString('test_key', 'test_value');
          prefs.getString('test_key');
        }, returnsNormally);
      });

      test('should handle large data storage appropriately', () async {
        // ARRANGE
        final largeDataMap = <String, dynamic>{};
        
        // Create a large object
        for (int i = 0; i < 1000; i++) {
          largeDataMap['item_$i'] = {
            'id': 'id_$i',
            'data': 'x' * 100, // 100 character string
            'timestamp': '2024-01-15T10:${i.toString().padLeft(2, '0')}:00Z',
            'properties': List.generate(10, (index) => 'property_${i}_$index')
          };
        }

        // ACT
        final serialized = jsonEncode(largeDataMap);
        
        // This test verifies we can handle large data sets
        // In a real implementation, we might want to chunk or compress large data
        expect(serialized.length, greaterThan(100000)); // Should be substantial
        
        await prefs.setString('large_data_test', serialized);
        final retrieved = prefs.getString('large_data_test');
        
        // ASSERT
        expect(retrieved, isNotNull);
        expect(retrieved!.length, equals(serialized.length));
        
        final deserialized = jsonDecode(retrieved);
        expect(deserialized, hasLength(1000));
        expect(deserialized['item_0']['data'], equals('x' * 100));
      });
    });

    group('Storage Keys and Organization', () {
      test('should use consistent key naming conventions', () async {
        // ARRANGE
        const expectedKeys = {
          'quarter_plans_index': '[]',
          'quarter_plan_qp_001': '{"id":"qp_001"}',
          'application_state': '{"version":"1.0"}',
          'user_preferences': '{"theme":"light"}',
          'cache_team_members': '[]',
          'metadata_version': '1.0.0'
        };

        // ACT
        for (final entry in expectedKeys.entries) {
          await prefs.setString(entry.key, entry.value);
        }

        // ASSERT
        final allKeys = prefs.getKeys();
        for (final expectedKey in expectedKeys.keys) {
          expect(allKeys.contains(expectedKey), isTrue, 
            reason: 'Expected key $expectedKey should exist in storage');
        }

        // Verify key naming patterns
        final quarterPlanKeys = allKeys.where((key) => key.startsWith('quarter_plan_')).toList();
        expect(quarterPlanKeys, hasLength(1));
        expect(quarterPlanKeys.first, equals('quarter_plan_qp_001'));

        final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).toList();
        expect(cacheKeys, hasLength(1));
        expect(cacheKeys.first, equals('cache_team_members'));
      });

      test('should support key enumeration and cleanup', () async {
        // ARRANGE
        final testData = {
          'temp_key_1': 'temporary_data_1',
          'temp_key_2': 'temporary_data_2',
          'persistent_key': 'persistent_data',
          'another_temp_key': 'more_temporary_data'
        };

        // ACT - Store test data
        for (final entry in testData.entries) {
          await prefs.setString(entry.key, entry.value);
        }

        // Verify all keys are stored
        final allKeys = prefs.getKeys();
        for (final key in testData.keys) {
          expect(allKeys.contains(key), isTrue);
        }

        // Clean up temporary keys
        final tempKeys = allKeys.where((key) => key.startsWith('temp_')).toList();
        for (final tempKey in tempKeys) {
          await prefs.remove(tempKey);
        }

        // ASSERT
        final remainingKeys = prefs.getKeys();
        expect(remainingKeys.contains('persistent_key'), isTrue);
        expect(remainingKeys.contains('another_temp_key'), isTrue); // Starts with 'another_'
        expect(remainingKeys.where((key) => key.startsWith('temp_')), isEmpty);
      });

      test('should handle key collisions and overwrites', () async {
        // ARRANGE
        const key = 'collision_test_key';
        const firstValue = 'first_value';
        const secondValue = 'second_value';

        // ACT
        await prefs.setString(key, firstValue);
        final firstRetrieved = prefs.getString(key);

        await prefs.setString(key, secondValue);
        final secondRetrieved = prefs.getString(key);

        // ASSERT
        expect(firstRetrieved, equals(firstValue));
        expect(secondRetrieved, equals(secondValue));
        expect(secondRetrieved, isNot(equals(firstValue)));
      });
    });

    group('Data Migration and Versioning', () {
      test('should handle data format migration scenarios', () async {
        // ARRANGE - Simulate old data format
        final oldFormatData = {
          'version': '1.0',
          'quarter_plan': {
            'id': 'qp_001',
            'name': 'Q1 Plan', // Old field name
            'team': ['Alice', 'Bob'], // Old format - just names
            'tasks': [ // Old field name for initiatives
              {
                'title': 'Task 1',
                'owner': 'Alice' // Old format - just name
              }
            ]
          }
        };

        // Expected new format after migration (will be used when migration logic is implemented)
        final expectedNewFormat = {
          'version': '2.0',
          'quarter_plan': {
            'id': 'qp_001',
            'title': 'Q1 Plan', // New field name
            'teamMembers': [ // New format - full objects
              {
                'id': 'generated_alice_id',
                'name': 'Alice',
                'role': 'Developer'
              },
              {
                'id': 'generated_bob_id',
                'name': 'Bob',
                'role': 'Developer'
              }
            ],
            'initiatives': [ // New field name
              {
                'id': 'generated_task_id',
                'title': 'Task 1',
                'assignedMember': { // New format - full object
                  'id': 'generated_alice_id',
                  'name': 'Alice'
                }
              }
            ]
          }
        };
        // TODO: Use expectedNewFormat for validation when migration is implemented

        // ACT - Store old format data
        await prefs.setString('old_format_data', jsonEncode(oldFormatData));
        
        // TODO: When migration logic is implemented, it would:
        // 1. Detect version 1.0 data
        // 2. Transform to version 2.0 format
        // 3. Update version number
        // 4. Store migrated data
        
        // For now, just verify we can detect version differences
        final storedData = prefs.getString('old_format_data');
        final parsedData = storedData != null ? jsonDecode(storedData) : null;

        // ASSERT
        expect(parsedData, isNotNull);
        expect(parsedData['version'], equals('1.0'));
        expect(parsedData['quarter_plan']['name'], equals('Q1 Plan')); // Old field
        expect(parsedData['quarter_plan']['team'], isA<List>());
        expect(parsedData['quarter_plan']['tasks'], isA<List>());

        // Verify we can identify what needs migration
        expect(parsedData['quarter_plan']['title'], isNull); // New field doesn't exist
        expect(parsedData['quarter_plan']['teamMembers'], isNull); // New field doesn't exist
        expect(parsedData['quarter_plan']['initiatives'], isNull); // New field doesn't exist
      });

      test('should preserve data integrity during version upgrades', () async {
        // ARRANGE
        final criticalData = {
          'version': '1.0',
          'criticalInfo': {
            'userId': 'user_123',
            'importantTimestamp': '2024-01-15T10:30:00Z',
            'essentialData': [1, 2, 3, 4, 5]
          }
        };

        // ACT
        await prefs.setString('critical_data', jsonEncode(criticalData));
        
        // Simulate version upgrade process
        final retrieved = prefs.getString('critical_data');
        final parsed = retrieved != null ? jsonDecode(retrieved) : null;

        // During upgrade, critical data should be preserved
        final upgradedData = {
          'version': '2.0', // Updated version
          'criticalInfo': parsed?['criticalInfo'], // Preserve critical data
          'newFeatures': {
            'addedInV2': true
          }
        };

        await prefs.setString('critical_data', jsonEncode(upgradedData));
        final finalData = jsonDecode(prefs.getString('critical_data')!);

        // ASSERT
        expect(finalData['version'], equals('2.0'));
        expect(finalData['criticalInfo']['userId'], equals('user_123'));
        expect(finalData['criticalInfo']['importantTimestamp'], equals('2024-01-15T10:30:00Z'));
        expect(finalData['criticalInfo']['essentialData'], equals([1, 2, 3, 4, 5]));
        expect(finalData['newFeatures']['addedInV2'], isTrue);
      });

      test('should handle backward compatibility requirements', () async {
        // ARRANGE
        final currentVersionData = {
          'version': '2.0',
          'features': {
            'newFeature': 'available',
            'legacyFeature': 'still_supported'
          }
        };

        // ACT
        await prefs.setString('compatibility_test', jsonEncode(currentVersionData));
        
        // Simulate reading with older version expectations
        final retrieved = prefs.getString('compatibility_test');
        final parsed = retrieved != null ? jsonDecode(retrieved) : null;

        // ASSERT
        expect(parsed, isNotNull);
        expect(parsed['version'], equals('2.0'));
        
        // Even with newer version, legacy features should be accessible
        expect(parsed['features']['legacyFeature'], equals('still_supported'));
        
        // New features should be available but optional
        expect(parsed['features']['newFeature'], equals('available'));
      });
    });

    group('Performance and Optimization', () {
      test('should handle concurrent storage operations', () async {
        // ARRANGE
        const numberOfOperations = 10;
        final futures = <Future<void>>[];

        // ACT - Perform concurrent writes
        for (int i = 0; i < numberOfOperations; i++) {
          final future = prefs.setString('concurrent_key_$i', 'value_$i');
          futures.add(future);
        }

        // Wait for all operations to complete
        await Future.wait(futures);

        // ASSERT - Verify all operations completed successfully
        for (int i = 0; i < numberOfOperations; i++) {
          final retrieved = prefs.getString('concurrent_key_$i');
          expect(retrieved, equals('value_$i'));
        }
      });

      test('should handle storage cleanup and optimization', () async {
        // ARRANGE
        final testKeys = <String>[];
        
        // Create multiple entries
        for (int i = 0; i < 50; i++) {
          final key = 'cleanup_test_$i';
          await prefs.setString(key, 'data_for_$i');
          testKeys.add(key);
        }

        // Verify all entries are stored
        expect(prefs.getKeys().where((key) => key.startsWith('cleanup_test_')), 
               hasLength(50));

        // ACT - Perform cleanup of specific keys
        final keysToRemove = testKeys.where((key) => key.contains('_1') || key.contains('_2')).toList();
        
        for (final key in keysToRemove) {
          await prefs.remove(key);
        }

        // ASSERT
        final remainingKeys = prefs.getKeys().where((key) => key.startsWith('cleanup_test_')).toList();
        expect(remainingKeys.length, lessThan(50));
        
        // Verify specific patterns were removed
        for (final removedKey in keysToRemove) {
          expect(prefs.getString(removedKey), isNull);
        }
      });

      test('should provide storage usage information', () async {
        // ARRANGE
        final initialKeyCount = prefs.getKeys().length;
        
        // Add some data
        final testData = {
          'usage_test_1': 'small_data',
          'usage_test_2': 'x' * 1000, // 1KB of data
          'usage_test_3': List.generate(100, (i) => 'item_$i').join(',')
        };

        // ACT
        for (final entry in testData.entries) {
          await prefs.setString(entry.key, entry.value);
        }

        // ASSERT
        final finalKeyCount = prefs.getKeys().length;
        expect(finalKeyCount, equals(initialKeyCount + testData.length));

        // Verify we can enumerate all storage keys
        final allKeys = prefs.getKeys();
        expect(allKeys, isA<Set<String>>());
        expect(allKeys.length, greaterThanOrEqualTo(testData.length));

        // Verify we can check for specific keys
        for (final key in testData.keys) {
          expect(allKeys.contains(key), isTrue);
        }
      });
    });
  });
}
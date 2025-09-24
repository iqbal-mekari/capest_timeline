/// Unit tests for ApplicationState entity.
/// 
/// Tests comprehensive functionality including:
/// - Construction and property validation
/// - View mode and settings management
/// - Auto-save and change tracking
/// - Recent plans management
/// - Filter functionality and validation
/// - Serialization and deserialization
library;

import 'package:test/test.dart';

import '../../../lib/features/configuration/domain/entities/application_state.dart';

void main() {
  group('ApplicationState Entity Tests', () {
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;
    late DateTime testLastSaveTime;
    late ApplicationFilters testFilters;

    setUp(() {
      testCreatedAt = DateTime(2024, 6, 1, 10, 0, 0);
      testUpdatedAt = DateTime(2024, 6, 15, 14, 30, 0);
      testLastSaveTime = DateTime(2024, 6, 15, 14, 0, 0);
      testFilters = const ApplicationFilters(
        showCompletedInitiatives: false,
        showInactiveMembers: true,
        roleFilter: {'backend', 'frontend'},
        searchQuery: 'mobile app',
        priorityRange: (5, 9),
        capacityUtilizationRange: (50.0, 150.0),
      );
    });

    group('Construction and Basic Properties', () {
      test('should create ApplicationState with default values', () {
        // Arrange & Act
        const applicationState = ApplicationState();

        // Assert
        expect(applicationState.currentPlanId, isNull);
        expect(applicationState.lastAccessedPlanIds, isEmpty);
        expect(applicationState.viewMode, equals(ViewMode.timeline));
        expect(applicationState.selectedQuarter, isNull);
        expect(applicationState.selectedYear, isNull);
        expect(applicationState.filters, equals(const ApplicationFilters()));
        expect(applicationState.isAutoSaveEnabled, isTrue);
        expect(applicationState.lastSaveTime, isNull);
        expect(applicationState.hasUnsavedChanges, isFalse);
        expect(applicationState.createdAt, isNull);
        expect(applicationState.updatedAt, isNull);
      });

      test('should create ApplicationState with all specified values', () {
        // Arrange & Act
        final applicationState = ApplicationState(
          currentPlanId: 'plan001',
          lastAccessedPlanIds: ['plan001', 'plan002', 'plan003'],
          viewMode: ViewMode.capacity,
          selectedQuarter: 3,
          selectedYear: 2024,
          filters: testFilters,
          isAutoSaveEnabled: false,
          lastSaveTime: testLastSaveTime,
          hasUnsavedChanges: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(applicationState.currentPlanId, equals('plan001'));
        expect(applicationState.lastAccessedPlanIds, equals(['plan001', 'plan002', 'plan003']));
        expect(applicationState.viewMode, equals(ViewMode.capacity));
        expect(applicationState.selectedQuarter, equals(3));
        expect(applicationState.selectedYear, equals(2024));
        expect(applicationState.filters, equals(testFilters));
        expect(applicationState.isAutoSaveEnabled, isFalse);
        expect(applicationState.lastSaveTime, equals(testLastSaveTime));
        expect(applicationState.hasUnsavedChanges, isTrue);
        expect(applicationState.createdAt, equals(testCreatedAt));
        expect(applicationState.updatedAt, equals(testUpdatedAt));
      });
    });

    group('Computed Properties', () {
      test('should calculate effective quarter/year from current date when none selected', () {
        // Arrange
        const applicationState = ApplicationState();

        // Act
        final (quarter, year) = applicationState.effectiveQuarterYear;

        // Assert
        final now = DateTime.now();
        final expectedQuarter = ((now.month - 1) ~/ 3) + 1;
        final expectedYear = now.year;
        
        expect(quarter, equals(expectedQuarter));
        expect(year, equals(expectedYear));
      });

      test('should return selected quarter/year when specified', () {
        // Arrange
        const applicationState = ApplicationState(
          selectedQuarter: 2,
          selectedYear: 2025,
        );

        // Act
        final (quarter, year) = applicationState.effectiveQuarterYear;

        // Assert
        expect(quarter, equals(2));
        expect(year, equals(2025));
      });

      test('should detect active plan correctly', () {
        // Arrange
        const withActivePlan = ApplicationState(currentPlanId: 'plan123');
        const withEmptyPlan = ApplicationState(currentPlanId: '');
        const withoutPlan = ApplicationState();

        // Act & Assert
        expect(withActivePlan.hasActivePlan, isTrue);
        expect(withEmptyPlan.hasActivePlan, isFalse);
        expect(withoutPlan.hasActivePlan, isFalse);
      });

      test('should detect auto-save due when enabled with unsaved changes', () {
        // Arrange
        final oldSaveTime = DateTime.now().subtract(const Duration(minutes: 1));
        final recentSaveTime = DateTime.now().subtract(const Duration(seconds: 10));

        final autosaveDue = ApplicationState(
          isAutoSaveEnabled: true,
          hasUnsavedChanges: true,
          lastSaveTime: oldSaveTime,
        );

        final autosaveNotDue = ApplicationState(
          isAutoSaveEnabled: true,
          hasUnsavedChanges: true,
          lastSaveTime: recentSaveTime,
        );

        final noUnsavedChanges = ApplicationState(
          isAutoSaveEnabled: true,
          hasUnsavedChanges: false,
          lastSaveTime: oldSaveTime,
        );

        final autosaveDisabled = ApplicationState(
          isAutoSaveEnabled: false,
          hasUnsavedChanges: true,
          lastSaveTime: oldSaveTime,
        );

        // Act & Assert
        expect(autosaveDue.isAutoSaveDue, isTrue);
        expect(autosaveNotDue.isAutoSaveDue, isFalse);
        expect(noUnsavedChanges.isAutoSaveDue, isFalse);
        expect(autosaveDisabled.isAutoSaveDue, isFalse);
      });

      test('should detect auto-save due when no save time exists', () {
        // Arrange
        const autosaveDue = ApplicationState(
          isAutoSaveEnabled: true,
          hasUnsavedChanges: true,
          lastSaveTime: null,
        );

        // Act & Assert
        expect(autosaveDue.isAutoSaveDue, isTrue);
      });
    });

    group('Plan Management', () {
      test('should update current plan and manage recent plans list', () {
        // Arrange
        const initialState = ApplicationState(
          lastAccessedPlanIds: ['plan002', 'plan003', 'plan004'],
        );

        // Act
        final updatedState = initialState.withCurrentPlan('plan001');

        // Assert
        expect(updatedState.currentPlanId, equals('plan001'));
        expect(updatedState.lastAccessedPlanIds.first, equals('plan001'));
        expect(updatedState.lastAccessedPlanIds.contains('plan002'), isTrue);
        expect(updatedState.hasUnsavedChanges, isTrue);
        expect(updatedState.updatedAt, isNotNull);
      });

      test('should remove duplicates from recent plans when adding existing plan', () {
        // Arrange
        const initialState = ApplicationState(
          lastAccessedPlanIds: ['plan001', 'plan002', 'plan003'],
        );

        // Act
        final updatedState = initialState.withCurrentPlan('plan002');

        // Assert
        expect(updatedState.currentPlanId, equals('plan002'));
        expect(updatedState.lastAccessedPlanIds, equals(['plan002', 'plan001', 'plan003']));
      });

      test('should limit recent plans list to maximum size', () {
        // Arrange
        final manyPlans = List.generate(15, (index) => 'plan${index + 1}');
        final initialState = ApplicationState(
          lastAccessedPlanIds: manyPlans,
        );

        // Act
        final updatedState = initialState.withCurrentPlan('newPlan');

        // Assert
        expect(updatedState.lastAccessedPlanIds.length, equals(ApplicationState.maxRecentPlans));
        expect(updatedState.lastAccessedPlanIds.first, equals('newPlan'));
      });

      test('should handle empty string as effectively clearing plan', () {
        // Arrange
        const initialState = ApplicationState(
          currentPlanId: 'plan001',
          lastAccessedPlanIds: ['plan001', 'plan002'],
        );

        // Act
        final updatedState = initialState.withCurrentPlan('');

        // Assert
        expect(updatedState.currentPlanId, equals(''));
        expect(updatedState.hasActivePlan, isFalse); // Empty string means no active plan
        expect(updatedState.lastAccessedPlanIds, equals(['', 'plan001', 'plan002'])); // Empty string is added to recent plans
        expect(updatedState.hasUnsavedChanges, isTrue);
      });
    });

    group('View Settings Management', () {
      test('should update view mode', () {
        // Arrange
        const initialState = ApplicationState(viewMode: ViewMode.timeline);

        // Act
        final updatedState = initialState.withViewSettings(viewMode: ViewMode.kanban);

        // Assert
        expect(updatedState.viewMode, equals(ViewMode.kanban));
        expect(updatedState.hasUnsavedChanges, isTrue);
        expect(updatedState.updatedAt, isNotNull);
      });

      test('should update selected quarter and year', () {
        // Arrange
        const initialState = ApplicationState(
          selectedQuarter: 1,
          selectedYear: 2024,
        );

        // Act
        final updatedState = initialState.withViewSettings(
          quarter: 3,
          year: 2025,
        );

        // Assert
        expect(updatedState.selectedQuarter, equals(3));
        expect(updatedState.selectedYear, equals(2025));
        expect(updatedState.hasUnsavedChanges, isTrue);
      });

      test('should preserve existing values when updating partial view settings', () {
        // Arrange
        const initialState = ApplicationState(
          viewMode: ViewMode.capacity,
          selectedQuarter: 2,
          selectedYear: 2024,
        );

        // Act
        final updatedState = initialState.withViewSettings(viewMode: ViewMode.table);

        // Assert
        expect(updatedState.viewMode, equals(ViewMode.table));
        expect(updatedState.selectedQuarter, equals(2)); // Preserved
        expect(updatedState.selectedYear, equals(2024)); // Preserved
      });
    });

    group('Save State Management', () {
      test('should mark state as saved', () {
        // Arrange
        const initialState = ApplicationState(
          hasUnsavedChanges: true,
          lastSaveTime: null,
        );

        // Act
        final savedState = initialState.markAsSaved();

        // Assert
        expect(savedState.hasUnsavedChanges, isFalse);
        expect(savedState.lastSaveTime, isNotNull);
        expect(savedState.updatedAt, isNotNull);
      });

      test('should mark state as changed', () {
        // Arrange
        const initialState = ApplicationState(
          hasUnsavedChanges: false,
        );

        // Act
        final changedState = initialState.markAsChanged();

        // Assert
        expect(changedState.hasUnsavedChanges, isTrue);
        expect(changedState.updatedAt, isNotNull);
      });
    });

    group('Validation', () {
      test('should validate correct ApplicationState successfully', () {
        // Arrange
        final validState = ApplicationState(
          selectedQuarter: 2,
          selectedYear: 2024,
          lastAccessedPlanIds: ['plan1', 'plan2'],
          filters: const ApplicationFilters(),
        );

        // Act
        final result = validState.validate();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail validation for invalid quarter', () {
        // Arrange
        const invalidQuarter1 = ApplicationState(selectedQuarter: 0);
        const invalidQuarter2 = ApplicationState(selectedQuarter: 5);

        // Act
        final result1 = invalidQuarter1.validate();
        final result2 = invalidQuarter2.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), contains('Selected quarter must be between 1 and 4'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), contains('Selected quarter must be between 1 and 4'));
      });

      test('should fail validation for invalid year', () {
        // Arrange
        const invalidYear1 = ApplicationState(selectedYear: 2019);
        const invalidYear2 = ApplicationState(selectedYear: 2051);

        // Act
        final result1 = invalidYear1.validate();
        final result2 = invalidYear2.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), contains('Selected year must be between 2020 and 2050'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), contains('Selected year must be between 2020 and 2050'));
      });

      test('should fail validation for too many recent plans', () {
        // Arrange
        final tooManyPlans = List.generate(15, (index) => 'plan$index');
        final invalidState = ApplicationState(lastAccessedPlanIds: tooManyPlans);

        // Act
        final result = invalidState.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Recent plans list cannot exceed ${ApplicationState.maxRecentPlans} items'));
      });

      test('should fail validation for duplicate plan IDs in recent list', () {
        // Arrange
        const invalidState = ApplicationState(
          lastAccessedPlanIds: ['plan1', 'plan2', 'plan1'], // Duplicate plan1
        );

        // Act
        final result = invalidState.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Recent plans list contains duplicate IDs'));
      });

      test('should fail validation when filters validation fails', () {
        // Arrange
        const invalidFilters = ApplicationFilters(
          priorityRange: (11, 15), // Invalid range
        );
        const invalidState = ApplicationState(filters: invalidFilters);

        // Act
        final result = invalidState.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Filters validation failed'));
      });

      test('should accumulate multiple validation errors', () {
        // Arrange
        final tooManyPlans = List.generate(15, (index) => 'plan$index');
        final invalidState = ApplicationState(
          selectedQuarter: 0,
          selectedYear: 2051,
          lastAccessedPlanIds: tooManyPlans,
        );

        // Act
        final result = invalidState.validate();

        // Assert
        expect(result.isError, isTrue);
        final allErrors = result.error.allErrors.join(' ');
        expect(allErrors, contains('Selected quarter must be between 1 and 4'));
        expect(allErrors, contains('Selected year must be between 2020 and 2050'));
        expect(allErrors, contains('Recent plans list cannot exceed'));
      });
    });

    group('Serialization', () {
      test('should serialize to Map correctly', () {
        // Arrange
        final applicationState = ApplicationState(
          currentPlanId: 'plan001',
          lastAccessedPlanIds: ['plan001', 'plan002'],
          viewMode: ViewMode.capacity,
          selectedQuarter: 3,
          selectedYear: 2024,
          filters: testFilters,
          isAutoSaveEnabled: false,
          lastSaveTime: testLastSaveTime,
          hasUnsavedChanges: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = applicationState.toMap();

        // Assert
        expect(map['currentPlanId'], equals('plan001'));
        expect(map['lastAccessedPlanIds'], equals(['plan001', 'plan002']));
        expect(map['viewMode'], equals('capacity'));
        expect(map['selectedQuarter'], equals(3));
        expect(map['selectedYear'], equals(2024));
        expect(map['filters'], isA<Map<String, dynamic>>());
        expect(map['isAutoSaveEnabled'], isFalse);
        expect(map['lastSaveTime'], equals(testLastSaveTime.toIso8601String()));
        expect(map['hasUnsavedChanges'], isTrue);
        expect(map['createdAt'], equals(testCreatedAt.toIso8601String()));
        expect(map['updatedAt'], equals(testUpdatedAt.toIso8601String()));
      });

      test('should deserialize from Map correctly', () {
        // Arrange
        final map = {
          'currentPlanId': 'plan002',
          'lastAccessedPlanIds': ['plan002', 'plan003'],
          'viewMode': 'table',
          'selectedQuarter': 4,
          'selectedYear': 2025,
          'filters': testFilters.toMap(),
          'isAutoSaveEnabled': false,
          'lastSaveTime': testLastSaveTime.toIso8601String(),
          'hasUnsavedChanges': true,
          'createdAt': testCreatedAt.toIso8601String(),
          'updatedAt': testUpdatedAt.toIso8601String(),
        };

        // Act
        final applicationState = ApplicationState.fromMap(map);

        // Assert
        expect(applicationState.currentPlanId, equals('plan002'));
        expect(applicationState.lastAccessedPlanIds, equals(['plan002', 'plan003']));
        expect(applicationState.viewMode, equals(ViewMode.table));
        expect(applicationState.selectedQuarter, equals(4));
        expect(applicationState.selectedYear, equals(2025));
        expect(applicationState.filters, equals(testFilters));
        expect(applicationState.isAutoSaveEnabled, isFalse);
        expect(applicationState.lastSaveTime, equals(testLastSaveTime));
        expect(applicationState.hasUnsavedChanges, isTrue);
        expect(applicationState.createdAt, equals(testCreatedAt));
        expect(applicationState.updatedAt, equals(testUpdatedAt));
      });

      test('should handle serialization round-trip correctly', () {
        // Arrange
        final originalState = ApplicationState(
          currentPlanId: 'plan003',
          lastAccessedPlanIds: ['plan003', 'plan001'],
          viewMode: ViewMode.kanban,
          selectedQuarter: 1,
          selectedYear: 2024,
          filters: testFilters,
          isAutoSaveEnabled: true,
          lastSaveTime: testLastSaveTime,
          hasUnsavedChanges: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = originalState.toMap();
        final deserializedState = ApplicationState.fromMap(map);

        // Assert
        expect(deserializedState, equals(originalState));
      });

      test('should handle deserialization with missing optional fields', () {
        // Arrange
        final minimalMap = {
          'viewMode': 'timeline',
        };

        // Act
        final applicationState = ApplicationState.fromMap(minimalMap);

        // Assert
        expect(applicationState.currentPlanId, isNull);
        expect(applicationState.lastAccessedPlanIds, isEmpty);
        expect(applicationState.viewMode, equals(ViewMode.timeline));
        expect(applicationState.selectedQuarter, isNull);
        expect(applicationState.selectedYear, isNull);
        expect(applicationState.filters, equals(const ApplicationFilters()));
        expect(applicationState.isAutoSaveEnabled, isTrue);
        expect(applicationState.lastSaveTime, isNull);
        expect(applicationState.hasUnsavedChanges, isFalse);
        expect(applicationState.createdAt, isNull);
        expect(applicationState.updatedAt, isNull);
      });

      test('should handle invalid view mode gracefully', () {
        // Arrange
        final mapWithInvalidViewMode = {
          'viewMode': 'invalid_mode',
        };

        // Act
        final applicationState = ApplicationState.fromMap(mapWithInvalidViewMode);

        // Assert
        expect(applicationState.viewMode, equals(ViewMode.timeline)); // Default fallback
      });
    });

    group('Copy and Mutation', () {
      test('should create copy with updated fields', () {
        // Arrange
        const originalState = ApplicationState(
          currentPlanId: 'original',
          viewMode: ViewMode.timeline,
          selectedQuarter: 1,
          isAutoSaveEnabled: true,
        );

        // Act
        final updatedState = originalState.copyWith(
          currentPlanId: 'updated',
          viewMode: ViewMode.capacity,
          selectedYear: 2025,
          hasUnsavedChanges: true,
        );

        // Assert
        expect(updatedState.currentPlanId, equals('updated'));
        expect(updatedState.viewMode, equals(ViewMode.capacity));
        expect(updatedState.selectedQuarter, equals(1)); // Preserved
        expect(updatedState.selectedYear, equals(2025));
        expect(updatedState.isAutoSaveEnabled, isTrue); // Preserved
        expect(updatedState.hasUnsavedChanges, isTrue);
      });

      test('should preserve original when no fields updated in copy', () {
        // Arrange
        const originalState = ApplicationState(
          currentPlanId: 'test',
          viewMode: ViewMode.table,
          selectedQuarter: 2,
          selectedYear: 2024,
        );

        // Act
        final copiedState = originalState.copyWith();

        // Assert
        expect(copiedState, equals(originalState));
        expect(identical(copiedState, originalState), isFalse);
      });
    });

    group('Equality and String Representation', () {
      test('should implement equality correctly', () {
        // Arrange
        const state1 = ApplicationState(
          currentPlanId: 'plan001',
          viewMode: ViewMode.timeline,
          selectedQuarter: 2,
        );

        const state2 = ApplicationState(
          currentPlanId: 'plan001',
          viewMode: ViewMode.timeline,
          selectedQuarter: 2,
        );

        const state3 = ApplicationState(
          currentPlanId: 'plan002',
          viewMode: ViewMode.timeline,
          selectedQuarter: 2,
        );

        // Act & Assert
        expect(state1, equals(state2));
        expect(state1, isNot(equals(state3)));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        const applicationState = ApplicationState(
          currentPlanId: 'plan123',
          viewMode: ViewMode.capacity,
          selectedQuarter: 3,
          selectedYear: 2024,
          hasUnsavedChanges: true,
        );

        // Act
        final stringRep = applicationState.toString();

        // Assert
        expect(stringRep, contains('plan123'));
        expect(stringRep, contains('Capacity'));
        expect(stringRep, contains('Q3 2024'));
        expect(stringRep, contains('hasChanges: true'));
      });

      test('should handle missing values in string representation', () {
        // Arrange
        const applicationState = ApplicationState();

        // Act
        final stringRep = applicationState.toString();

        // Assert
        expect(stringRep, contains('currentPlan: null'));
        expect(stringRep, contains('Q? ?'));
        expect(stringRep, contains('hasChanges: false'));
      });
    });
  });

  group('ViewMode Enum Tests', () {
    group('Display Names', () {
      test('should have correct display names', () {
        // Act & Assert
        expect(ViewMode.timeline.displayName, equals('Timeline'));
        expect(ViewMode.capacity.displayName, equals('Capacity'));
        expect(ViewMode.table.displayName, equals('Table'));
        expect(ViewMode.kanban.displayName, equals('Kanban'));
      });
    });

    group('Capability Detection', () {
      test('should detect drag and drop support correctly', () {
        // Act & Assert
        expect(ViewMode.timeline.supportsDragDrop, isTrue);
        expect(ViewMode.kanban.supportsDragDrop, isTrue);
        expect(ViewMode.capacity.supportsDragDrop, isFalse);
        expect(ViewMode.table.supportsDragDrop, isFalse);
      });

      test('should detect time-based views correctly', () {
        // Act & Assert
        expect(ViewMode.timeline.isTimeBased, isTrue);
        expect(ViewMode.capacity.isTimeBased, isFalse);
        expect(ViewMode.table.isTimeBased, isFalse);
        expect(ViewMode.kanban.isTimeBased, isFalse);
      });

      test('should detect capacity display correctly', () {
        // Act & Assert
        expect(ViewMode.timeline.showsCapacity, isTrue);
        expect(ViewMode.capacity.showsCapacity, isTrue);
        expect(ViewMode.table.showsCapacity, isFalse);
        expect(ViewMode.kanban.showsCapacity, isFalse);
      });
    });
  });

  group('ApplicationFilters Tests', () {
    group('Construction and Basic Properties', () {
      test('should create ApplicationFilters with default values', () {
        // Arrange & Act
        const filters = ApplicationFilters();

        // Assert
        expect(filters.showCompletedInitiatives, isTrue);
        expect(filters.showInactiveMembers, isFalse);
        expect(filters.roleFilter, isEmpty);
        expect(filters.searchQuery, equals(''));
        expect(filters.priorityRange, equals((1, 10)));
        expect(filters.capacityUtilizationRange, equals((0.0, 200.0)));
        expect(filters.hasActiveFilters, isFalse);
      });

      test('should create ApplicationFilters with specified values', () {
        // Arrange & Act
        const filters = ApplicationFilters(
          showCompletedInitiatives: false,
          showInactiveMembers: true,
          roleFilter: {'backend', 'qa'},
          searchQuery: 'mobile',
          priorityRange: (3, 8),
          capacityUtilizationRange: (25.0, 150.0),
        );

        // Assert
        expect(filters.showCompletedInitiatives, isFalse);
        expect(filters.showInactiveMembers, isTrue);
        expect(filters.roleFilter, equals({'backend', 'qa'}));
        expect(filters.searchQuery, equals('mobile'));
        expect(filters.priorityRange, equals((3, 8)));
        expect(filters.capacityUtilizationRange, equals((25.0, 150.0)));
        expect(filters.hasActiveFilters, isTrue);
      });
    });

    group('Active Filters Detection', () {
      test('should detect active filters correctly', () {
        // Arrange
        const noActiveFilters = ApplicationFilters();
        
        const completedHidden = ApplicationFilters(showCompletedInitiatives: false);
        const inactiveShown = ApplicationFilters(showInactiveMembers: true);
        const withRoleFilter = ApplicationFilters(roleFilter: {'backend'});
        const withSearchQuery = ApplicationFilters(searchQuery: 'test');
        const withPriorityRange = ApplicationFilters(priorityRange: (5, 8));
        const withCapacityRange = ApplicationFilters(capacityUtilizationRange: (50.0, 100.0));

        // Act & Assert
        expect(noActiveFilters.hasActiveFilters, isFalse);
        expect(completedHidden.hasActiveFilters, isTrue);
        expect(inactiveShown.hasActiveFilters, isTrue);
        expect(withRoleFilter.hasActiveFilters, isTrue);
        expect(withSearchQuery.hasActiveFilters, isTrue);
        expect(withPriorityRange.hasActiveFilters, isTrue);
        expect(withCapacityRange.hasActiveFilters, isTrue);
      });
    });

    group('Validation', () {
      test('should validate correct ApplicationFilters successfully', () {
        // Arrange
        const validFilters = ApplicationFilters(
          priorityRange: (3, 8),
          capacityUtilizationRange: (25.0, 175.0),
        );

        // Act
        final result = validFilters.validate();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail validation for invalid priority range minimum', () {
        // Arrange
        const invalidFilters = ApplicationFilters(priorityRange: (0, 5));

        // Act
        final result = invalidFilters.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Priority range minimum must be between 1 and 10'));
      });

      test('should fail validation for invalid priority range maximum', () {
        // Arrange
        const invalidFilters = ApplicationFilters(priorityRange: (5, 11));

        // Act
        final result = invalidFilters.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Priority range maximum must be between 1 and 10'));
      });

      test('should fail validation when priority minimum exceeds maximum', () {
        // Arrange
        const invalidFilters = ApplicationFilters(priorityRange: (8, 5));

        // Act
        final result = invalidFilters.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Priority range minimum cannot exceed maximum'));
      });

      test('should fail validation for negative capacity utilization minimum', () {
        // Arrange
        const invalidFilters = ApplicationFilters(capacityUtilizationRange: (-10.0, 100.0));

        // Act
        final result = invalidFilters.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Capacity utilization range minimum cannot be negative'));
      });

      test('should fail validation for excessive capacity utilization maximum', () {
        // Arrange
        const invalidFilters = ApplicationFilters(capacityUtilizationRange: (50.0, 600.0));

        // Act
        final result = invalidFilters.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Capacity utilization range maximum cannot exceed 500%'));
      });

      test('should fail validation when capacity minimum exceeds maximum', () {
        // Arrange
        const invalidFilters = ApplicationFilters(capacityUtilizationRange: (150.0, 100.0));

        // Act
        final result = invalidFilters.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Capacity utilization range minimum cannot exceed maximum'));
      });

      test('should accumulate multiple validation errors', () {
        // Arrange
        const invalidFilters = ApplicationFilters(
          priorityRange: (0, 11),
          capacityUtilizationRange: (-10.0, 600.0),
        );

        // Act
        final result = invalidFilters.validate();

        // Assert
        expect(result.isError, isTrue);
        final allErrors = result.error.allErrors.join(' ');
        expect(allErrors, contains('Priority range minimum must be between 1 and 10'));
        expect(allErrors, contains('Priority range maximum must be between 1 and 10'));
        expect(allErrors, contains('Capacity utilization range minimum cannot be negative'));
        expect(allErrors, contains('Capacity utilization range maximum cannot exceed 500%'));
      });
    });

    group('Serialization', () {
      test('should serialize ApplicationFilters to Map correctly', () {
        // Arrange
        const filters = ApplicationFilters(
          showCompletedInitiatives: false,
          showInactiveMembers: true,
          roleFilter: {'backend', 'frontend'},
          searchQuery: 'mobile app',
          priorityRange: (3, 8),
          capacityUtilizationRange: (50.0, 150.0),
        );

        // Act
        final map = filters.toMap();

        // Assert
        expect(map['showCompletedInitiatives'], isFalse);
        expect(map['showInactiveMembers'], isTrue);
        expect(map['roleFilter'], equals(['backend', 'frontend']));
        expect(map['searchQuery'], equals('mobile app'));
        expect(map['priorityRange'], equals([3, 8]));
        expect(map['capacityUtilizationRange'], equals([50.0, 150.0]));
      });

      test('should deserialize ApplicationFilters from Map correctly', () {
        // Arrange
        final map = {
          'showCompletedInitiatives': false,
          'showInactiveMembers': true,
          'roleFilter': ['qa', 'design'],
          'searchQuery': 'user interface',
          'priorityRange': [4, 9],
          'capacityUtilizationRange': [75.0, 125.0],
        };

        // Act
        final filters = ApplicationFilters.fromMap(map);

        // Assert
        expect(filters.showCompletedInitiatives, isFalse);
        expect(filters.showInactiveMembers, isTrue);
        expect(filters.roleFilter, equals({'qa', 'design'}));
        expect(filters.searchQuery, equals('user interface'));
        expect(filters.priorityRange, equals((4, 9)));
        expect(filters.capacityUtilizationRange, equals((75.0, 125.0)));
      });

      test('should handle ApplicationFilters serialization round-trip correctly', () {
        // Arrange
        const originalFilters = ApplicationFilters(
          showCompletedInitiatives: false,
          showInactiveMembers: true,
          roleFilter: {'devops', 'qa'},
          searchQuery: 'database migration',
          priorityRange: (2, 7),
          capacityUtilizationRange: (25.0, 175.0),
        );

        // Act
        final map = originalFilters.toMap();
        final deserializedFilters = ApplicationFilters.fromMap(map);

        // Assert
        expect(deserializedFilters, equals(originalFilters));
      });

      test('should handle ApplicationFilters deserialization with missing fields', () {
        // Arrange
        final minimalMap = <String, dynamic>{};

        // Act
        final filters = ApplicationFilters.fromMap(minimalMap);

        // Assert
        expect(filters.showCompletedInitiatives, isTrue);
        expect(filters.showInactiveMembers, isFalse);
        expect(filters.roleFilter, isEmpty);
        expect(filters.searchQuery, equals(''));
        expect(filters.priorityRange, equals((1, 10)));
        expect(filters.capacityUtilizationRange, equals((0.0, 200.0)));
      });
    });

    group('Copy and Mutation', () {
      test('should create copy with updated fields', () {
        // Arrange
        const originalFilters = ApplicationFilters(
          showCompletedInitiatives: true,
          showInactiveMembers: false,
          roleFilter: {'backend'},
          searchQuery: 'original',
          priorityRange: (1, 10),
        );

        // Act
        final updatedFilters = originalFilters.copyWith(
          showCompletedInitiatives: false,
          roleFilter: {'frontend', 'qa'},
          searchQuery: 'updated',
        );

        // Assert
        expect(updatedFilters.showCompletedInitiatives, isFalse);
        expect(updatedFilters.showInactiveMembers, isFalse); // Preserved
        expect(updatedFilters.roleFilter, equals({'frontend', 'qa'}));
        expect(updatedFilters.searchQuery, equals('updated'));
        expect(updatedFilters.priorityRange, equals((1, 10))); // Preserved
      });

      test('should preserve original when no fields updated in copy', () {
        // Arrange
        const originalFilters = ApplicationFilters(
          showCompletedInitiatives: false,
          roleFilter: {'backend', 'frontend'},
          searchQuery: 'test query',
        );

        // Act
        final copiedFilters = originalFilters.copyWith();

        // Assert
        expect(copiedFilters, equals(originalFilters));
        expect(identical(copiedFilters, originalFilters), isFalse);
      });
    });

    group('Equality and String Representation', () {
      test('should implement equality correctly', () {
        // Arrange
        const filters1 = ApplicationFilters(
          showCompletedInitiatives: false,
          roleFilter: {'backend'},
          searchQuery: 'test',
        );

        const filters2 = ApplicationFilters(
          showCompletedInitiatives: false,
          roleFilter: {'backend'},
          searchQuery: 'test',
        );

        const filters3 = ApplicationFilters(
          showCompletedInitiatives: true,
          roleFilter: {'backend'},
          searchQuery: 'test',
        );

        // Act & Assert
        expect(filters1, equals(filters2));
        expect(filters1, isNot(equals(filters3)));
        expect(filters1.hashCode, equals(filters2.hashCode));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        const filters = ApplicationFilters(
          showCompletedInitiatives: false,
          showInactiveMembers: true,
          roleFilter: {'backend', 'frontend'},
          searchQuery: 'mobile app',
        );

        // Act
        final stringRep = filters.toString();

        // Assert
        expect(stringRep, contains('completed: false'));
        expect(stringRep, contains('inactive: true'));
        expect(stringRep, contains('roles: 2'));
        expect(stringRep, contains('search: "mobile app"'));
        expect(stringRep, contains('active: true'));
      });
    });
  });
}
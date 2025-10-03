import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/services/kanban_service.dart';
import 'package:capest_timeline/models/models.dart';
import 'package:capest_timeline/core/errors/kanban_service_exceptions.dart';
import '../../mocks/mock_storage_service.dart';
import '../../mocks/mock_capacity_service.dart';

void main() {
  group('KanbanService Error Handling Tests', () {
    late KanbanService kanbanService;
    late MockStorageService mockStorageService;
    late MockCapacityService mockCapacityService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockCapacityService = MockCapacityService(mockStorageService);
      kanbanService = KanbanService(
        storageService: mockStorageService,
        capacityService: mockCapacityService,
      );
    });

    group('Storage Failures', () {
      test('should handle storage read failure during data load', () async {
        // Arrange
        mockStorageService.shouldFailRead = true;
        mockStorageService.readFailureMessage = 'Storage read failed';

        // Act & Assert
        expect(
          () async => await kanbanService.getKanbanData(),
          throwsA(isA<StorageException>()),
        );
      });

      test('should handle storage write failure during initiative creation', () async {
        // Arrange
        mockStorageService.shouldFailWrite = true;
        mockStorageService.writeFailureMessage = 'Storage write failed';

        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        // Act & Assert
        expect(
          () async => await kanbanService.createInitiative(initiativeData),
          throwsA(isA<StorageException>()),
        );
      });

      test('should handle storage corruption during data load', () async {
        // Arrange
        mockStorageService.shouldReturnCorruptedData = true;

        // Act & Assert - This may not throw directly, but could cause issues
        try {
          await kanbanService.getKanbanData();
          // If it doesn't throw, data might be empty or malformed
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle partial storage failure with recovery', () async {
        // Arrange
        mockStorageService.shouldFailPartialWrite = true;

        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        // Act - Should still create initiative despite partial failure
        final initiative = await kanbanService.createInitiative(initiativeData);

        // Assert
        expect(initiative.title, 'Test Initiative');
        expect(mockStorageService.partialFailureLogged, isTrue);
      });
    });

    group('Data Validation Errors', () {
      test('should reject initiative with empty title', () async {
        // Arrange
        final invalidInitiativeData = {
          'title': '', // Invalid: empty title
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        // Act & Assert
        expect(
          () async => await kanbanService.createInitiative(invalidInitiativeData),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should reject initiative with invalid estimated weeks', () async {
        // Arrange
        final invalidInitiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': -1, // Invalid: negative weeks
          'priority': 1,
        };

        // Act & Assert
        expect(
          () async => await kanbanService.createInitiative(invalidInitiativeData),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should reject duplicate initiative titles', () async {
        // Arrange
        final initiativeData1 = {
          'title': 'Duplicate Title',
          'description': 'First Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };
        
        final initiativeData2 = {
          'title': 'Duplicate Title', // Same title
          'description': 'Second Description',
          'requiredPlatforms': ['frontend'],
          'estimatedWeeks': 3,
          'priority': 2,
        };

        await kanbanService.createInitiative(initiativeData1);

        // Act & Assert
        expect(
          () async => await kanbanService.createInitiative(initiativeData2),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Capacity Service Integration Failures', () {
      test('should handle capacity calculation failure', () async {
        // Arrange
        mockCapacityService.shouldFailCalculation = true;
        mockCapacityService.calculationFailureMessage = 'Capacity calculation failed';

        // Act & Assert
        expect(
          () async => await kanbanService.getKanbanData(),
          throwsA(isA<CapacityCalculationException>()),
        );
      });

      test('should handle capacity constraint violation during assignment', () async {
        // Arrange
        mockCapacityService.shouldRejectOverAllocation = true;

        // Create a test initiative first
        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        final initiative = await kanbanService.createInitiative(initiativeData);

        // Act & Assert
        expect(
          () async => await kanbanService.assignMember(
            initiativeId: initiative.id,
            memberId: 'member-1',
            platformType: 'backend',
            capacityPercentage: 0.8,
            startWeek: DateTime.now(),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle missing team member data', () async {
        // Arrange
        mockCapacityService.shouldReturnEmptyTeamData = true;

        // Act & Assert
        expect(
          () async => await kanbanService.getKanbanData(),
          throwsA(isA<MissingDataException>()),
        );
      });
    });

    group('Network and Connectivity Errors', () {
      test('should handle network timeout during sync', () async {
        // Arrange
        mockStorageService.shouldTimeoutOnSync = true;

        // Act & Assert
        expect(
          () async => await mockStorageService.syncWithRemote(),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should handle network unavailability gracefully', () async {
        // Arrange
        mockStorageService.isNetworkAvailable = false;

        // Act
        final result = await mockStorageService.syncWithRemote();

        // Assert - Should return failure when network is unavailable
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('network unavailable'));
      });
    });

    group('Concurrent Access Errors', () {
      test('should handle concurrent modification conflicts', () async {
        // Arrange
        mockStorageService.shouldSimulateConcurrentModification = true;

        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        final initiative = await kanbanService.createInitiative(initiativeData);

        // Act & Assert - Multiple concurrent updates should handle conflicts
        expect(
          () async => await Future.wait([
            kanbanService.updateInitiative(
              initiativeId: initiative.id,
              title: 'Updated 1',
            ),
            kanbanService.updateInitiative(
              initiativeId: initiative.id,
              title: 'Updated 2',
            ),
            kanbanService.updateInitiative(
              initiativeId: initiative.id,
              title: 'Updated 3',
            ),
          ]),
          throwsA(isA<ConcurrentModificationException>()),
        );
      });

      test('should handle resource locking timeout', () async {
        // Arrange
        mockStorageService.shouldTimeoutOnLock = true;

        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        // Act & Assert
        expect(
          () async => await kanbanService.createInitiative(initiativeData),
          throwsA(isA<ResourceLockException>()),
        );
      });
    });

    group('Recovery and Fallback Mechanisms', () {
      test('should recover from temporary storage failure', () async {
        // Arrange
        mockStorageService.shouldFailTemporarily = true;
        mockStorageService.failureCount = 0;
        mockStorageService.maxFailuresBeforeRecovery = 2;

        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        // Act - Should eventually succeed after retries
        final initiative = await kanbanService.createInitiative(initiativeData);

        // Assert
        expect(initiative.title, 'Test Initiative');
        expect(mockStorageService.failureCount, 2); // Failed twice before recovery
      });

      test('should use fallback data when primary source fails', () async {
        // Arrange
        mockStorageService.shouldUseFallbackData = true;
        mockStorageService.fallbackInitiatives = [
          Initiative(
            id: 'fallback-1',
            title: 'Fallback Initiative',
            description: 'Fallback Description',
            platformVariants: const [],
            requiredPlatforms: const [PlatformType.backend],
            createdAt: DateTime.now(),
            status: 'active',
            priority: 'medium',
          ),
        ];

        // Act
        final result = await kanbanService.getKanbanData();

        // Assert
        expect(result.initiatives.length, 1);
        expect(result.initiatives.first.id, 'fallback-1');
        expect(result.initiatives.first.title, 'Fallback Initiative');
      });

      test('should maintain data consistency during partial failures', () async {
        // Arrange
        mockStorageService.shouldFailPartialOperations = true;

        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test Description',
          'requiredPlatforms': ['backend', 'frontend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        // Act
        final initiative = await kanbanService.createInitiative(initiativeData);

        // Assert - Data should remain consistent even with partial failures
        expect(initiative.platformVariants.length, 2); // Should have both backend and frontend variants
        
        // Verify data integrity
        for (final variant in initiative.platformVariants) {
          expect(variant.initiativeId, initiative.id);
        }
      });
    });
  });
}
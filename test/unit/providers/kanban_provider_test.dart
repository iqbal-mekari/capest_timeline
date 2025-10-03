import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:capest_timeline/providers/kanban_provider.dart';
import 'package:capest_timeline/services/kanban_service.dart';
import 'package:capest_timeline/services/storage_service.dart';
import 'package:capest_timeline/models/models.dart';

// Generate mocks
@GenerateMocks([KanbanService, StorageService])
import 'kanban_provider_test.mocks.dart';

void main() {
  group('KanbanProvider', () {
    late KanbanProvider provider;
    late MockKanbanService mockKanbanService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockKanbanService = MockKanbanService();
      mockStorageService = MockStorageService();
      provider = KanbanProvider(
        kanbanService: mockKanbanService,
        storageService: mockStorageService,
      );
    });

    group('Initialization', () {
      test('should initialize with empty state', () {
        expect(provider.initiatives, isEmpty);
        expect(provider.platformVariants, isEmpty);
        expect(provider.timelineWeeks, isEmpty);
        expect(provider.capacityPeriods, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isFalse);
        expect(provider.errorMessage, isNull);
      });

      test('should load data on initialization', () async {
        // Arrange
        final mockData = KanbanDataResult(
          initiatives: [
            Initiative(
              id: 'init-1',
              title: 'Test Initiative',
              description: 'Test Description',
              requiredPlatforms: [PlatformType.backend],
              priority: '1',
              status: 'active',
              createdAt: DateTime.now(),
              platformVariants: [],
            ),
          ],
          teamMembers: [],
          capacityPeriods: [
            CapacityPeriod(
              weekStart: DateTime(2024, 1, 1),
              weekEnd: DateTime(2024, 1, 7),
              assignments: [],
              totalCapacityAvailable: 40.0,
            ),
          ],
          timelineWeeks: [],
        );

        when(mockKanbanService.getKanbanData(
          startDate: any,
          endDate: any,
        )).thenAnswer((_) async => mockData);

        when(mockStorageService.loadPlatformVariants())
            .thenAnswer((_) async => []);

        // Act
        await provider.initialize();

        // Assert
        expect(provider.initiatives, hasLength(1));
        expect(provider.initiatives.first.title, 'Test Initiative');
        expect(provider.capacityPeriods, hasLength(1));
        expect(provider.timelineWeeks, hasLength(12));
        expect(provider.isLoading, isFalse);
        expect(provider.hasError, isFalse);
      });

      test('should handle initialization error', () async {
        // Arrange
        when(mockKanbanService.getKanbanData(
          startDate: any,
          endDate: any,
        )).thenThrow(Exception('Service error'));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Failed to load kanban data'));
        expect(provider.isLoading, isFalse);
      });
    });

    group('Initiative Management', () {
      test('should create initiative successfully', () async {
        // Arrange
        final initiative = Initiative(
          id: 'init-1',
          title: 'New Initiative',
          description: 'Description',
          requiredPlatforms: [PlatformType.backend],
          priority: '1',
          status: 'active',
          createdAt: DateTime.now(),
          platformVariants: [],
        );

        when(mockKanbanService.createInitiative(any))
            .thenAnswer((_) async => initiative);
        when(mockKanbanService.getKanbanData(
          startDate: any,
          endDate: any,
        )).thenAnswer((_) async => KanbanDataResult(
          initiatives: [],
          teamMembers: [],
          capacityPeriods: [],
          timelineWeeks: [],
        ));
        when(mockStorageService.loadPlatformVariants())
            .thenAnswer((_) async => []);

        // Act
        final result = await provider.createInitiative(initiative);

        // Assert
        expect(result, isTrue);
        verify(mockKanbanService.createInitiative(any)).called(1);
      });

      test('should handle create initiative error', () async {
        // Arrange
        final initiative = Initiative(
          id: 'init-1',
          title: 'New Initiative',
          description: 'Description',
          requiredPlatforms: [PlatformType.backend],
          priority: '1',
          status: 'active',
          createdAt: DateTime.now(),
          platformVariants: [],
        );

        when(mockKanbanService.createInitiative(any))
            .thenThrow(Exception('Create failed'));

        // Act
        final result = await provider.createInitiative(initiative);

        // Assert
        expect(result, isFalse);
        expect(provider.hasError, isTrue);
        expect(provider.errorMessage, contains('Error creating initiative'));
      });
    });

    group('Error Handling', () {
      test('should clear error', () {
        // Act
        provider.clearError();

        // Assert
        expect(provider.hasError, isFalse);
        expect(provider.errorMessage, isNull);
      });
    });

    group('Storage Operations', () {
      test('should save to storage successfully', () async {
        // Arrange
        when(mockStorageService.saveKanbanState(any))
            .thenAnswer((_) async => {});

        // Act
        await provider.saveToStorage();

        // Assert
        expect(provider.hasError, isFalse);
        verify(mockStorageService.saveKanbanState(any)).called(1);
      });
    });
  });
}
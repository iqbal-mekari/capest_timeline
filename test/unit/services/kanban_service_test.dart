import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:capest_timeline/services/kanban_service.dart';
import 'package:capest_timeline/services/storage_service.dart';
import 'package:capest_timeline/services/capacity_service.dart';
import 'package:capest_timeline/models/initiative.dart';
import 'package:capest_timeline/models/platform_variant.dart';
import 'package:capest_timeline/models/team_member.dart';
import 'package:capest_timeline/models/assignment.dart';
import 'package:capest_timeline/models/capacity_period.dart';
import 'package:capest_timeline/models/platform_type.dart';

// Generate mocks for dependencies
@GenerateNiceMocks([
  MockSpec<StorageService>(),
  MockSpec<CapacityService>(),
])
import 'kanban_service_test.mocks.dart';

void main() {
  group('KanbanService Contract Tests', () {
    late KanbanService kanbanService;
    late MockStorageService mockStorageService;
    late MockCapacityService mockCapacityService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockCapacityService = MockCapacityService();
      kanbanService = KanbanService(
        storageService: mockStorageService,
        capacityService: mockCapacityService,
      );
    });

    group('getKanbanData() contract', () {
      test('should return complete kanban data structure', () async {
        // Arrange
        final mockInitiatives = [
          Initiative(
            id: 'init-1',
            title: 'Reimbursement System',
            description: 'Complete reimbursement workflow',
            createdAt: DateTime(2024, 1, 1),
            platformVariants: const [],
            requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
            priority: 'high',
          ),
        ];

        final mockTeamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        final mockCapacityPeriods = [
          CapacityPeriod(
            weekStart: DateTime(2024, 1, 1),
            weekEnd: DateTime(2024, 1, 7),
            assignments: const [],
            totalCapacityAvailable: 5.0,
          ),
        ];

        when(mockStorageService.loadInitiatives())
            .thenAnswer((_) async => mockInitiatives);
        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => mockTeamMembers);
        when(mockCapacityService.getCapacityPeriods(any, any))
            .thenAnswer((_) async => mockCapacityPeriods);

        // Act
        final result = await kanbanService.getKanbanData();

        // Assert
        expect(result, isNotNull);
        expect(result.initiatives, equals(mockInitiatives));
        expect(result.teamMembers, equals(mockTeamMembers));
        expect(result.capacityPeriods, equals(mockCapacityPeriods));
        expect(result.timelineWeeks, isNotEmpty);
        
        // Verify service interactions
        verify(mockStorageService.loadInitiatives()).called(1);
        verify(mockStorageService.loadTeamMembers()).called(1);
        verify(mockCapacityService.getCapacityPeriods(any, any)).called(1);
      });

      test('should handle empty data gracefully', () async {
        // Arrange
        when(mockStorageService.loadInitiatives())
            .thenAnswer((_) async => <Initiative>[]);
        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => <TeamMember>[]);
        when(mockCapacityService.getCapacityPeriods(any, any))
            .thenAnswer((_) async => <CapacityPeriod>[]);

        // Act
        final result = await kanbanService.getKanbanData();

        // Assert
        expect(result.initiatives, isEmpty);
        expect(result.teamMembers, isEmpty);
        expect(result.capacityPeriods, isEmpty);
      });

      test('should propagate storage service errors', () async {
        // Arrange
        when(mockStorageService.loadInitiatives())
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => kanbanService.getKanbanData(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('moveVariantToWeek() contract', () {
      test('should move platform variant to target week successfully', () async {
        // Arrange
        final variant = PlatformVariant(
          id: 'variant-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: '[BE] Test Initiative',
          estimatedWeeks: 4,
          currentWeek: DateTime(2024, 1, 1),
          isAssigned: false,
        );

        final targetWeek = DateTime(2024, 1, 8);

        when(mockStorageService.savePlatformVariant(any))
            .thenAnswer((_) async => {});
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => <Assignment>[]);

        // Act
        await kanbanService.moveVariantToWeek(variant, targetWeek);

        // Assert - Verify the method completed without errors
        verify(mockStorageService.savePlatformVariant(any)).called(1);
        verify(mockStorageService.loadAssignments()).called(1);
      });

      test('should handle storage service errors gracefully', () async {
        // Arrange
        final variant = PlatformVariant(
          id: 'variant-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: '[BE] Test Initiative',
          estimatedWeeks: 4,
          currentWeek: DateTime(2024, 1, 1),
          isAssigned: false,
        );

        when(mockStorageService.savePlatformVariant(any))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => kanbanService.moveVariantToWeek(variant, DateTime(2024, 1, 8)),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('createInitiative() contract', () {
      test('should create initiative with all platform variants', () async {
        // Arrange
        final initiativeData = {
          'title': 'New Reimbursement Feature',
          'description': 'Complete reimbursement workflow',
          'requiredPlatforms': ['backend', 'frontend', 'mobile'],
          'estimatedWeeks': 12,
          'priority': 1,
        };

        when(mockStorageService.loadInitiatives())
            .thenAnswer((_) async => <Initiative>[]);
        when(mockStorageService.saveInitiative(any))
            .thenAnswer((_) async => {});
        when(mockStorageService.savePlatformVariant(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await kanbanService.createInitiative(initiativeData);

        // Assert
        expect(result, isNotNull);
        expect(result.title, equals('New Reimbursement Feature'));
        expect(result.description, equals('Complete reimbursement workflow'));
        expect(result.requiredPlatforms, hasLength(3));
        expect(result.requiredPlatforms, contains(PlatformType.backend));
        expect(result.requiredPlatforms, contains(PlatformType.frontend));
        expect(result.requiredPlatforms, contains(PlatformType.mobile));
        expect(result.totalEffortWeeks, equals(12));
        expect(result.priority, equals('1'));
        
        verify(mockStorageService.saveInitiative(any)).called(1);
        verify(mockStorageService.savePlatformVariant(any)).called(3); // One for each platform
      });

      test('should generate platform variants for each required platform', () async {
        // Arrange
        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test description',
          'requiredPlatforms': ['backend', 'frontend'],
          'estimatedWeeks': 8,
          'priority': 2,
        };

        when(mockStorageService.loadInitiatives())
            .thenAnswer((_) async => <Initiative>[]);
        when(mockStorageService.saveInitiative(any))
            .thenAnswer((_) async => {});
        when(mockStorageService.savePlatformVariant(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await kanbanService.createInitiative(initiativeData);

        // Assert - Should create variants (verified in integration)
        expect(result.requiredPlatforms, hasLength(2));
        verify(mockStorageService.saveInitiative(any)).called(1);
        verify(mockStorageService.savePlatformVariant(any)).called(2); // One for each platform
      });

      test('should reject invalid initiative data', () async {
        // Arrange
        final invalidData = {
          'title': '', // Empty title should be invalid
          'description': 'Test',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 0, // Zero weeks should be invalid
          'priority': 1,
        };

        // Act & Assert
        expect(
          () => kanbanService.createInitiative(invalidData),
          throwsA(isA<ArgumentError>()),
        );
        
        verifyNever(mockStorageService.saveInitiative(any));
      });

      test('should handle storage errors during creation', () async {
        // Arrange
        final initiativeData = {
          'title': 'Test Initiative',
          'description': 'Test',
          'requiredPlatforms': ['backend'],
          'estimatedWeeks': 4,
          'priority': 1,
        };

        when(mockStorageService.loadInitiatives())
            .thenAnswer((_) async => <Initiative>[]);
        when(mockStorageService.saveInitiative(any))
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => kanbanService.createInitiative(initiativeData),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
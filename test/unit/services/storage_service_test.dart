import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capest_timeline/services/storage_service.dart';
import 'package:capest_timeline/models/initiative.dart';
import 'package:capest_timeline/models/platform_variant.dart';
import 'package:capest_timeline/models/team_member.dart';
import 'package:capest_timeline/models/assignment.dart';
import 'package:capest_timeline/models/platform_type.dart';

// Generate mocks for dependencies
@GenerateNiceMocks([
  MockSpec<SharedPreferences>(),
])
import 'storage_service_test.mocks.dart';

void main() {
  group('StorageService Contract Tests', () {
    late StorageService storageService;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      storageService = StorageService(
        sharedPreferences: mockSharedPreferences,
      );
    });

    group('saveKanbanState() contract', () {
      test('should save complete kanban state to storage', () async {
        // Arrange
        final initiatives = [
          Initiative(
            id: 'init-1',
            title: 'Reimbursement System',
            description: 'Complete reimbursement workflow',
            createdAt: DateTime(2024, 1, 1),
            platformVariants: [
              PlatformVariant(
                id: 'variant-1',
                initiativeId: 'init-1',
                platformType: PlatformType.backend,
                title: '[BE] Reimbursement System',
                estimatedWeeks: 4,
                currentWeek: DateTime(2024, 1, 1),
                isAssigned: false,
              ),
              PlatformVariant(
                id: 'variant-2',
                initiativeId: 'init-1',
                platformType: PlatformType.frontend,
                title: '[FE] Reimbursement System',
                estimatedWeeks: 4,
                currentWeek: DateTime(2024, 1, 1),
                isAssigned: false,
              ),
            ],
            requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
            priority: 'high',
          ),
        ];

        final platformVariants = initiatives.first.platformVariants;

        final teamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        final assignments = [
          Assignment(
            id: 'assign-1',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 4,
            capacityPercentage: 0.5,
            startWeek: DateTime(2024, 1, 1),
          ),
        ];

        final kanbanState = {
          'initiatives': initiatives,
          'platformVariants': platformVariants,
          'teamMembers': teamMembers,
          'assignments': assignments,
          'lastUpdated': DateTime.now(),
        };

        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        // Act
        await storageService.saveKanbanState(kanbanState);

        // Assert
        verify(mockSharedPreferences.setString('kanban_initiatives', any)).called(1);
        verify(mockSharedPreferences.setString('kanban_platform_variants', any)).called(1);
        verify(mockSharedPreferences.setString('kanban_team_members', any)).called(1);
        verify(mockSharedPreferences.setString('kanban_assignments', any)).called(1);
        verify(mockSharedPreferences.setString('kanban_state', any)).called(1);
      });

      test('should handle empty state gracefully', () async {
        // Arrange
        final emptyState = {
          'initiatives': <Initiative>[],
          'platformVariants': <PlatformVariant>[],
          'teamMembers': <TeamMember>[],
          'assignments': <Assignment>[],
          'lastUpdated': DateTime.now(),
        };

        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        // Act
        await storageService.saveKanbanState(emptyState);

        // Assert
        verify(mockSharedPreferences.setString('kanban_initiatives', '[]')).called(1);
        verify(mockSharedPreferences.setString('kanban_platform_variants', '[]')).called(1);
        verify(mockSharedPreferences.setString('kanban_team_members', '[]')).called(1);
        verify(mockSharedPreferences.setString('kanban_assignments', '[]')).called(1);
      });

      test('should handle SharedPreferences errors', () async {
        // Arrange
        final kanbanState = {
          'initiatives': <Initiative>[],
          'platformVariants': <PlatformVariant>[],
          'teamMembers': <TeamMember>[],
          'assignments': <Assignment>[],
        };

        when(mockSharedPreferences.setString(any, any))
            .thenThrow(Exception('SharedPreferences error'));

        // Act & Assert
        expect(
          () => storageService.saveKanbanState(kanbanState),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('loadInitiatives() contract', () {
      test('should load initiatives from storage', () async {
        // Arrange
        const initiativesJson = '''[
          {
            "id": "init-1",
            "title": "Test Initiative",
            "description": "Test description",
            "createdAt": "2024-01-01T00:00:00.000",
            "platformVariants": [],
            "requiredPlatforms": ["backend", "frontend"],
            "priority": "high"
          }
        ]''';

        when(mockSharedPreferences.getString('kanban_initiatives'))
            .thenReturn(initiativesJson);

        // Act
        final result = await storageService.loadInitiatives();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('init-1'));
        expect(result.first.title, equals('Test Initiative'));
        expect(result.first.requiredPlatforms, hasLength(2));
        expect(result.first.priority, equals('high'));
        
        verify(mockSharedPreferences.getString('kanban_initiatives')).called(1);
      });

      test('should return empty list when no data stored', () async {
        // Arrange
        when(mockSharedPreferences.getString('kanban_initiatives'))
            .thenReturn(null);

        // Act
        final result = await storageService.loadInitiatives();

        // Assert
        expect(result, isEmpty);
        verify(mockSharedPreferences.getString('kanban_initiatives')).called(1);
      });

      test('should handle malformed JSON gracefully', () async {
        // Arrange
        when(mockSharedPreferences.getString('kanban_initiatives'))
            .thenReturn('invalid json');

        // Act
        final result = await storageService.loadInitiatives();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('loadTeamMembers() contract', () {
      test('should load team members from storage', () async {
        // Arrange
        const teamMembersJson = '''[
          {
            "id": "member-1",
            "name": "John Doe",
            "platformSpecializations": ["backend", "qa"],
            "weeklyCapacity": 1.0,
            "isActive": true
          }
        ]''';

        when(mockSharedPreferences.getString('kanban_team_members'))
            .thenReturn(teamMembersJson);

        // Act
        final result = await storageService.loadTeamMembers();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('member-1'));
        expect(result.first.name, equals('John Doe'));
        expect(result.first.platformSpecializations, hasLength(2));
        expect(result.first.weeklyCapacity, equals(1.0));
        expect(result.first.isActive, isTrue);
        
        verify(mockSharedPreferences.getString('kanban_team_members')).called(1);
      });

      test('should return empty list when no team members stored', () async {
        // Arrange
        when(mockSharedPreferences.getString('kanban_team_members'))
            .thenReturn(null);

        // Act
        final result = await storageService.loadTeamMembers();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('loadAssignments() contract', () {
      test('should load assignments from storage', () async {
        // Arrange
        const assignmentsJson = '''[
          {
            "id": "assign-1",
            "memberId": "member-1",
            "platformType": "backend",
            "allocatedWeeks": 4,
            "capacityPercentage": 0.75,
            "startWeek": "2024-01-01T00:00:00.000",
            "notes": "Backend development tasks"
          }
        ]''';

        when(mockSharedPreferences.getString('kanban_assignments'))
            .thenReturn(assignmentsJson);

        // Act
        final result = await storageService.loadAssignments();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('assign-1'));
        expect(result.first.memberId, equals('member-1'));
        expect(result.first.allocatedWeeks, equals(4));
        expect(result.first.capacityPercentage, equals(0.75));
        expect(result.first.notes, equals('Backend development tasks'));
        
        verify(mockSharedPreferences.getString('kanban_assignments')).called(1);
      });

      test('should return empty list when no assignments stored', () async {
        // Arrange
        when(mockSharedPreferences.getString('kanban_assignments'))
            .thenReturn(null);

        // Act
        final result = await storageService.loadAssignments();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('loadPlatformVariants() contract', () {
      test('should load platform variants from storage', () async {
        // Arrange
        const variantsJson = '''[
          {
            "id": "variant-1",
            "initiativeId": "init-1",
            "platformType": "backend",
            "title": "[BE] Test Initiative",
            "estimatedWeeks": 4,
            "currentWeek": "2024-01-01T00:00:00.000",
            "isAssigned": false
          }
        ]''';

        when(mockSharedPreferences.getString('kanban_platform_variants'))
            .thenReturn(variantsJson);

        // Act
        final result = await storageService.loadPlatformVariants();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.id, equals('variant-1'));
        expect(result.first.initiativeId, equals('init-1'));
        expect(result.first.title, equals('[BE] Test Initiative'));
        expect(result.first.estimatedWeeks, equals(4));
        expect(result.first.isAssigned, isFalse);
        
        verify(mockSharedPreferences.getString('kanban_platform_variants')).called(1);
      });

      test('should return empty list when no variants stored', () async {
        // Arrange
        when(mockSharedPreferences.getString('kanban_platform_variants'))
            .thenReturn(null);

        // Act
        final result = await storageService.loadPlatformVariants();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('clearAllData() contract', () {
      test('should clear all kanban data from storage', () async {
        // Arrange
        when(mockSharedPreferences.remove(any))
            .thenAnswer((_) async => true);

        // Act
        await storageService.clearAllData();

        // Assert
        verify(mockSharedPreferences.remove('kanban_initiatives')).called(1);
        verify(mockSharedPreferences.remove('kanban_platform_variants')).called(1);
        verify(mockSharedPreferences.remove('kanban_team_members')).called(1);
        verify(mockSharedPreferences.remove('kanban_assignments')).called(1);
        verify(mockSharedPreferences.remove('kanban_state')).called(1);
      });

      test('should handle SharedPreferences errors during clear', () async {
        // Arrange
        when(mockSharedPreferences.remove(any))
            .thenThrow(Exception('Clear error'));

        // Act & Assert
        expect(
          () => storageService.clearAllData(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getLastUpdated() contract', () {
      test('should return last updated timestamp', () async {
        // Arrange
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        final stateWithTimestamp = jsonEncode({
          'initiatives': [],
          'platformVariants': [],
          'teamMembers': [],
          'assignments': [],
          'lastUpdated': timestamp.toIso8601String(),
        });
        when(mockSharedPreferences.getString('kanban_state'))
            .thenReturn(stateWithTimestamp);

        // Act
        final result = await storageService.getLastUpdated();

        // Assert
        expect(result, equals(timestamp));
        verify(mockSharedPreferences.getString('kanban_state')).called(1);
      });

      test('should return null when no timestamp stored', () async {
        // Arrange
        when(mockSharedPreferences.getString('kanban_state'))
            .thenReturn(null);

        // Act
        final result = await storageService.getLastUpdated();

        // Assert
        expect(result, isNull);
        verify(mockSharedPreferences.getString('kanban_state')).called(1);
      });
    });
  });
}
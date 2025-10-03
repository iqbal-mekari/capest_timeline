import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:capest_timeline/services/capacity_service.dart';
import 'package:capest_timeline/services/storage_service.dart';
import 'package:capest_timeline/models/models.dart';

// Generate mocks
@GenerateMocks([StorageService])
import 'capacity_service_test.mocks.dart';

void main() {
  group('CapacityService', () {
    late CapacityService capacityService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      capacityService = CapacityService(storageService: mockStorageService);
    });

    group('getCapacityUtilization', () {
      test('should calculate capacity utilization correctly', () async {
        // Arrange
        final teamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
          const TeamMember(
            id: 'member-2',
            name: 'Jane Smith',
            platformSpecializations: ['frontend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        final assignments = [
          Assignment(
            id: 'assign-1',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 2.0,
            capacityPercentage: 0.5,
            startWeek: DateTime(2024, 1, 1),
            initiativeId: 'init-1',
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => assignments);

        // Act
        final result = await capacityService.getCapacityUtilization(
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 31),
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['overall'], isNotNull);
        expect(result['byMember'], isNotNull);
        expect(result['dateRange'], isNotNull);

        final overall = result['overall'] as Map<String, dynamic>;
        expect(overall['totalCapacity'], greaterThan(0));
        expect(overall['utilizedCapacity'], greaterThanOrEqualTo(0));
        expect(overall['utilizationPercentage'], greaterThanOrEqualTo(0));

        final byMember = result['byMember'] as Map<String, dynamic>;
        expect(byMember['member-1'], isNotNull);
        expect(byMember['member-2'], isNotNull);

        verify(mockStorageService.loadTeamMembers()).called(1);
        verify(mockStorageService.loadAssignments()).called(1);
      });

      test('should handle no assignments gracefully', () async {
        // Arrange
        final teamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => <Assignment>[]);

        // Act
        final result = await capacityService.getCapacityUtilization(
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 31),
        );

        // Assert
        final overall = result['overall'] as Map<String, dynamic>;
        expect(overall['utilizedCapacity'], equals(0.0));
        expect(overall['utilizationPercentage'], equals(0.0));

        final byMember = result['byMember'] as Map<String, dynamic>;
        final member1Data = byMember['member-1'] as Map<String, dynamic>;
        expect(member1Data['utilizationPercentage'], equals(0.0));
      });

      test('should detect over-allocation correctly', () async {
        // Arrange
        final teamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        final overAllocatedAssignments = [
          Assignment(
            id: 'assign-1',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 4.0,
            capacityPercentage: 0.8,
            startWeek: DateTime(2024, 1, 1),
            initiativeId: 'init-1',
          ),
          Assignment(
            id: 'assign-2',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 4.0,
            capacityPercentage: 0.6,
            startWeek: DateTime(2024, 1, 1),
            initiativeId: 'init-2',
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => overAllocatedAssignments);

        // Act
        final result = await capacityService.getCapacityUtilization(
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 31),
        );

        // Assert
        final overall = result['overall'] as Map<String, dynamic>;
        expect(overall['utilizationPercentage'], greaterThan(100.0));
      });

      test('should filter by date range correctly', () async {
        // Arrange
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
            allocatedWeeks: 4.0,
            capacityPercentage: 0.5,
            startWeek: DateTime(2024, 1, 1), // Within range
            initiativeId: 'init-1',
          ),
          Assignment(
            id: 'assign-2',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 4.0,
            capacityPercentage: 0.5,
            startWeek: DateTime(2024, 3, 1), // Outside range
            initiativeId: 'init-2',
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => assignments);

        // Act
        final result = await capacityService.getCapacityUtilization(
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 31),
        );

        // Assert - Should only count assignment within date range
        final byMember = result['byMember'] as Map<String, dynamic>;
        final member1Data = byMember['member-1'] as Map<String, dynamic>;
        expect(member1Data['utilization'], equals(160.0)); // 4 weeks * 40 hours
      });

      test('should handle service errors gracefully', () async {
        // Arrange
        when(mockStorageService.loadTeamMembers())
            .thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => capacityService.getCapacityUtilization(
            DateTime(2024, 1, 1),
            DateTime(2024, 1, 31),
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getCapacityPeriods', () {
      test('should generate capacity periods for date range', () async {
        // Arrange
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
            allocatedWeeks: 2.0,
            capacityPercentage: 0.5,
            startWeek: DateTime(2024, 1, 1),
            initiativeId: 'init-1',
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => assignments);

        // Act
        final result = await capacityService.getCapacityPeriods(
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 21), // 3 weeks
        );

        // Assert
        expect(result, hasLength(3)); // 3 week periods
        expect(result.first.weekStart, equals(DateTime(2024, 1, 1)));
        expect(result.first.totalCapacityAvailable, equals(40.0)); // 1.0 * 40 hours
        expect(result.first.assignments, isNotEmpty);
      });

      test('should handle empty assignments list', () async {
        // Arrange
        final teamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => <Assignment>[]);

        // Act
        final result = await capacityService.getCapacityPeriods(
          DateTime(2024, 1, 1),
          DateTime(2024, 1, 14), // 2 weeks
        );

        // Assert
        expect(result, hasLength(2));
        expect(result.first.assignments, isEmpty);
        expect(result.first.totalCapacityAvailable, equals(40.0)); // 1.0 * 40 hours
      });
    });

    group('validateCapacityConstraints', () {
      test('should validate capacity constraints for assignments', () async {
        // Arrange
        final teamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        final proposedAssignments = [
          Assignment(
            id: 'assign-1',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 0.5,
            capacityPercentage: 0.5,
            startWeek: DateTime(2024, 1, 1),
            initiativeId: 'init-1',
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => <Assignment>[]);

        // Act
        final result = await capacityService.validateCapacityConstraints(
          proposedAssignments,
        );

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['isValid'], isTrue);
        expect(result['violations'], isEmpty);
        expect(result['warnings'], isEmpty);
        expect(result['validatedAssignments'], equals(1));
      });

      test('should detect over-allocation', () async {
        // Arrange
        final teamMembers = [
          const TeamMember(
            id: 'member-1',
            name: 'John Doe',
            platformSpecializations: ['backend'],
            weeklyCapacity: 1.0,
            isActive: true,
          ),
        ];

        final existingAssignments = [
          Assignment(
            id: 'existing-1',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 0.8,
            capacityPercentage: 0.8,
            startWeek: DateTime(2024, 1, 1),
            initiativeId: 'init-1',
          ),
        ];

        final proposedAssignments = [
          Assignment(
            id: 'assign-1',
            memberId: 'member-1',
            platformType: PlatformType.backend,
            allocatedWeeks: 0.5,
            capacityPercentage: 0.5,
            startWeek: DateTime(2024, 1, 1),
            initiativeId: 'init-2',
          ),
        ];

        when(mockStorageService.loadTeamMembers())
            .thenAnswer((_) async => teamMembers);
        when(mockStorageService.loadAssignments())
            .thenAnswer((_) async => existingAssignments);

        // Act
        final result = await capacityService.validateCapacityConstraints(
          proposedAssignments,
        );

        // Assert
        expect(result['isValid'], isFalse);
        expect(result['violations'], isNotEmpty);
      });
    });
  });
}
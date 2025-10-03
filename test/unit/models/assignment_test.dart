import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/models/assignment.dart';
import 'package:capest_timeline/models/team_member.dart';
import 'package:capest_timeline/models/platform_type.dart';

void main() {
  group('Assignment Model Tests', () {
    test('should create Assignment with valid data', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
        notes: 'Backend development tasks',
      );

      // Assert
      expect(assignment.id, equals('assign-1'));
      expect(assignment.memberId, equals('member-1'));
      expect(assignment.platformType, equals(PlatformType.backend));
      expect(assignment.allocatedWeeks, equals(4));
      expect(assignment.capacityPercentage, equals(0.5));
      expect(assignment.startWeek, equals(DateTime(2024, 1, 1)));
      expect(assignment.notes, equals('Backend development tasks'));
    });

    test('should create Assignment with optional notes', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.frontend,
        allocatedWeeks: 2,
        capacityPercentage: 1.0,
        startWeek: DateTime(2024, 1, 1),
      );

      // Assert
      expect(assignment.notes, isNull);
    });

    test('should throw exception when allocatedWeeks is not positive', () {
      // Act & Assert
      expect(
        () => Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 0,
          capacityPercentage: 0.5,
          startWeek: DateTime(2024, 1, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: -1,
          capacityPercentage: 0.5,
          startWeek: DateTime(2024, 1, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw exception when capacityPercentage is not in valid range', () {
      // Act & Assert
      expect(
        () => Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 4,
          capacityPercentage: 0.0,
          startWeek: DateTime(2024, 1, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 4,
          capacityPercentage: -0.1, // Negative values should be invalid
          startWeek: DateTime(2024, 1, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => Assignment(
          id: 'assign-1',
          memberId: 'member-1',
          platformType: PlatformType.backend,
          allocatedWeeks: 4,
          capacityPercentage: -0.1,
          startWeek: DateTime(2024, 1, 1),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should support equality comparison using Equatable', () {
      // Arrange
      final assignment1 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
        notes: 'Backend tasks',
      );

      final assignment2 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
        notes: 'Backend tasks',
      );

      final assignment3 = Assignment(
        id: 'assign-2',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
        notes: 'Backend tasks',
      );

      // Assert
      expect(assignment1, equals(assignment2));
      expect(assignment1, isNot(equals(assignment3)));
      expect(assignment1.hashCode, equals(assignment2.hashCode));
    });

    test('should calculate end week correctly', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      // Act
      final endWeek = assignment.calculateEndWeek();

      // Assert
      expect(endWeek, equals(DateTime(2024, 1, 29))); // 4 weeks later (28 days)
    });

    test('should check if assignment overlaps with date range', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      // Act & Assert
      expect(assignment.overlapsWith(DateTime(2023, 12, 25), DateTime(2024, 1, 7)), isTrue);
      expect(assignment.overlapsWith(DateTime(2024, 1, 15), DateTime(2024, 2, 15)), isTrue);
      expect(assignment.overlapsWith(DateTime(2024, 1, 1), DateTime(2024, 1, 29)), isTrue);
      expect(assignment.overlapsWith(DateTime(2023, 12, 1), DateTime(2023, 12, 31)), isFalse);
      expect(assignment.overlapsWith(DateTime(2024, 2, 1), DateTime(2024, 2, 28)), isFalse);
    });

    test('should calculate total effort hours', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      // Act
      final totalHours = assignment.calculateTotalEffortHours(hoursPerWeek: 40);

      // Assert
      expect(totalHours, equals(80.0)); // 4 weeks * 0.5 capacity * 40 hours
    });

    test('should check if assignment is active during week', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      // Act & Assert
      expect(assignment.isActiveDuring(DateTime(2024, 1, 1)), isTrue);  // Start week
      expect(assignment.isActiveDuring(DateTime(2024, 1, 15)), isTrue); // Middle week
      expect(assignment.isActiveDuring(DateTime(2024, 1, 29)), isTrue); // End week
      expect(assignment.isActiveDuring(DateTime(2023, 12, 25)), isFalse); // Before
      expect(assignment.isActiveDuring(DateTime(2024, 2, 5)), isFalse);   // After
    });

    test('should serialize to and from JSON', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.75,
        startWeek: DateTime(2024, 1, 1),
        notes: 'Backend development',
      );

      // Act
      final json = assignment.toJson();
      final fromJson = Assignment.fromJson(json);

      // Assert
      expect(fromJson, equals(assignment));
      expect(json['id'], equals('assign-1'));
      expect(json['memberId'], equals('member-1'));
      expect(json['platformType'], equals('backend'));
      expect(json['allocatedWeeks'], equals(4));
      expect(json['capacityPercentage'], equals(0.75));
      expect(json['startWeek'], equals('2024-01-01T00:00:00.000'));
      expect(json['notes'], equals('Backend development'));
    });

    test('should update assignment details correctly', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      // Act
      final updated = assignment.copyWith(
        allocatedWeeks: 6,
        capacityPercentage: 0.75,
        notes: 'Updated notes',
      );

      // Assert
      expect(updated.allocatedWeeks, equals(6));
      expect(updated.capacityPercentage, equals(0.75));
      expect(updated.notes, equals('Updated notes'));
      expect(updated.id, equals(assignment.id));
      expect(updated.memberId, equals(assignment.memberId));
      expect(updated.platformType, equals(assignment.platformType));
    });

    test('should validate member compatibility', () {
      // Arrange
      const backendMember = TeamMember(
        id: 'member-1',
        name: 'John Doe',
        platformSpecializations: ['backend', 'qa'],
        weeklyCapacity: 1.0,
        isActive: true,
      );

      final frontendAssignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.frontend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final backendAssignment = Assignment(
        id: 'assign-2',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      // Act & Assert
      expect(frontendAssignment.isMemberCompatible(backendMember), isFalse);
      expect(backendAssignment.isMemberCompatible(backendMember), isTrue);
    });
  });
}
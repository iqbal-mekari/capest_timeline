import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/models/capacity_period.dart';
import 'package:capest_timeline/models/assignment.dart';
import 'package:capest_timeline/models/platform_type.dart';

void main() {
  group('CapacityPeriod Model Tests', () {
    test('should create CapacityPeriod with valid data', () {
      // Arrange
      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: const [],
        totalCapacityAvailable: 5.0,
      );

      // Assert
      expect(period.weekStart, equals(DateTime(2024, 1, 1)));
      expect(period.weekEnd, equals(DateTime(2024, 1, 7)));
      expect(period.assignments, isEmpty);
      expect(period.totalCapacityAvailable, equals(5.0));
    });

    test('should create CapacityPeriod with assignments', () {
      // Arrange
      final assignment1 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final assignment2 = Assignment(
        id: 'assign-2',
        memberId: 'member-2',
        platformType: PlatformType.frontend,
        allocatedWeeks: 2,
        capacityPercentage: 1.0,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment1, assignment2],
        totalCapacityAvailable: 5.0,
      );

      // Assert
      expect(period.assignments, hasLength(2));
      expect(period.assignments, contains(assignment1));
      expect(period.assignments, contains(assignment2));
    });

    test('should validate when weekStart is after weekEnd', () {
      // Arrange
      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 8),
        weekEnd: DateTime(2024, 1, 1),
        assignments: const [],
        totalCapacityAvailable: 5.0,
      );

      // Act
      final validation = period.validate();

      // Assert
      expect(validation, isNotNull);
      expect(validation, contains('Week end cannot be before week start'));
    });

    test('should validate when totalCapacityAvailable is negative', () {
      // Arrange
      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: const [],
        totalCapacityAvailable: -1.0,
      );

      // Act
      final validation = period.validate();

      // Assert
      expect(validation, isNotNull);
      expect(validation, contains('Total capacity cannot be negative'));
    });

    test('should support equality comparison using Equatable', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final period1 = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment],
        totalCapacityAvailable: 5.0,
      );

      final period2 = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment],
        totalCapacityAvailable: 5.0,
      );

      final period3 = CapacityPeriod(
        weekStart: DateTime(2024, 1, 8),
        weekEnd: DateTime(2024, 1, 14),
        assignments: [assignment],
        totalCapacityAvailable: 5.0,
      );

      // Assert
      expect(period1, equals(period2));
      expect(period1, isNot(equals(period3)));
      expect(period1.hashCode, equals(period2.hashCode));
    });

    test('should calculate total allocated capacity correctly', () {
      // Arrange
      final assignment1 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final assignment2 = Assignment(
        id: 'assign-2',
        memberId: 'member-2',
        platformType: PlatformType.frontend,
        allocatedWeeks: 2,
        capacityPercentage: 0.75,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment1, assignment2],
        totalCapacityAvailable: 50.0,
      );

      // Act
      final totalAllocated = period.calculatedUtilizedCapacity;

      // Assert
      expect(totalAllocated, equals(50.0)); // (0.5 * 40) + (0.75 * 40) = 20 + 30 = 50 hours per week
    });

    test('should calculate remaining capacity correctly', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment],
        totalCapacityAvailable: 30.0,
      );

      // Act
      final remaining = period.calculatedAvailableCapacity;

      // Assert
      expect(remaining, equals(10.0)); // 30.0 - (0.5 * 40) = 30.0 - 20.0 = 10.0
    });

    test('should detect over-allocation correctly', () {
      // Arrange
      final assignment1 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 1.0,
        startWeek: DateTime(2024, 1, 1),
      );

      final assignment2 = Assignment(
        id: 'assign-2',
        memberId: 'member-2',
        platformType: PlatformType.frontend,
        allocatedWeeks: 2,
        capacityPercentage: 1.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final underAllocatedPeriod = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment1],
        totalCapacityAvailable: 50.0,
      );

      final overAllocatedPeriod = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment1, assignment2],
        totalCapacityAvailable: 50.0,
      );

      // Act & Assert
      expect(underAllocatedPeriod.calculatedIsOverAllocated, isFalse); // 40 hours vs 50 capacity
      expect(overAllocatedPeriod.calculatedIsOverAllocated, isTrue); // 40 + 60 = 100 hours vs 50 capacity
    });

    test('should calculate utilization percentage correctly', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.75,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment],
        totalCapacityAvailable: 30.0,
      );

      // Act
      final utilization = period.utilizationPercentage;

      // Assert
      expect(utilization, equals(100.0)); // (30.0 / 30.0) * 100 = 100%
    });

    test('should get assignments by platform type', () {
      // Arrange
      final backendAssignment1 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final backendAssignment2 = Assignment(
        id: 'assign-2',
        memberId: 'member-2',
        platformType: PlatformType.backend,
        allocatedWeeks: 2,
        capacityPercentage: 0.75,
        startWeek: DateTime(2024, 1, 1),
      );

      final frontendAssignment = Assignment(
        id: 'assign-3',
        memberId: 'member-3',
        platformType: PlatformType.frontend,
        allocatedWeeks: 3,
        capacityPercentage: 1.0,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [backendAssignment1, backendAssignment2, frontendAssignment],
        totalCapacityAvailable: 5.0,
      );

      // Act
      final backendAssignments = period.getAssignmentsByPlatform('backend');
      final frontendAssignments = period.getAssignmentsByPlatform('frontend');
      final mobileAssignments = period.getAssignmentsByPlatform('mobile');

      // Assert
      expect(backendAssignments, hasLength(2));
      expect(backendAssignments, contains(backendAssignment1));
      expect(backendAssignments, contains(backendAssignment2));
      expect(frontendAssignments, hasLength(1));
      expect(frontendAssignments, contains(frontendAssignment));
      expect(mobileAssignments, isEmpty);
    });

    test('should get assignments by member ID', () {
      // Arrange
      final assignment1 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final assignment2 = Assignment(
        id: 'assign-2',
        memberId: 'member-1',
        platformType: PlatformType.frontend,
        allocatedWeeks: 2,
        capacityPercentage: 0.25,
        startWeek: DateTime(2024, 1, 1),
      );

      final assignment3 = Assignment(
        id: 'assign-3',
        memberId: 'member-2',
        platformType: PlatformType.backend,
        allocatedWeeks: 3,
        capacityPercentage: 1.0,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment1, assignment2, assignment3],
        totalCapacityAvailable: 5.0,
      );

      // Act
      final member1Assignments = period.getAssignmentsForMember('member-1');
      final member2Assignments = period.getAssignmentsForMember('member-2');
      final member3Assignments = period.getAssignmentsForMember('member-3');

      // Assert
      expect(member1Assignments, hasLength(2));
      expect(member1Assignments, contains(assignment1));
      expect(member1Assignments, contains(assignment2));
      expect(member2Assignments, hasLength(1));
      expect(member2Assignments, contains(assignment3));
      expect(member3Assignments, isEmpty);
    });

    test('should serialize to and from JSON', () {
      // Arrange
      final assignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment],
        totalCapacityAvailable: 3.5,
      );

      // Act
      final json = period.toJson();
      final fromJson = CapacityPeriod.fromJson(json);

      // Assert
      expect(fromJson, equals(period));
      expect(json['weekStart'], equals('2024-01-01T00:00:00.000'));
      expect(json['weekEnd'], equals('2024-01-07T00:00:00.000'));
      expect(json['assignments'], hasLength(1));
      expect(json['totalCapacityAvailable'], equals(3.5));
    });

    test('should add assignment correctly', () {
      // Arrange
      final existingAssignment = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [existingAssignment],
        totalCapacityAvailable: 5.0,
      );

      final newAssignment = Assignment(
        id: 'assign-2',
        memberId: 'member-2',
        platformType: PlatformType.frontend,
        allocatedWeeks: 2,
        capacityPercentage: 0.75,
        startWeek: DateTime(2024, 1, 1),
      );

      // Act
      final updatedPeriod = period.copyWith(
        assignments: [...period.assignments, newAssignment],
      );

      // Assert
      expect(updatedPeriod.assignments, hasLength(2));
      expect(updatedPeriod.assignments, contains(existingAssignment));
      expect(updatedPeriod.assignments, contains(newAssignment));
      expect(period.assignments, hasLength(1)); // Original unchanged
    });

    test('should remove assignment correctly', () {
      // Arrange
      final assignment1 = Assignment(
        id: 'assign-1',
        memberId: 'member-1',
        platformType: PlatformType.backend,
        allocatedWeeks: 4,
        capacityPercentage: 0.5,
        startWeek: DateTime(2024, 1, 1),
      );

      final assignment2 = Assignment(
        id: 'assign-2',
        memberId: 'member-2',
        platformType: PlatformType.frontend,
        allocatedWeeks: 2,
        capacityPercentage: 0.75,
        startWeek: DateTime(2024, 1, 1),
      );

      final period = CapacityPeriod(
        weekStart: DateTime(2024, 1, 1),
        weekEnd: DateTime(2024, 1, 7),
        assignments: [assignment1, assignment2],
        totalCapacityAvailable: 5.0,
      );

      // Act
      final updatedPeriod = period.copyWith(
        assignments: period.assignments.where((a) => a.id != 'assign-1').toList(),
      );

      // Assert
      expect(updatedPeriod.assignments, hasLength(1));
      expect(updatedPeriod.assignments, contains(assignment2));
      expect(updatedPeriod.assignments, isNot(contains(assignment1)));
      expect(period.assignments, hasLength(2)); // Original unchanged
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/models/platform_variant.dart';
import 'package:capest_timeline/models/platform_type.dart';

void main() {
  group('PlatformVariant Model Tests', () {
    test('should create PlatformVariant with valid data', () {
      // Arrange
      final now = DateTime.now();
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: now,
        isAssigned: true,
        assignedMemberId: 'member-1',
      );

      // Assert
      expect(variant.id, equals('variant-1'));
      expect(variant.initiativeId, equals('init-1'));
      expect(variant.platformType, equals(PlatformType.backend));
      expect(variant.title, equals('Backend Implementation'));
      expect(variant.estimatedWeeks, equals(3));
      expect(variant.currentWeek, equals(now));
      expect(variant.isAssigned, equals(true));
      expect(variant.assignedMemberId, equals('member-1'));
    });

    test('should create unassigned variant', () {
      // Arrange
      final now = DateTime.now();
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.frontend,
        title: 'Frontend Implementation',
        estimatedWeeks: 2,
        currentWeek: now,
        isAssigned: false,
      );

      // Assert
      expect(variant.isAssigned, equals(false));
      expect(variant.assignedMemberId, isNull);
      expect(variant.estimatedWeeks, equals(2));
    });

    test('should validate properly when title is empty', () {
      // Arrange
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: '',
        estimatedWeeks: 3,
        currentWeek: DateTime.now(),
        isAssigned: false,
      );

      // Act & Assert
      expect(variant.validate(), equals('Title cannot be empty'));
    });

    test('should validate properly when estimated weeks is negative', () {
      // Arrange
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: -1,
        currentWeek: DateTime.now(),
        isAssigned: false,
      );

      // Act & Assert
      expect(variant.validate(), equals('Estimated weeks cannot be negative'));
    });

    test('should validate properly when assigned but no member id', () {
      // Arrange
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: DateTime.now(),
        isAssigned: true,
        assignedMemberId: null,
      );

      // Act & Assert
      expect(variant.validate(), equals('Assigned variants must have a team member ID'));
    });

    test('should support equality comparison using Equatable', () {
      // Arrange
      final now = DateTime.now();
      final variant1 = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: now,
        isAssigned: false,
      );

      final variant2 = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: now,
        isAssigned: false,
      );

      final variant3 = PlatformVariant(
        id: 'variant-2',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: now,
        isAssigned: false,
      );

      // Assert
      expect(variant1, equals(variant2));
      expect(variant1, isNot(equals(variant3)));
      expect(variant1.hashCode, equals(variant2.hashCode));
    });

    test('should calculate end date correctly', () {
      // Arrange
      final startDate = DateTime(2024, 1, 1);
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: startDate,
        isAssigned: false,
      );

      // Assert
      final expectedEndDate = startDate.add(const Duration(days: 3 * 7 - 1));
      expect(variant.endDate.year, equals(expectedEndDate.year));
      expect(variant.endDate.month, equals(expectedEndDate.month));
      expect(variant.endDate.day, equals(expectedEndDate.day));
    });

    test('should calculate completion percentage correctly', () {
      // Arrange
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 4,
        currentWeek: DateTime.now(),
        isAssigned: false,
        completedWeeks: 2,
      );

      // Assert
      expect(variant.completionPercentage, equals(50.0));
      expect(variant.remainingWeeks, equals(2));
    });

    test('should check completion status correctly', () {
      // Arrange
      final completeVariant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: DateTime.now(),
        isAssigned: false,
        completedWeeks: 3,
      );

      final incompleteVariant = PlatformVariant(
        id: 'variant-2',
        initiativeId: 'init-1',
        platformType: PlatformType.frontend,
        title: 'Frontend Implementation',
        estimatedWeeks: 4,
        currentWeek: DateTime.now(),
        isAssigned: false,
        completedWeeks: 2,
      );

      // Assert
      expect(completeVariant.isCompleted, equals(true));
      expect(incompleteVariant.isCompleted, equals(false));
    });

    test('should serialize to and from JSON', () {
      // Arrange
      final now = DateTime(2024, 1, 1);
      final variant = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Backend Implementation',
        estimatedWeeks: 3,
        currentWeek: now,
        isAssigned: true,
        assignedMemberId: 'member-1',
        description: 'Backend work',
        priority: 'high',
        tags: const ['api', 'database'],
        completedWeeks: 1,
      );

      // Act
      final json = variant.toJson();
      final fromJson = PlatformVariant.fromJson(json);

      // Assert
      expect(fromJson, equals(variant));
      expect(json['id'], equals('variant-1'));
      expect(json['platformType'], equals('backend'));
      expect(json['title'], equals('Backend Implementation'));
      expect(json['estimatedWeeks'], equals(3));
      expect(json['isAssigned'], equals(true));
      expect(json['assignedMemberId'], equals('member-1'));
    });

    test('should create copy with updated fields', () {
      // Arrange
      final original = PlatformVariant(
        id: 'variant-1',
        initiativeId: 'init-1',
        platformType: PlatformType.backend,
        title: 'Original Title',
        estimatedWeeks: 2,
        currentWeek: DateTime.now(),
        isAssigned: false,
      );

      // Act
      final updated = original.copyWith(
        title: 'Updated Title',
        estimatedWeeks: 4,
        isAssigned: true,
        assignedMemberId: 'member-1',
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated Title'));
      expect(updated.estimatedWeeks, equals(4));
      expect(updated.isAssigned, equals(true));
      expect(updated.assignedMemberId, equals('member-1'));
      expect(updated.platformType, equals(original.platformType));
      expect(updated.currentWeek, equals(original.currentWeek));
    });
  });
}
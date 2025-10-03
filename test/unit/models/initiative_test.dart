import 'package:flutter_test/flutter_test.dart';
import 'package:capest_timeline/models/initiative.dart';
import 'package:capest_timeline/models/platform_type.dart';
import 'package:capest_timeline/models/platform_variant.dart';

void main() {
  group('Initiative Model Tests', () {
    test('should create valid initiative with all required fields', () {
      // Arrange
      final now = DateTime.now();
      final initiative = Initiative(
        id: 'init-1',
        title: 'Test Initiative',
        description: 'Test description',
        createdAt: now,
        platformVariants: [
          PlatformVariant(
            id: 'pv-1',
            initiativeId: 'init-1',
            platformType: PlatformType.backend,
            title: 'Backend Implementation',
            estimatedWeeks: 4,
            currentWeek: now,
            isAssigned: false,
          ),
          PlatformVariant(
            id: 'pv-2',
            initiativeId: 'init-1',
            platformType: PlatformType.frontend,
            title: 'Frontend Implementation',
            estimatedWeeks: 4,
            currentWeek: now,
            isAssigned: false,
          ),
        ],
        requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
      );

      // Assert
      expect(initiative.id, equals('init-1'));
      expect(initiative.title, equals('Test Initiative'));
      expect(initiative.estimatedWeeks, equals(8.0));
      expect(initiative.requiredPlatforms, contains(PlatformType.backend));
      expect(initiative.requiredPlatforms, contains(PlatformType.frontend));
      expect(initiative.requiredPlatforms.length, equals(2));
    });

    test('should validate properly when title is empty', () {
      // Arrange
      final initiative = Initiative(
        id: 'init-1',
        title: '',
        description: 'Test description',
        createdAt: DateTime.now(),
        platformVariants: const [],
      );

      // Act & Assert
      expect(initiative.validate(), equals('Title cannot be empty'));
    });

    test('should validate properly when description is empty', () {
      // Arrange
      final initiative = Initiative(
        id: 'init-1',
        title: 'Test Initiative',
        description: '',
        createdAt: DateTime.now(),
        platformVariants: const [],
      );

      // Act & Assert
      expect(initiative.validate(), equals('Description cannot be empty'));
    });

    test('should validate invalid status', () {
      // Arrange
      final initiative = Initiative(
        id: 'init-1',
        title: 'Test Initiative',
        description: 'Test description',
        createdAt: DateTime.now(),
        platformVariants: const [],
        status: 'invalid-status',
      );

      // Act & Assert
      expect(initiative.validate(), contains('Status must be'));
    });

    test('should validate invalid priority', () {
      // Arrange
      final initiative = Initiative(
        id: 'init-1',
        title: 'Test Initiative',
        description: 'Test description',
        createdAt: DateTime.now(),
        platformVariants: const [],
        priority: 'invalid-priority',
      );

      // Act & Assert
      expect(initiative.validate(), contains('Priority must be'));
    });

    test('should support equality comparison using Equatable', () {
      // Arrange
      final date1 = DateTime.now();
      final variants = [
        PlatformVariant(
          id: 'pv-1',
          initiativeId: 'init-1',
          platformType: PlatformType.backend,
          title: 'Backend Implementation',
          estimatedWeeks: 4,
          currentWeek: date1,
          isAssigned: false,
        ),
      ];
      
      final initiative1 = Initiative(
        id: 'init-1',
        title: 'Test Initiative',
        description: 'Test description',
        createdAt: date1,
        platformVariants: variants,
        requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
      );

      final initiative2 = Initiative(
        id: 'init-1',
        title: 'Test Initiative',
        description: 'Test description',
        createdAt: date1,
        platformVariants: variants,
        requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
      );

      final initiative3 = Initiative(
        id: 'init-2',
        title: 'Test Initiative',
        description: 'Test description',
        createdAt: date1,
        platformVariants: variants,
        requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
      );

      // Assert
      expect(initiative1, equals(initiative2));
      expect(initiative1, isNot(equals(initiative3)));
      expect(initiative1.hashCode, equals(initiative2.hashCode));
    });

    test('should create copy with updated fields', () {
      // Arrange
      final original = Initiative(
        id: 'init-1',
        title: 'Original Title',
        description: 'Original description',
        createdAt: DateTime.now(),
        platformVariants: const [],
        requiredPlatforms: const [PlatformType.backend],
      );

      // Act
      final updated = original.copyWith(
        title: 'Updated Title',
        description: 'Updated description',
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated Title'));
      expect(updated.description, equals('Updated description'));
      expect(updated.requiredPlatforms, equals(original.requiredPlatforms));
      expect(updated.createdAt, equals(original.createdAt));
      expect(updated.updatedAt, isNot(equals(original.updatedAt)));
    });

    test('should serialize to and from JSON', () {
      // Arrange
      final createdAt = DateTime.parse('2025-10-02T12:00:00.000Z');
      final currentWeek = DateTime.parse('2025-10-03T00:00:00.000Z');
      
      final initiative = Initiative(
        id: 'init-1',
        title: 'Test Initiative',
        description: 'Test description',
        createdAt: createdAt,
        platformVariants: [
          PlatformVariant(
            id: 'pv-1',
            initiativeId: 'init-1',
            platformType: PlatformType.backend,
            title: 'Backend Implementation',
            estimatedWeeks: 4,
            currentWeek: currentWeek,
            isAssigned: false,
          ),
        ],
        requiredPlatforms: const [PlatformType.backend, PlatformType.frontend],
      );

      // Act
      final json = initiative.toJson();
      final fromJson = Initiative.fromJson(json);

      // Assert
      expect(fromJson, equals(initiative));
      expect(json['id'], equals('init-1'));
      expect(json['title'], equals('Test Initiative'));
      expect(json['description'], equals('Test description'));
      expect(json['requiredPlatforms'], equals(['backend', 'frontend']));
    });
  });
}
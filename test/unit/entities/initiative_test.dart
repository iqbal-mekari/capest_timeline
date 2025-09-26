/// Unit tests for Initiative entity.
/// 
/// Tests comprehensive functionality including:
/// - Construction and property validation
/// - Effort calculations and role analysis
/// - Priority scoring and business logic
/// - Validation rules and constraints
/// - Serialization and deserialization
library;

import 'package:test/test.dart';
import 'package:capest_timeline/core/enums/role.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/initiative.dart';

void main() {
  group('Initiative Entity Tests', () {
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;
    late Map<Role, double> testRequiredRoles;

    setUp(() {
      testCreatedAt = DateTime(2024, 6, 1);
      testUpdatedAt = DateTime(2024, 6, 15);
      testRequiredRoles = {
        Role.backend: 4.0,
        Role.frontend: 3.0,
        Role.qa: 1.0,
      };
    });

    group('Construction and Basic Properties', () {
      test('should create valid Initiative with required fields', () {
        // Arrange & Act
        final initiative = Initiative(
          id: 'init001',
          name: 'User Authentication System',
          description: 'Implement secure user authentication with OAuth2',
          requiredRoles: testRequiredRoles,
          estimatedEffortWeeks: 8.0,
          priority: 8,
          businessValue: 9,
          dependencies: [],
        );

        // Assert
        expect(initiative.id, equals('init001'));
        expect(initiative.name, equals('User Authentication System'));
        expect(initiative.description, equals('Implement secure user authentication with OAuth2'));
        expect(initiative.requiredRoles, equals(testRequiredRoles));
        expect(initiative.estimatedEffortWeeks, equals(8.0));
        expect(initiative.priority, equals(8));
        expect(initiative.businessValue, equals(9));
        expect(initiative.dependencies, isEmpty);
        expect(initiative.tags, isEmpty);
        expect(initiative.notes, equals(''));
        expect(initiative.createdAt, isNull);
        expect(initiative.updatedAt, isNull);
      });

      test('should create Initiative with all optional fields', () {
        // Arrange & Act
        final initiative = Initiative(
          id: 'init002',
          name: 'Mobile App Redesign',
          description: 'Complete redesign of mobile application UI/UX',
          requiredRoles: {Role.frontend: 6.0, Role.design: 4.0},
          estimatedEffortWeeks: 10.0,
          priority: 7,
          businessValue: 8,
          dependencies: ['init001'],
          tags: ['mobile', 'ui', 'redesign'],
          notes: 'High visibility project for Q4',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(initiative.id, equals('init002'));
        expect(initiative.name, equals('Mobile App Redesign'));
        expect(initiative.description, equals('Complete redesign of mobile application UI/UX'));
        expect(initiative.requiredRoles, equals({Role.frontend: 6.0, Role.design: 4.0}));
        expect(initiative.estimatedEffortWeeks, equals(10.0));
        expect(initiative.priority, equals(7));
        expect(initiative.businessValue, equals(8));
        expect(initiative.dependencies, equals(['init001']));
        expect(initiative.tags, equals(['mobile', 'ui', 'redesign']));
        expect(initiative.notes, equals('High visibility project for Q4'));
        expect(initiative.createdAt, equals(testCreatedAt));
        expect(initiative.updatedAt, equals(testUpdatedAt));
      });
    });

    group('Effort Calculations', () {
      test('should calculate total effort correctly', () {
        // Arrange
        final initiative = Initiative(
          id: 'init003',
          name: 'API Integration',
          description: 'Integrate with external payment API',
          requiredRoles: {
            Role.backend: 5.0,
            Role.frontend: 2.0,
            Role.qa: 1.5,
          },
          estimatedEffortWeeks: 8.5,
          priority: 6,
          businessValue: 7,
          dependencies: [],
        );

        // Act
        final totalEffort = initiative.totalEffort;

        // Assert
        expect(totalEffort, equals(8.5)); // 5.0 + 2.0 + 1.5
      });

      test('should calculate effort distribution as percentages', () {
        // Arrange
        final initiative = Initiative(
          id: 'init004',
          name: 'Database Migration',
          description: 'Migrate from MySQL to PostgreSQL',
          requiredRoles: {
            Role.backend: 6.0,
            Role.devops: 4.0,
          },
          estimatedEffortWeeks: 10.0,
          priority: 9,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final distribution = initiative.effortDistribution;

        // Assert
        expect(distribution[Role.backend], equals(60.0)); // 6.0/10.0 * 100
        expect(distribution[Role.devops], equals(40.0)); // 4.0/10.0 * 100
      });

      test('should handle zero total effort in distribution calculation', () {
        // Arrange
        final initiative = Initiative(
          id: 'init005',
          name: 'Empty Initiative',
          description: 'Initiative with no effort',
          requiredRoles: {},
          estimatedEffortWeeks: 0.0,
          priority: 1,
          businessValue: 1,
          dependencies: [],
        );

        // Act
        final distribution = initiative.effortDistribution;

        // Assert
        expect(distribution, isEmpty);
      });

      test('should get all unique roles required', () {
        // Arrange
        final initiative = Initiative(
          id: 'init006',
          name: 'Full Stack Feature',
          description: 'Complete feature requiring multiple roles',
          requiredRoles: {
            Role.backend: 3.0,
            Role.frontend: 4.0,
            Role.design: 1.0,
            Role.qa: 2.0,
          },
          estimatedEffortWeeks: 10.0,
          priority: 8,
          businessValue: 7,
          dependencies: [],
        );

        // Act
        final roles = initiative.roles;

        // Assert
        expect(roles, containsAll([Role.backend, Role.frontend, Role.design, Role.qa]));
        expect(roles, hasLength(4));
      });
    });

    group('Role and Complexity Analysis', () {
      test('should identify primary role correctly', () {
        // Arrange
        final initiative = Initiative(
          id: 'init007',
          name: 'Backend Heavy Feature',
          description: 'Feature requiring mostly backend work',
          requiredRoles: {
            Role.backend: 8.0,
            Role.frontend: 2.0,
            Role.qa: 1.0,
          },
          estimatedEffortWeeks: 11.0,
          priority: 7,
          businessValue: 8,
          dependencies: [],
        );

        // Act
        final primaryRole = initiative.primaryRole;

        // Assert
        expect(primaryRole, equals(Role.backend));
      });

      test('should return null primary role for empty requirements', () {
        // Arrange
        final initiative = Initiative(
          id: 'init008',
          name: 'Empty Requirements',
          description: 'Initiative with no role requirements',
          requiredRoles: {},
          estimatedEffortWeeks: 0.0,
          priority: 1,
          businessValue: 1,
          dependencies: [],
        );

        // Act
        final primaryRole = initiative.primaryRole;

        // Assert
        expect(primaryRole, isNull);
      });

      test('should identify complex initiatives correctly', () {
        // Arrange
        final complexInitiative = Initiative(
          id: 'init009',
          name: 'Multi-Role Feature',
          description: 'Feature requiring multiple roles',
          requiredRoles: {
            Role.backend: 3.0,
            Role.frontend: 2.0,
          },
          estimatedEffortWeeks: 5.0,
          priority: 6,
          businessValue: 7,
          dependencies: [],
        );

        final simpleInitiative = Initiative(
          id: 'init010',
          name: 'Single Role Feature',
          description: 'Feature requiring only one role',
          requiredRoles: {
            Role.backend: 4.0,
          },
          estimatedEffortWeeks: 4.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act & Assert
        expect(complexInitiative.isComplex, isTrue);
        expect(simpleInitiative.isComplex, isFalse);
      });

      test('should identify large initiatives correctly', () {
        // Arrange
        final largeInitiative = Initiative(
          id: 'init011',
          name: 'Large Feature',
          description: 'Feature requiring significant effort',
          requiredRoles: {
            Role.backend: 6.0,
            Role.frontend: 4.0,
          },
          estimatedEffortWeeks: 10.0,
          priority: 8,
          businessValue: 9,
          dependencies: [],
        );

        final smallInitiative = Initiative(
          id: 'init012',
          name: 'Small Feature',
          description: 'Small feature requiring minimal effort',
          requiredRoles: {
            Role.backend: 2.0,
          },
          estimatedEffortWeeks: 2.0,
          priority: 4,
          businessValue: 5,
          dependencies: [],
        );

        // Act & Assert
        expect(largeInitiative.isLarge, isTrue); // > 8 weeks
        expect(smallInitiative.isLarge, isFalse); // <= 8 weeks
      });
    });

    group('Priority Scoring', () {
      test('should calculate priority score correctly', () {
        // Arrange
        final initiative = Initiative(
          id: 'init013',
          name: 'High Priority Feature',
          description: 'Critical business feature',
          requiredRoles: {Role.backend: 4.0},
          estimatedEffortWeeks: 4.0,
          priority: 9,
          businessValue: 7,
          dependencies: [],
        );

        // Act
        final priorityScore = initiative.priorityScore;

        // Assert
        expect(priorityScore, equals(8.0)); // (9 + 7) / 2
      });

      test('should handle minimum priority and business value', () {
        // Arrange
        final initiative = Initiative(
          id: 'init014',
          name: 'Low Priority Feature',
          description: 'Nice to have feature',
          requiredRoles: {Role.frontend: 1.0},
          estimatedEffortWeeks: 1.0,
          priority: 1,
          businessValue: 1,
          dependencies: [],
        );

        // Act
        final priorityScore = initiative.priorityScore;

        // Assert
        expect(priorityScore, equals(1.0)); // (1 + 1) / 2
      });

      test('should handle maximum priority and business value', () {
        // Arrange
        final initiative = Initiative(
          id: 'init015',
          name: 'Critical Feature',
          description: 'Mission critical feature',
          requiredRoles: {Role.backend: 8.0},
          estimatedEffortWeeks: 8.0,
          priority: 10,
          businessValue: 10,
          dependencies: [],
        );

        // Act
        final priorityScore = initiative.priorityScore;

        // Assert
        expect(priorityScore, equals(10.0)); // (10 + 10) / 2
      });
    });

    group('Validation', () {
      test('should validate correct Initiative successfully', () {
        // Arrange
        final validInitiative = Initiative(
          id: 'init016',
          name: 'Valid Feature',
          description: 'Well-defined feature with proper constraints',
          requiredRoles: {Role.backend: 4.0, Role.frontend: 2.0},
          estimatedEffortWeeks: 6.0,
          priority: 7,
          businessValue: 8,
          dependencies: ['init001'],
        );

        // Act
        final result = validInitiative.validate();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail validation for empty ID', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: '',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Initiative ID cannot be empty'));
      });

      test('should fail validation for empty name', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: 'init017',
          name: '',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Initiative name cannot be empty'));
      });

      test('should fail validation for empty description', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: 'init018',
          name: 'Valid Name',
          description: '',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Initiative description cannot be empty'));
      });

      test('should fail validation for invalid priority range', () {
        // Arrange
        final lowPriorityInitiative = Initiative(
          id: 'init019',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 0, // Invalid
          businessValue: 5,
          dependencies: [],
        );

        final highPriorityInitiative = Initiative(
          id: 'init020',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 11, // Invalid
          businessValue: 5,
          dependencies: [],
        );

        // Act
        final result1 = lowPriorityInitiative.validate();
        final result2 = highPriorityInitiative.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), contains('Priority must be between 1 and 10'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), contains('Priority must be between 1 and 10'));
      });

      test('should fail validation for invalid business value range', () {
        // Arrange
        final lowValueInitiative = Initiative(
          id: 'init021',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 0, // Invalid
          dependencies: [],
        );

        final highValueInitiative = Initiative(
          id: 'init022',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 11, // Invalid
          dependencies: [],
        );

        // Act
        final result1 = lowValueInitiative.validate();
        final result2 = highValueInitiative.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), contains('Business value must be between 1 and 10'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), contains('Business value must be between 1 and 10'));
      });

      test('should fail validation for empty required roles', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: 'init023',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {}, // Empty
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Initiative must require at least one role'));
      });

      test('should fail validation for negative role effort', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: 'init024',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {
            Role.backend: 3.0,
            Role.frontend: -1.0, // Invalid
          },
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Effort for Frontend must be positive'));
      });

      test('should fail validation for zero or negative estimated effort', () {
        // Arrange
        final zeroEffortInitiative = Initiative(
          id: 'init025',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 0.0, // Invalid
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        final negativeEffortInitiative = Initiative(
          id: 'init026',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: -1.0, // Invalid
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final result1 = zeroEffortInitiative.validate();
        final result2 = negativeEffortInitiative.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), contains('Estimated effort must be positive'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), contains('Estimated effort must be positive'));
      });

      test('should fail validation when estimated effort does not match role efforts', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: 'init027',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {
            Role.backend: 3.0,
            Role.frontend: 2.0,
          }, // Total: 5.0
          estimatedEffortWeeks: 8.0, // Doesn't match
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        final errorMessage = result.error.allErrors.join(' ');
        expect(errorMessage, matches(r'Estimated effort \(8(?:\.0)?\) does not match sum of role efforts \(5(?:\.0)?\)'));
      });

      test('should fail validation for self-referencing dependencies', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: 'init028',
          name: 'Valid Name',
          description: 'Valid description',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: ['init028'], // Self-reference
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Initiative cannot depend on itself'));
      });

      test('should accumulate multiple validation errors', () {
        // Arrange
        final invalidInitiative = Initiative(
          id: '',
          name: '',
          description: '',
          requiredRoles: {},
          estimatedEffortWeeks: -1.0,
          priority: 0,
          businessValue: 11,
          dependencies: [],
        );

        // Act
        final result = invalidInitiative.validate();

        // Assert
        expect(result.isError, isTrue);
        final allErrors = result.error.allErrors.join(' ');
        expect(allErrors, contains('Initiative ID cannot be empty'));
        expect(allErrors, contains('Initiative name cannot be empty'));
        expect(allErrors, contains('Initiative description cannot be empty'));
        expect(allErrors, contains('Initiative must require at least one role'));
        expect(allErrors, contains('Estimated effort must be positive'));
        expect(allErrors, contains('Priority must be between 1 and 10'));
        expect(allErrors, contains('Business value must be between 1 and 10'));
      });
    });

    group('Serialization', () {
      test('should serialize to Map correctly', () {
        // Arrange
        final initiative = Initiative(
          id: 'init029',
          name: 'Serialization Test',
          description: 'Test initiative for serialization',
          requiredRoles: {
            Role.backend: 4.0,
            Role.frontend: 3.0,
          },
          estimatedEffortWeeks: 7.0,
          priority: 8,
          businessValue: 7,
          dependencies: ['init001', 'init002'],
          tags: ['test', 'serialization'],
          notes: 'Test notes',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = initiative.toMap();

        // Assert
        expect(map['id'], equals('init029'));
        expect(map['name'], equals('Serialization Test'));
        expect(map['description'], equals('Test initiative for serialization'));
        expect(map['requiredRoles'], isA<Map<String, double>>());
        expect(map['requiredRoles']['backend'], equals(4.0));
        expect(map['requiredRoles']['frontend'], equals(3.0));
        expect(map['estimatedEffortWeeks'], equals(7.0));
        expect(map['priority'], equals(8));
        expect(map['businessValue'], equals(7));
        expect(map['dependencies'], equals(['init001', 'init002']));
        expect(map['tags'], equals(['test', 'serialization']));
        expect(map['notes'], equals('Test notes'));
        expect(map['createdAt'], equals(testCreatedAt.toIso8601String()));
        expect(map['updatedAt'], equals(testUpdatedAt.toIso8601String()));
      });

      test('should deserialize from Map correctly', () {
        // Arrange
        final map = {
          'id': 'init030',
          'name': 'Deserialization Test',
          'description': 'Test initiative for deserialization',
          'requiredRoles': {
            'backend': 5.0,
            'qa': 2.0,
          },
          'estimatedEffortWeeks': 7.0,
          'priority': 6,
          'businessValue': 8,
          'dependencies': ['init003'],
          'tags': ['test', 'deserialization'],
          'notes': 'Deserialization notes',
          'createdAt': testCreatedAt.toIso8601String(),
          'updatedAt': testUpdatedAt.toIso8601String(),
        };

        // Act
        final initiative = Initiative.fromMap(map);

        // Assert
        expect(initiative.id, equals('init030'));
        expect(initiative.name, equals('Deserialization Test'));
        expect(initiative.description, equals('Test initiative for deserialization'));
        expect(initiative.requiredRoles[Role.backend], equals(5.0));
        expect(initiative.requiredRoles[Role.qa], equals(2.0));
        expect(initiative.estimatedEffortWeeks, equals(7.0));
        expect(initiative.priority, equals(6));
        expect(initiative.businessValue, equals(8));
        expect(initiative.dependencies, equals(['init003']));
        expect(initiative.tags, equals(['test', 'deserialization']));
        expect(initiative.notes, equals('Deserialization notes'));
        expect(initiative.createdAt, equals(testCreatedAt));
        expect(initiative.updatedAt, equals(testUpdatedAt));
      });

      test('should handle serialization round-trip correctly', () {
        // Arrange
        final originalInitiative = Initiative(
          id: 'init031',
          name: 'Round-trip Test',
          description: 'Test initiative for round-trip serialization',
          requiredRoles: {
            Role.backend: 3.0,
            Role.frontend: 2.0,
            Role.design: 1.0,
          },
          estimatedEffortWeeks: 6.0,
          priority: 7,
          businessValue: 8,
          dependencies: ['init001'],
          tags: ['roundtrip'],
          notes: 'Round-trip notes',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = originalInitiative.toMap();
        final deserializedInitiative = Initiative.fromMap(map);

        // Assert
        expect(deserializedInitiative, equals(originalInitiative));
      });

      test('should handle deserialization with missing optional fields', () {
        // Arrange
        final minimalMap = {
          'id': 'init032',
          'name': 'Minimal Initiative',
          'description': 'Initiative with minimal fields',
          'requiredRoles': {'backend': 2.0},
          'estimatedEffortWeeks': 2.0,
          'priority': 5,
          'businessValue': 6,
          'dependencies': <String>[],
        };

        // Act
        final initiative = Initiative.fromMap(minimalMap);

        // Assert
        expect(initiative.id, equals('init032'));
        expect(initiative.name, equals('Minimal Initiative'));
        expect(initiative.description, equals('Initiative with minimal fields'));
        expect(initiative.requiredRoles[Role.backend], equals(2.0));
        expect(initiative.estimatedEffortWeeks, equals(2.0));
        expect(initiative.priority, equals(5));
        expect(initiative.businessValue, equals(6));
        expect(initiative.dependencies, isEmpty);
        expect(initiative.tags, isEmpty);
        expect(initiative.notes, equals(''));
        expect(initiative.createdAt, isNull);
        expect(initiative.updatedAt, isNull);
      });
    });

    group('Copy and Mutation', () {
      test('should create copy with updated fields', () {
        // Arrange
        final originalInitiative = Initiative(
          id: 'init033',
          name: 'Original Name',
          description: 'Original description',
          requiredRoles: {Role.backend: 4.0},
          estimatedEffortWeeks: 4.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act
        final updatedInitiative = originalInitiative.copyWith(
          name: 'Updated Name',
          priority: 8,
          tags: ['updated'],
          notes: 'Updated notes',
        );

        // Assert
        expect(updatedInitiative.id, equals(originalInitiative.id));
        expect(updatedInitiative.description, equals(originalInitiative.description));
        expect(updatedInitiative.requiredRoles, equals(originalInitiative.requiredRoles));
        expect(updatedInitiative.estimatedEffortWeeks, equals(originalInitiative.estimatedEffortWeeks));
        expect(updatedInitiative.businessValue, equals(originalInitiative.businessValue));
        expect(updatedInitiative.dependencies, equals(originalInitiative.dependencies));
        expect(updatedInitiative.name, equals('Updated Name'));
        expect(updatedInitiative.priority, equals(8));
        expect(updatedInitiative.tags, equals(['updated']));
        expect(updatedInitiative.notes, equals('Updated notes'));
      });

      test('should preserve original when no fields updated in copy', () {
        // Arrange
        final originalInitiative = Initiative(
          id: 'init034',
          name: 'Preserve Test',
          description: 'Test preservation in copy',
          requiredRoles: {Role.frontend: 3.0},
          estimatedEffortWeeks: 3.0,
          priority: 6,
          businessValue: 7,
          dependencies: [],
        );

        // Act
        final copiedInitiative = originalInitiative.copyWith();

        // Assert
        expect(copiedInitiative, equals(originalInitiative));
        expect(identical(copiedInitiative, originalInitiative), isFalse);
      });
    });

    group('Equality and String Representation', () {
      test('should implement equality correctly', () {
        // Arrange
        final initiative1 = Initiative(
          id: 'init035',
          name: 'Equality Test',
          description: 'Test initiative for equality',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        final initiative2 = Initiative(
          id: 'init035',
          name: 'Equality Test',
          description: 'Test initiative for equality',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        final initiative3 = Initiative(
          id: 'init036',
          name: 'Different Initiative',
          description: 'Different test initiative',
          requiredRoles: {Role.backend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 5,
          businessValue: 6,
          dependencies: [],
        );

        // Act & Assert
        expect(initiative1, equals(initiative2));
        expect(initiative1, isNot(equals(initiative3)));
        expect(initiative1.hashCode, equals(initiative2.hashCode));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        final initiative = Initiative(
          id: 'init037',
          name: 'String Test Initiative',
          description: 'Initiative for testing string representation',
          requiredRoles: {
            Role.backend: 4.0,
            Role.frontend: 2.0,
          },
          estimatedEffortWeeks: 6.0,
          priority: 8,
          businessValue: 7,
          dependencies: [],
        );

        // Act
        final stringRep = initiative.toString();

        // Assert
        expect(stringRep, contains('init037'));
        expect(stringRep, contains('String Test Initiative'));
        expect(stringRep, matches(r'effort: 6(?:\.0)?w'));
        expect(stringRep, contains('priority: 8'));
        expect(stringRep, contains('Backend'));
        expect(stringRep, contains('Frontend'));
      });
    });

    group('Edge Cases', () {
      test('should handle very small effort values', () {
        // Arrange
        final initiative = Initiative(
          id: 'init038',
          name: 'Tiny Initiative',
          description: 'Initiative with minimal effort',
          requiredRoles: {Role.qa: 0.1},
          estimatedEffortWeeks: 0.1,
          priority: 1,
          businessValue: 1,
          dependencies: [],
        );

        // Act & Assert
        expect(initiative.totalEffort, equals(0.1));
        expect(initiative.isLarge, isFalse);
        expect(initiative.isComplex, isFalse);
        expect(initiative.validate().isSuccess, isTrue);
      });

      test('should handle very large effort values', () {
        // Arrange
        final initiative = Initiative(
          id: 'init039',
          name: 'Massive Initiative',
          description: 'Initiative with significant effort',
          requiredRoles: {
            Role.backend: 20.0,
            Role.frontend: 15.0,
            Role.qa: 10.0,
            Role.design: 8.0,
            Role.devops: 5.0,
          },
          estimatedEffortWeeks: 58.0,
          priority: 10,
          businessValue: 10,
          dependencies: [],
        );

        // Act & Assert
        expect(initiative.totalEffort, equals(58.0));
        expect(initiative.isLarge, isTrue);
        expect(initiative.isComplex, isTrue);
        expect(initiative.primaryRole, equals(Role.backend));
        expect(initiative.validate().isSuccess, isTrue);
      });

      test('should handle initiatives with many dependencies', () {
        // Arrange
        final manyDependencies = List.generate(10, (index) => 'dep$index');
        final initiative = Initiative(
          id: 'init040',
          name: 'Dependent Initiative',
          description: 'Initiative with many dependencies',
          requiredRoles: {Role.backend: 3.0},
          estimatedEffortWeeks: 3.0,
          priority: 5,
          businessValue: 6,
          dependencies: manyDependencies,
        );

        // Act & Assert
        expect(initiative.dependencies, hasLength(10));
        expect(initiative.dependencies, equals(manyDependencies));
        expect(initiative.validate().isSuccess, isTrue);
      });

      test('should handle initiatives with many tags', () {
        // Arrange
        final manyTags = List.generate(15, (index) => 'tag$index');
        final initiative = Initiative(
          id: 'init041',
          name: 'Tagged Initiative',
          description: 'Initiative with many tags',
          requiredRoles: {Role.frontend: 2.0},
          estimatedEffortWeeks: 2.0,
          priority: 4,
          businessValue: 5,
          dependencies: [],
          tags: manyTags,
        );

        // Act & Assert
        expect(initiative.tags, hasLength(15));
        expect(initiative.tags, equals(manyTags));
        expect(initiative.validate().isSuccess, isTrue);
      });
    });
  });
}
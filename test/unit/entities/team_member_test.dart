/// Unit tests for TeamMember entity.
/// 
/// Tests comprehensive functionality including:
/// - Construction and property validation
/// - Business logic and calculations
/// - Serialization and deserialization
/// - Edge cases and error conditions
library;

import 'package:test/test.dart';
import 'package:capest_timeline/core/enums/role.dart';
import 'package:capest_timeline/features/team_management/domain/entities/team_member.dart';

void main() {
  group('TeamMember Entity Tests', () {
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;
    late DateTime vacationStart;
    late DateTime vacationEnd;
    late UnavailablePeriod testVacation;

    setUp(() {
      testCreatedAt = DateTime(2024, 1, 1);
      testUpdatedAt = DateTime(2024, 1, 15);
      vacationStart = DateTime(2024, 6, 1);
      vacationEnd = DateTime(2024, 6, 14);
      testVacation = UnavailablePeriod(
        startDate: vacationStart,
        endDate: vacationEnd,
        reason: 'Vacation',
        notes: 'Summer vacation',
      );
    });

    group('Construction and Basic Properties', () {
      test('should create valid TeamMember with required fields', () {
        // Arrange & Act
        final teamMember = TeamMember(
          id: 'tm001',
          name: 'Alice Johnson',
          email: 'alice@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
        );

        // Assert
        expect(teamMember.id, equals('tm001'));
        expect(teamMember.name, equals('Alice Johnson'));
        expect(teamMember.email, equals('alice@company.com'));
        expect(teamMember.roles, equals({Role.frontend}));
        expect(teamMember.weeklyCapacity, equals(1.0));
        expect(teamMember.skillLevel, equals(5)); // default
        expect(teamMember.unavailablePeriods, isEmpty);
        expect(teamMember.notes, equals(''));
        expect(teamMember.isActive, isTrue);
        expect(teamMember.createdAt, isNull);
        expect(teamMember.updatedAt, isNull);
      });

      test('should create TeamMember with all optional fields', () {
        // Arrange & Act
        final teamMember = TeamMember(
          id: 'tm002',
          name: 'Bob Smith',
          email: 'bob@company.com',
          roles: {Role.backend, Role.devops},
          weeklyCapacity: 0.8,
          skillLevel: 8,
          unavailablePeriods: [testVacation],
          notes: 'Senior developer with DevOps expertise',
          isActive: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(teamMember.id, equals('tm002'));
        expect(teamMember.name, equals('Bob Smith'));
        expect(teamMember.skillLevel, equals(8));
        expect(teamMember.unavailablePeriods, hasLength(1));
        expect(teamMember.notes, equals('Senior developer with DevOps expertise'));
        expect(teamMember.createdAt, equals(testCreatedAt));
        expect(teamMember.updatedAt, equals(testUpdatedAt));
      });
    });

    group('Computed Properties', () {
      test('should return correct primary role', () {
        // Arrange
        final teamMember = TeamMember(
          id: 'tm003',
          name: 'Carol Davis',
          email: 'carol@company.com',
          roles: {Role.backend, Role.frontend},
          weeklyCapacity: 1.0,
        );

        // Act & Assert
        expect(teamMember.primaryRole, isNotNull);
        expect({Role.backend, Role.frontend}, 
               contains(teamMember.primaryRole));
      });

      test('should return null primary role when no roles', () {
        // Arrange
        final teamMember = TeamMember(
          id: 'tm004',
          name: 'Dave Wilson',
          email: 'dave@company.com',
          roles: <Role>{},
          weeklyCapacity: 1.0,
        );

        // Act & Assert
        expect(teamMember.primaryRole, isNull);
      });

      test('should calculate quarterly capacity correctly', () {
        // Arrange
        final fullTimeTeamMember = TeamMember(
          id: 'tm005',
          name: 'Eva Brown',
          email: 'eva@company.com',
          roles: {Role.design},
          weeklyCapacity: 1.0,
        );

        final partTimeTeamMember = TeamMember(
          id: 'tm006',
          name: 'Frank Green',
          email: 'frank@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 0.5,
        );

        // Act & Assert
        expect(fullTimeTeamMember.quarterlyCapacity, equals(13.0));
        expect(partTimeTeamMember.quarterlyCapacity, equals(6.5));
      });

      test('should identify senior team members correctly', () {
        // Arrange
        final seniorMember = TeamMember(
          id: 'tm007',
          name: 'Grace Lee',
          email: 'grace@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
          skillLevel: 9,
        );

        final regularMember = TeamMember(
          id: 'tm008',
          name: 'Henry Taylor',
          email: 'henry@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
          skillLevel: 6,
        );

        // Act & Assert
        expect(seniorMember.isSenior, isTrue);
        expect(regularMember.isSenior, isFalse);
      });

      test('should identify junior team members correctly', () {
        // Arrange
        final juniorMember = TeamMember(
          id: 'tm009',
          name: 'Ivy Martinez',
          email: 'ivy@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
          skillLevel: 2,
        );

        final regularMember = TeamMember(
          id: 'tm010',
          name: 'Jack Anderson',
          email: 'jack@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
          skillLevel: 5,
        );

        // Act & Assert
        expect(juniorMember.isJunior, isTrue);
        expect(regularMember.isJunior, isFalse);
      });
    });

    group('Role Capabilities', () {
      test('should identify technical roles correctly', () {
        // Arrange
        final techMember = TeamMember(
          id: 'tm011',
          name: 'Karen White',
          email: 'karen@company.com',
          roles: {Role.frontend, Role.backend},
          weeklyCapacity: 1.0,
        );

        final nonTechMember = TeamMember(
          id: 'tm012',
          name: 'Liam Black',
          email: 'liam@company.com',
          roles: {Role.design},
          weeklyCapacity: 1.0,
        );

        // Act & Assert
        expect(techMember.hasTechnicalRoles, isTrue);
        expect(techMember.hasCodingRoles, isTrue);
        expect(nonTechMember.hasTechnicalRoles, isFalse);
        expect(nonTechMember.hasCodingRoles, isFalse);
      });

      test('should identify client-facing roles correctly', () {
        // Arrange
        final clientFacingMember = TeamMember(
          id: 'tm013',
          name: 'Maya Rodriguez',
          email: 'maya@company.com',
          roles: {Role.design, Role.frontend},
          weeklyCapacity: 1.0,
        );

        final internalMember = TeamMember(
          id: 'tm014',
          name: 'Nathan Cooper',
          email: 'nathan@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
        );

        // Act & Assert
        expect(clientFacingMember.hasClientFacingRoles, isTrue);
        expect(internalMember.hasClientFacingRoles, isFalse);
      });

      test('should check role fulfillment correctly', () {
        // Arrange
        final teamMember = TeamMember(
          id: 'tm015',
          name: 'Olivia Turner',
          email: 'olivia@company.com',
          roles: {Role.frontend, Role.design},
          weeklyCapacity: 1.0,
        );

        // Act & Assert
        expect(teamMember.canFulfillRole(Role.frontend), isTrue);
        expect(teamMember.canFulfillRole(Role.design), isTrue);
        expect(teamMember.canFulfillRole(Role.backend), isFalse);
        expect(teamMember.canFulfillRole(Role.devops), isFalse);
      });

      test('should return correct role categories', () {
        // Arrange
        final mixedRoleMember = TeamMember(
          id: 'tm016',
          name: 'Paul Johnson',
          email: 'paul@company.com',
          roles: {Role.frontend, Role.design},
          weeklyCapacity: 1.0,
        );

        // Act
        final categories = mixedRoleMember.roleCategories;

        // Assert
        expect(categories, contains('technical'));
        expect(categories, contains('client-facing'));
      });
    });

    group('Capacity Calculations', () {
      test('should calculate available capacity without unavailable periods', () {
        // Arrange
        final teamMember = TeamMember(
          id: 'tm017',
          name: 'Quinn Davis',
          email: 'quinn@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
          isActive: true,
        );

        final startDate = DateTime(2024, 6, 1);
        final endDate = DateTime(2024, 6, 28); // 4 weeks

        // Act
        final availableCapacity = teamMember.calculateAvailableCapacity(startDate, endDate);

        // Assert
        expect(availableCapacity, closeTo(3.857, 0.01)); // 27 days / 7 * 1.0 capacity
      });

      test('should calculate available capacity with unavailable periods', () {
        // Arrange
        final vacationPeriod = UnavailablePeriod(
          startDate: DateTime(2024, 6, 10),
          endDate: DateTime(2024, 6, 16), // 1 week vacation
          reason: 'Vacation',
        );

        final teamMember = TeamMember(
          id: 'tm018',
          name: 'Rachel Green',
          email: 'rachel@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
          unavailablePeriods: [vacationPeriod],
          isActive: true,
        );

        final startDate = DateTime(2024, 6, 1);
        final endDate = DateTime(2024, 6, 28); // 4 weeks total

        // Act
        final availableCapacity = teamMember.calculateAvailableCapacity(startDate, endDate);

        // Assert
        expect(availableCapacity, closeTo(3.0, 0.01)); // 3.857 weeks - 0.857 weeks vacation
      });

      test('should return zero capacity for inactive members', () {
        // Arrange
        final inactiveTeamMember = TeamMember(
          id: 'tm019',
          name: 'Sam Wilson',
          email: 'sam@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
          isActive: false,
        );

        final startDate = DateTime(2024, 6, 1);
        final endDate = DateTime(2024, 6, 28);

        // Act
        final availableCapacity = inactiveTeamMember.calculateAvailableCapacity(startDate, endDate);

        // Assert
        expect(availableCapacity, equals(0.0));
      });

      test('should handle partial week unavailable periods', () {
        // Arrange
        final partialVacation = UnavailablePeriod(
          startDate: DateTime(2024, 6, 12), // Wednesday
          endDate: DateTime(2024, 6, 14),   // Friday
          reason: 'Personal days',
        );

        final teamMember = TeamMember(
          id: 'tm020',
          name: 'Tina Brown',
          email: 'tina@company.com',
          roles: {Role.qa},
          weeklyCapacity: 1.0,
          unavailablePeriods: [partialVacation],
          isActive: true,
        );

        final startDate = DateTime(2024, 6, 1);
        final endDate = DateTime(2024, 6, 28); // 4 weeks

        // Act
        final availableCapacity = teamMember.calculateAvailableCapacity(startDate, endDate);

        // Assert
        // Should be approximately 3.57 weeks (3.857 weeks - 0.286 weeks partial vacation)
        expect(availableCapacity, closeTo(3.57, 0.01));
      });
    });

    group('Validation', () {
      test('should validate correct TeamMember successfully', () {
        // Arrange
        final validTeamMember = TeamMember(
          id: 'tm021',
          name: 'Uma Patel',
          email: 'uma@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 0.8,
          skillLevel: 7,
        );

        // Act
        final result = validTeamMember.validate();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail validation for empty ID', () {
        // Arrange
        final invalidTeamMember = TeamMember(
          id: '',
          name: 'Victor Lopez',
          email: 'victor@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
        );

        // Act
        final result = invalidTeamMember.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Team member ID cannot be empty'));
      });

      test('should fail validation for empty name', () {
        // Arrange
        final invalidTeamMember = TeamMember(
          id: 'tm022',
          name: '   ',
          email: 'whitespace@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
        );

        // Act
        final result = invalidTeamMember.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Team member name cannot be empty'));
      });

      test('should fail validation for invalid email', () {
        // Arrange
        final invalidTeamMember = TeamMember(
          id: 'tm023',
          name: 'Walter White',
          email: 'not-an-email',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
        );

        // Act
        final result = invalidTeamMember.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Team member email is not valid'));
      });

      test('should fail validation for empty roles', () {
        // Arrange
        final invalidTeamMember = TeamMember(
          id: 'tm024',
          name: 'Xander Young',
          email: 'xander@company.com',
          roles: <Role>{},
          weeklyCapacity: 1.0,
        );

        // Act
        final result = invalidTeamMember.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Team member must have at least one role'));
      });

      test('should fail validation for invalid weekly capacity', () {
        // Arrange
        final invalidTeamMember1 = TeamMember(
          id: 'tm025',
          name: 'Yara King',
          email: 'yara@company.com',
          roles: {Role.design},
          weeklyCapacity: 0.0,
        );

        final invalidTeamMember2 = TeamMember(
          id: 'tm026',
          name: 'Zoe Clark',
          email: 'zoe@company.com',
          roles: {Role.design},
          weeklyCapacity: 1.5,
        );

        // Act
        final result1 = invalidTeamMember1.validate();
        final result2 = invalidTeamMember2.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), 
               contains('Weekly capacity must be between 0 and 1.0'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), 
               contains('Weekly capacity must be between 0 and 1.0'));
      });

      test('should fail validation for invalid skill level', () {
        // Arrange
        final invalidTeamMember1 = TeamMember(
          id: 'tm027',
          name: 'Aaron Scott',
          email: 'aaron@company.com',
          roles: {Role.devops},
          weeklyCapacity: 1.0,
          skillLevel: 0,
        );

        final invalidTeamMember2 = TeamMember(
          id: 'tm028',
          name: 'Betty Adams',
          email: 'betty@company.com',
          roles: {Role.qa},
          weeklyCapacity: 1.0,
          skillLevel: 11,
        );

        // Act
        final result1 = invalidTeamMember1.validate();
        final result2 = invalidTeamMember2.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), 
               contains('Skill level must be between 1 and 10'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), 
               contains('Skill level must be between 1 and 10'));
      });

      test('should fail validation for invalid unavailable period dates', () {
        // Arrange
        final invalidPeriod = UnavailablePeriod(
          startDate: DateTime(2024, 6, 15),
          endDate: DateTime(2024, 6, 10), // End before start
          reason: 'Invalid period',
        );

        final invalidTeamMember = TeamMember(
          id: 'tm029',
          name: 'Charlie Baker',
          email: 'charlie@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
          unavailablePeriods: [invalidPeriod],
        );

        // Act
        final result = invalidTeamMember.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), 
               contains('start date must be before end date'));
      });

      test('should fail validation for overlapping unavailable periods', () {
        // Arrange
        final period1 = UnavailablePeriod(
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 10),
          reason: 'Vacation',
        );

        final period2 = UnavailablePeriod(
          startDate: DateTime(2024, 6, 5),
          endDate: DateTime(2024, 6, 15),
          reason: 'Training',
        );

        final invalidTeamMember = TeamMember(
          id: 'tm030',
          name: 'Diana Foster',
          email: 'diana@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
          unavailablePeriods: [period1, period2],
        );

        // Act
        final result = invalidTeamMember.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), 
               contains('Unavailable periods cannot overlap'));
      });
    });

    group('Serialization', () {
      test('should serialize to Map correctly', () {
        // Arrange
        final teamMember = TeamMember(
          id: 'tm031',
          name: 'Edward Hill',
          email: 'edward@company.com',
          roles: {Role.frontend, Role.design},
          weeklyCapacity: 0.8,
          skillLevel: 6,
          unavailablePeriods: [testVacation],
          notes: 'UI/UX specialist',
          isActive: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = teamMember.toMap();

        // Assert
        expect(map['id'], equals('tm031'));
        expect(map['name'], equals('Edward Hill'));
        expect(map['email'], equals('edward@company.com'));
        expect(map['roles'], isA<List>());
        expect(map['roles'], hasLength(2));
        expect(map['weeklyCapacity'], equals(0.8));
        expect(map['skillLevel'], equals(6));
        expect(map['unavailablePeriods'], isA<List>());
        expect(map['unavailablePeriods'], hasLength(1));
        expect(map['notes'], equals('UI/UX specialist'));
        expect(map['isActive'], isTrue);
        expect(map['createdAt'], equals(testCreatedAt.toIso8601String()));
        expect(map['updatedAt'], equals(testUpdatedAt.toIso8601String()));
      });

      test('should deserialize from Map correctly', () {
        // Arrange
        final map = {
          'id': 'tm032',
          'name': 'Fiona Gray',
          'email': 'fiona@company.com',
          'roles': ['frontend', 'backend'],
          'weeklyCapacity': 1.0,
          'skillLevel': 8,
          'unavailablePeriods': [
            {
              'startDate': vacationStart.toIso8601String(),
              'endDate': vacationEnd.toIso8601String(),
              'reason': 'Vacation',
              'notes': 'Summer vacation',
            }
          ],
          'notes': 'Full-stack developer',
          'isActive': true,
          'createdAt': testCreatedAt.toIso8601String(),
          'updatedAt': testUpdatedAt.toIso8601String(),
        };

        // Act
        final teamMember = TeamMember.fromMap(map);

        // Assert
        expect(teamMember.id, equals('tm032'));
        expect(teamMember.name, equals('Fiona Gray'));
        expect(teamMember.email, equals('fiona@company.com'));
        expect(teamMember.roles, hasLength(2));
        expect(teamMember.roles, contains(Role.frontend));
        expect(teamMember.roles, contains(Role.backend));
        expect(teamMember.weeklyCapacity, equals(1.0));
        expect(teamMember.skillLevel, equals(8));
        expect(teamMember.unavailablePeriods, hasLength(1));
        expect(teamMember.notes, equals('Full-stack developer'));
        expect(teamMember.isActive, isTrue);
        expect(teamMember.createdAt, equals(testCreatedAt));
        expect(teamMember.updatedAt, equals(testUpdatedAt));
      });

      test('should handle serialization round-trip correctly', () {
        // Arrange
        final originalTeamMember = TeamMember(
          id: 'tm033',
          name: 'George Miller',
          email: 'george@company.com',
          roles: {Role.devops, Role.backend},
          weeklyCapacity: 0.9,
          skillLevel: 9,
          unavailablePeriods: [testVacation],
          notes: 'DevOps and backend specialist',
          isActive: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = originalTeamMember.toMap();
        final deserializedTeamMember = TeamMember.fromMap(map);

        // Assert
        expect(deserializedTeamMember, equals(originalTeamMember));
      });
    });

    group('Copy and Mutation', () {
      test('should create copy with updated fields', () {
        // Arrange
        final originalTeamMember = TeamMember(
          id: 'tm034',
          name: 'Hannah Johnson',
          email: 'hannah@company.com',
          roles: {Role.qa},
          weeklyCapacity: 1.0,
          skillLevel: 5,
        );

        // Act
        final updatedTeamMember = originalTeamMember.copyWith(
          skillLevel: 7,
          weeklyCapacity: 0.8,
          notes: 'Promoted to senior QA',
        );

        // Assert
        expect(updatedTeamMember.id, equals(originalTeamMember.id));
        expect(updatedTeamMember.name, equals(originalTeamMember.name));
        expect(updatedTeamMember.email, equals(originalTeamMember.email));
        expect(updatedTeamMember.roles, equals(originalTeamMember.roles));
        expect(updatedTeamMember.skillLevel, equals(7));
        expect(updatedTeamMember.weeklyCapacity, equals(0.8));
        expect(updatedTeamMember.notes, equals('Promoted to senior QA'));
      });

      test('should preserve original when no fields updated in copy', () {
        // Arrange
        final originalTeamMember = TeamMember(
          id: 'tm035',
          name: 'Ian Roberts',
          email: 'ian@company.com',
          roles: {Role.design},
          weeklyCapacity: 1.0,
        );

        // Act
        final copiedTeamMember = originalTeamMember.copyWith();

        // Assert
        expect(copiedTeamMember, equals(originalTeamMember));
        expect(identical(copiedTeamMember, originalTeamMember), isFalse);
      });
    });

    group('Equality and String Representation', () {
      test('should implement equality correctly', () {
        // Arrange
        final teamMember1 = TeamMember(
          id: 'tm036',
          name: 'Julia Chen',
          email: 'julia@company.com',
          roles: {Role.design},
          weeklyCapacity: 1.0,
          skillLevel: 6,
        );

        final teamMember2 = TeamMember(
          id: 'tm036',
          name: 'Julia Chen',
          email: 'julia@company.com',
          roles: {Role.design},
          weeklyCapacity: 1.0,
          skillLevel: 6,
        );

        final teamMember3 = TeamMember(
          id: 'tm037',
          name: 'Julia Chen',
          email: 'julia@company.com',
          roles: {Role.design},
          weeklyCapacity: 1.0,
          skillLevel: 6,
        );

        // Act & Assert
        expect(teamMember1, equals(teamMember2));
        expect(teamMember1, isNot(equals(teamMember3)));
        expect(teamMember1.hashCode, equals(teamMember2.hashCode));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        final teamMember = TeamMember(
          id: 'tm038',
          name: 'Kevin Wright',
          email: 'kevin@company.com',
          roles: {Role.frontend, Role.backend},
          weeklyCapacity: 0.8,
          skillLevel: 7,
        );

        // Act
        final stringRep = teamMember.toString();

        // Assert
        expect(stringRep, contains('tm038'));
        expect(stringRep, contains('Kevin Wright'));
        expect(stringRep, contains('0.8w/week'));
        expect(stringRep, contains('skill: 7'));
        expect(stringRep, contains('Frontend'));
        expect(stringRep, contains('Backend'));
      });
    });
  });

  group('UnavailablePeriod Tests', () {
    late DateTime startDate;
    late DateTime endDate;

    setUp(() {
      startDate = DateTime(2024, 6, 1);
      endDate = DateTime(2024, 6, 14);
    });

    group('Construction and Properties', () {
      test('should create UnavailablePeriod with required fields', () {
        // Arrange & Act
        final period = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Vacation',
        );

        // Assert
        expect(period.startDate, equals(startDate));
        expect(period.endDate, equals(endDate));
        expect(period.reason, equals('Vacation'));
        expect(period.notes, equals(''));
      });

      test('should create UnavailablePeriod with all fields', () {
        // Arrange & Act
        final period = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Training',
          notes: 'Flutter advanced course',
        );

        // Assert
        expect(period.startDate, equals(startDate));
        expect(period.endDate, equals(endDate));
        expect(period.reason, equals('Training'));
        expect(period.notes, equals('Flutter advanced course'));
      });
    });

    group('Duration Calculations', () {
      test('should calculate duration in days correctly', () {
        // Arrange
        final period = UnavailablePeriod(
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 7),
          reason: 'Vacation',
        );

        // Act & Assert
        expect(period.durationInDays, equals(7));
      });

      test('should calculate duration in weeks correctly', () {
        // Arrange
        final period = UnavailablePeriod(
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 14),
          reason: 'Vacation',
        );

        // Act & Assert
        expect(period.durationInWeeks, closeTo(2.0, 0.01));
      });

      test('should handle single day periods', () {
        // Arrange
        final period = UnavailablePeriod(
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 1),
          reason: 'Personal day',
        );

        // Act & Assert
        expect(period.durationInDays, equals(1));
        expect(period.durationInWeeks, closeTo(0.14, 0.01));
      });
    });

    group('Serialization', () {
      test('should serialize to Map correctly', () {
        // Arrange
        final period = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Conference',
          notes: 'Flutter Forward',
        );

        // Act
        final map = period.toMap();

        // Assert
        expect(map['startDate'], equals(startDate.toIso8601String()));
        expect(map['endDate'], equals(endDate.toIso8601String()));
        expect(map['reason'], equals('Conference'));
        expect(map['notes'], equals('Flutter Forward'));
      });

      test('should deserialize from Map correctly', () {
        // Arrange
        final map = {
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'reason': 'Sick leave',
          'notes': 'Doctor appointment',
        };

        // Act
        final period = UnavailablePeriod.fromMap(map);

        // Assert
        expect(period.startDate, equals(startDate));
        expect(period.endDate, equals(endDate));
        expect(period.reason, equals('Sick leave'));
        expect(period.notes, equals('Doctor appointment'));
      });

      test('should handle serialization round-trip correctly', () {
        // Arrange
        final originalPeriod = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Training',
          notes: 'Leadership workshop',
        );

        // Act
        final map = originalPeriod.toMap();
        final deserializedPeriod = UnavailablePeriod.fromMap(map);

        // Assert
        expect(deserializedPeriod, equals(originalPeriod));
      });
    });

    group('Copy and Mutation', () {
      test('should create copy with updated fields', () {
        // Arrange
        final originalPeriod = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Vacation',
          notes: 'Family trip',
        );

        // Act
        final updatedPeriod = originalPeriod.copyWith(
          reason: 'Personal leave',
          notes: 'Extended family trip',
        );

        // Assert
        expect(updatedPeriod.startDate, equals(originalPeriod.startDate));
        expect(updatedPeriod.endDate, equals(originalPeriod.endDate));
        expect(updatedPeriod.reason, equals('Personal leave'));
        expect(updatedPeriod.notes, equals('Extended family trip'));
      });
    });

    group('Equality and String Representation', () {
      test('should implement equality correctly', () {
        // Arrange
        final period1 = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Vacation',
          notes: 'Summer break',
        );

        final period2 = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Vacation',
          notes: 'Summer break',
        );

        final period3 = UnavailablePeriod(
          startDate: startDate,
          endDate: endDate,
          reason: 'Training',
          notes: 'Summer break',
        );

        // Act & Assert
        expect(period1, equals(period2));
        expect(period1, isNot(equals(period3)));
        expect(period1.hashCode, equals(period2.hashCode));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        final period = UnavailablePeriod(
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 14),
          reason: 'Vacation',
          notes: 'Summer holiday',
        );

        // Act
        final stringRep = period.toString();

        // Assert
        expect(stringRep, contains('2024-06-01'));
        expect(stringRep, contains('2024-06-14'));
        expect(stringRep, contains('Vacation'));
      });
    });
  });
}
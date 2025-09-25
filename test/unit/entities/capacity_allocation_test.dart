/// Unit tests for CapacityAllocation entity.
/// 
/// Tests comprehensive functionality including:
/// - Construction and property validation
/// - Computed properties and calculations
/// - Business logic and status management
/// - Validation rules and edge cases
/// - Serialization and deserialization
library;

import 'package:test/test.dart';
import 'package:capest_timeline/core/enums/role.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/capacity_allocation.dart';

void main() {
  group('CapacityAllocation Entity Tests', () {
    late DateTime testStartDate;
    late DateTime testEndDate;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testStartDate = DateTime(2024, 6, 1);
      testEndDate = DateTime(2024, 6, 28); // 4 weeks duration
      testCreatedAt = DateTime(2024, 5, 15);
      testUpdatedAt = DateTime(2024, 5, 20);
    });

    group('Construction and Basic Properties', () {
      test('should create valid CapacityAllocation with required fields', () {
        // Arrange & Act
        final allocation = CapacityAllocation(
          id: 'ca001',
          teamMemberId: 'tm001',
          initiativeId: 'init001',
          role: Role.frontend,
          allocatedWeeks: 2.0,
          startDate: testStartDate,
          endDate: testEndDate,
        );

        // Assert
        expect(allocation.id, equals('ca001'));
        expect(allocation.teamMemberId, equals('tm001'));
        expect(allocation.initiativeId, equals('init001'));
        expect(allocation.role, equals(Role.frontend));
        expect(allocation.allocatedWeeks, equals(2.0));
        expect(allocation.startDate, equals(testStartDate));
        expect(allocation.endDate, equals(testEndDate));
        expect(allocation.status, equals(AllocationStatus.planned)); // default
        expect(allocation.notes, equals('')); // default
        expect(allocation.createdAt, isNull);
        expect(allocation.updatedAt, isNull);
      });

      test('should create CapacityAllocation with all optional fields', () {
        // Arrange & Act
        final allocation = CapacityAllocation(
          id: 'ca002',
          teamMemberId: 'tm002',
          initiativeId: 'init002',
          role: Role.backend,
          allocatedWeeks: 3.5,
          startDate: testStartDate,
          endDate: testEndDate,
          status: AllocationStatus.inProgress,
          notes: 'Lead backend development',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(allocation.id, equals('ca002'));
        expect(allocation.teamMemberId, equals('tm002'));
        expect(allocation.initiativeId, equals('init002'));
        expect(allocation.role, equals(Role.backend));
        expect(allocation.allocatedWeeks, equals(3.5));
        expect(allocation.status, equals(AllocationStatus.inProgress));
        expect(allocation.notes, equals('Lead backend development'));
        expect(allocation.createdAt, equals(testCreatedAt));
        expect(allocation.updatedAt, equals(testUpdatedAt));
      });
    });

    group('Duration Calculations', () {
      test('should calculate duration in days correctly', () {
        // Arrange
        final allocation = CapacityAllocation(
          id: 'ca003',
          teamMemberId: 'tm003',
          initiativeId: 'init003',
          role: Role.design,
          allocatedWeeks: 1.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 7), // 7 days
        );

        // Act & Assert
        expect(allocation.durationInDays, equals(7));
      });

      test('should calculate duration in weeks correctly', () {
        // Arrange
        final allocation = CapacityAllocation(
          id: 'ca004',
          teamMemberId: 'tm004',
          initiativeId: 'init004',
          role: Role.qa,
          allocatedWeeks: 2.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 14), // 14 days
        );

        // Act & Assert
        expect(allocation.durationInWeeks, equals(2.0));
      });

      test('should handle single day duration', () {
        // Arrange
        final allocation = CapacityAllocation(
          id: 'ca005',
          teamMemberId: 'tm005',
          initiativeId: 'init005',
          role: Role.devops,
          allocatedWeeks: 0.2,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 1), // Same day
        );

        // Act & Assert
        expect(allocation.durationInDays, equals(1));
        expect(allocation.durationInWeeks, closeTo(0.14, 0.01));
      });
    });

    group('Capacity Utilization Calculations', () {
      test('should calculate weekly utilization correctly', () {
        // Arrange
        final fullUtilization = CapacityAllocation(
          id: 'ca006',
          teamMemberId: 'tm006',
          initiativeId: 'init006',
          role: Role.frontend,
          allocatedWeeks: 4.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 28), // 4 weeks
        );

        final partialUtilization = CapacityAllocation(
          id: 'ca007',
          teamMemberId: 'tm007',
          initiativeId: 'init007',
          role: Role.backend,
          allocatedWeeks: 2.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 28), // 4 weeks
        );

        // Act & Assert
        expect(fullUtilization.weeklyUtilization, equals(1.0)); // 100%
        expect(partialUtilization.weeklyUtilization, equals(0.5)); // 50%
      });

      test('should calculate weekly capacity needed correctly', () {
        // Arrange
        final allocation = CapacityAllocation(
          id: 'ca008',
          teamMemberId: 'tm008',
          initiativeId: 'init008',
          role: Role.design,
          allocatedWeeks: 3.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 21), // 3 weeks
        );

        // Act & Assert
        expect(allocation.weeklyCapacityNeeded, equals(1.0)); // 3 weeks / 3 weeks
      });

      test('should identify overcommitted allocations', () {
        // Arrange
        final overcommittedAllocation = CapacityAllocation(
          id: 'ca009',
          teamMemberId: 'tm009',
          initiativeId: 'init009',
          role: Role.frontend,
          allocatedWeeks: 6.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 28), // 4 weeks, so 150% utilization
        );

        final normalAllocation = CapacityAllocation(
          id: 'ca010',
          teamMemberId: 'tm010',
          initiativeId: 'init010',
          role: Role.backend,
          allocatedWeeks: 2.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 28), // 4 weeks, so 50% utilization
        );

        // Act & Assert
        expect(overcommittedAllocation.isOvercommitted, isTrue);
        expect(normalAllocation.isOvercommitted, isFalse);
      });
    });

    group('Status Management', () {
      test('should identify planned allocations correctly', () {
        // Arrange
        final plannedAllocation = CapacityAllocation(
          id: 'ca011',
          teamMemberId: 'tm011',
          initiativeId: 'init011',
          role: Role.qa,
          allocatedWeeks: 1.0,
          startDate: DateTime(2025, 1, 1), // Future date
          endDate: DateTime(2025, 1, 7),
          status: AllocationStatus.planned,
        );

        // Act & Assert
        expect(plannedAllocation.isPlanned, isTrue);
        expect(plannedAllocation.isActive, isFalse);
        expect(plannedAllocation.isCompleted, isFalse);
        expect(plannedAllocation.isCancelled, isFalse);
      });

      test('should identify in-progress allocations correctly', () {
        // Arrange
        final now = DateTime.now();
        final inProgressAllocation = CapacityAllocation(
          id: 'ca012',
          teamMemberId: 'tm012',
          initiativeId: 'init012',
          role: Role.devops,
          allocatedWeeks: 2.0,
          startDate: now.subtract(const Duration(days: 7)), // Started a week ago
          endDate: now.add(const Duration(days: 7)), // Ends in a week
          status: AllocationStatus.inProgress,
        );

        // Act & Assert
        expect(inProgressAllocation.isPlanned, isFalse);
        expect(inProgressAllocation.isActive, isTrue);
        expect(inProgressAllocation.isCompleted, isFalse);
        expect(inProgressAllocation.isCancelled, isFalse);
      });

      test('should identify completed allocations correctly', () {
        // Arrange
        final completedAllocation = CapacityAllocation(
          id: 'ca013',
          teamMemberId: 'tm013',
          initiativeId: 'init013',
          role: Role.design,
          allocatedWeeks: 1.5,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 14),
          status: AllocationStatus.completed,
        );

        // Act & Assert
        expect(completedAllocation.isPlanned, isFalse);
        expect(completedAllocation.isActive, isFalse);
        expect(completedAllocation.isCompleted, isTrue);
        expect(completedAllocation.isCancelled, isFalse);
      });

      test('should identify cancelled allocations correctly', () {
        // Arrange
        final cancelledAllocation = CapacityAllocation(
          id: 'ca014',
          teamMemberId: 'tm014',
          initiativeId: 'init014',
          role: Role.frontend,
          allocatedWeeks: 3.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 21),
          status: AllocationStatus.cancelled,
        );

        // Act & Assert
        expect(cancelledAllocation.isPlanned, isFalse);
        expect(cancelledAllocation.isActive, isFalse);
        expect(cancelledAllocation.isCompleted, isFalse);
        expect(cancelledAllocation.isCancelled, isTrue);
      });
    });

    group('Progress Calculations', () {
      test('should return 0% progress for planned allocations', () {
        // Arrange
        final plannedAllocation = CapacityAllocation(
          id: 'ca015',
          teamMemberId: 'tm015',
          initiativeId: 'init015',
          role: Role.backend,
          allocatedWeeks: 2.0,
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 1, 14),
          status: AllocationStatus.planned,
        );

        // Act & Assert
        expect(plannedAllocation.progressPercentage, equals(0.0));
      });

      test('should return 100% progress for completed allocations', () {
        // Arrange
        final completedAllocation = CapacityAllocation(
          id: 'ca016',
          teamMemberId: 'tm016',
          initiativeId: 'init016',
          role: Role.qa,
          allocatedWeeks: 1.0,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
          status: AllocationStatus.completed,
        );

        // Act & Assert
        expect(completedAllocation.progressPercentage, equals(100.0));
      });

      test('should return 0% progress for cancelled allocations', () {
        // Arrange
        final cancelledAllocation = CapacityAllocation(
          id: 'ca017',
          teamMemberId: 'tm017',
          initiativeId: 'init017',
          role: Role.devops,
          allocatedWeeks: 1.5,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 14),
          status: AllocationStatus.cancelled,
        );

        // Act & Assert
        expect(cancelledAllocation.progressPercentage, equals(0.0));
      });

      test('should calculate progress for in-progress allocations', () {
        // Arrange
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7)); // Started 7 days ago
        final endDate = now.add(const Duration(days: 7)); // Ends in 7 days (total 14 days)
        
        final inProgressAllocation = CapacityAllocation(
          id: 'ca018',
          teamMemberId: 'tm018',
          initiativeId: 'init018',
          role: Role.design,
          allocatedWeeks: 2.0,
          startDate: startDate,
          endDate: endDate,
          status: AllocationStatus.inProgress,
        );

        // Act & Assert
        // Should be approximately 50% (7 days elapsed out of 14 total days)
        expect(inProgressAllocation.progressPercentage, closeTo(50.0, 5.0));
      });

      test('should handle progress for future in-progress allocations', () {
        // Arrange
        final futureAllocation = CapacityAllocation(
          id: 'ca019',
          teamMemberId: 'tm019',
          initiativeId: 'init019',
          role: Role.frontend,
          allocatedWeeks: 1.0,
          startDate: DateTime.now().add(const Duration(days: 7)),
          endDate: DateTime.now().add(const Duration(days: 14)),
          status: AllocationStatus.inProgress,
        );

        // Act & Assert
        expect(futureAllocation.progressPercentage, equals(0.0));
      });

      test('should handle progress for past in-progress allocations', () {
        // Arrange
        final pastAllocation = CapacityAllocation(
          id: 'ca020',
          teamMemberId: 'tm020',
          initiativeId: 'init020',
          role: Role.backend,
          allocatedWeeks: 1.0,
          startDate: DateTime.now().subtract(const Duration(days: 14)),
          endDate: DateTime.now().subtract(const Duration(days: 7)),
          status: AllocationStatus.inProgress,
        );

        // Act & Assert
        expect(pastAllocation.progressPercentage, equals(100.0));
      });
    });

    group('Multi-Quarter Detection', () {
      test('should identify single quarter allocations', () {
        // Arrange - Q2 2024 (April-June)
        final singleQuarterAllocation = CapacityAllocation(
          id: 'ca021',
          teamMemberId: 'tm021',
          initiativeId: 'init021',
          role: Role.qa,
          allocatedWeeks: 4.0,
          startDate: DateTime(2024, 5, 1), // May
          endDate: DateTime(2024, 6, 30), // June
        );

        // Act & Assert
        expect(singleQuarterAllocation.isMultiQuarter, isFalse);
      });

      test('should identify multi-quarter allocations within same year', () {
        // Arrange - Q2 to Q3 2024
        final multiQuarterAllocation = CapacityAllocation(
          id: 'ca022',
          teamMemberId: 'tm022',
          initiativeId: 'init022',
          role: Role.devops,
          allocatedWeeks: 8.0,
          startDate: DateTime(2024, 6, 1), // Q2
          endDate: DateTime(2024, 8, 31), // Q3
        );

        // Act & Assert
        expect(multiQuarterAllocation.isMultiQuarter, isTrue);
      });

      test('should identify multi-quarter allocations across years', () {
        // Arrange - Q4 2024 to Q1 2025
        final yearSpanningAllocation = CapacityAllocation(
          id: 'ca023',
          teamMemberId: 'tm023',
          initiativeId: 'init023',
          role: Role.design,
          allocatedWeeks: 6.0,
          startDate: DateTime(2024, 12, 1), // Q4 2024
          endDate: DateTime(2025, 2, 28), // Q1 2025
        );

        // Act & Assert
        expect(yearSpanningAllocation.isMultiQuarter, isTrue);
      });
    });

    group('Validation', () {
      test('should validate correct CapacityAllocation successfully', () {
        // Arrange
        final validAllocation = CapacityAllocation(
          id: 'ca024',
          teamMemberId: 'tm024',
          initiativeId: 'init024',
          role: Role.frontend,
          allocatedWeeks: 3.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 21),
        );

        // Act
        final result = validAllocation.validate();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail validation for empty ID', () {
        // Arrange
        final invalidAllocation = CapacityAllocation(
          id: '',
          teamMemberId: 'tm025',
          initiativeId: 'init025',
          role: Role.backend,
          allocatedWeeks: 2.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 14),
        );

        // Act
        final result = invalidAllocation.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Allocation ID cannot be empty'));
      });

      test('should fail validation for empty team member ID', () {
        // Arrange
        final invalidAllocation = CapacityAllocation(
          id: 'ca026',
          teamMemberId: '   ',
          initiativeId: 'init026',
          role: Role.qa,
          allocatedWeeks: 1.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 7),
        );

        // Act
        final result = invalidAllocation.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Team member ID cannot be empty'));
      });

      test('should fail validation for empty initiative ID', () {
        // Arrange
        final invalidAllocation = CapacityAllocation(
          id: 'ca027',
          teamMemberId: 'tm027',
          initiativeId: '',
          role: Role.devops,
          allocatedWeeks: 2.5,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 18),
        );

        // Act
        final result = invalidAllocation.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Initiative ID cannot be empty'));
      });

      test('should fail validation for invalid date range', () {
        // Arrange
        final invalidAllocation = CapacityAllocation(
          id: 'ca028',
          teamMemberId: 'tm028',
          initiativeId: 'init028',
          role: Role.design,
          allocatedWeeks: 1.0,
          startDate: DateTime(2024, 6, 15),
          endDate: DateTime(2024, 6, 10), // End before start
        );

        // Act
        final result = invalidAllocation.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), 
               contains('Start date must be before or equal to end date'));
      });

      test('should fail validation for zero or negative allocated weeks', () {
        // Arrange
        final zeroWeeksAllocation = CapacityAllocation(
          id: 'ca029',
          teamMemberId: 'tm029',
          initiativeId: 'init029',
          role: Role.frontend,
          allocatedWeeks: 0.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 7),
        );

        final negativeWeeksAllocation = CapacityAllocation(
          id: 'ca030',
          teamMemberId: 'tm030',
          initiativeId: 'init030',
          role: Role.backend,
          allocatedWeeks: -1.0,
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 7),
        );

        // Act
        final result1 = zeroWeeksAllocation.validate();
        final result2 = negativeWeeksAllocation.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), 
               contains('Allocated weeks must be positive'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), 
               contains('Allocated weeks must be positive'));
      });

      test('should fail validation for excessive allocated weeks', () {
        // Arrange
        final excessiveAllocation = CapacityAllocation(
          id: 'ca031',
          teamMemberId: 'tm031',
          initiativeId: 'init031',
          role: Role.qa,
          allocatedWeeks: 60.0, // More than a year
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 12, 31),
        );

        // Act
        final result = excessiveAllocation.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), 
               contains('Allocated weeks cannot exceed 52'));
      });

      test('should fail validation for extreme weekly utilization', () {
        // Arrange
        final extremeUtilizationAllocation = CapacityAllocation(
          id: 'ca032',
          teamMemberId: 'tm032',
          initiativeId: 'init032',
          role: Role.devops,
          allocatedWeeks: 12.0, // 12 weeks allocated
          startDate: DateTime(2024, 6, 1),
          endDate: DateTime(2024, 6, 28), // But only 4 weeks duration = 300% utilization
        );

        // Act
        final result = extremeUtilizationAllocation.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), 
               contains('Weekly utilization'));
        expect(result.error.allErrors.join(' '), 
               contains('exceeds reasonable limits'));
      });

      test('should fail validation for excessive duration', () {
        // Arrange
        final longDurationAllocation = CapacityAllocation(
          id: 'ca033',
          teamMemberId: 'tm033',
          initiativeId: 'init033',
          role: Role.design,
          allocatedWeeks: 30.0,
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 12, 31), // Almost a full year
        );

        // Act
        final result = longDurationAllocation.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), 
               contains('Allocation duration cannot exceed 26 weeks'));
      });
    });

    group('Serialization', () {
      test('should serialize to Map correctly', () {
        // Arrange
        final allocation = CapacityAllocation(
          id: 'ca034',
          teamMemberId: 'tm034',
          initiativeId: 'init034',
          role: Role.frontend,
          allocatedWeeks: 4.5,
          startDate: testStartDate,
          endDate: testEndDate,
          status: AllocationStatus.inProgress,
          notes: 'Lead frontend development',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = allocation.toMap();

        // Assert
        expect(map['id'], equals('ca034'));
        expect(map['teamMemberId'], equals('tm034'));
        expect(map['initiativeId'], equals('init034'));
        expect(map['role'], equals('frontend'));
        expect(map['allocatedWeeks'], equals(4.5));
        expect(map['startDate'], equals(testStartDate.toIso8601String()));
        expect(map['endDate'], equals(testEndDate.toIso8601String()));
        expect(map['status'], equals('inProgress'));
        expect(map['notes'], equals('Lead frontend development'));
        expect(map['createdAt'], equals(testCreatedAt.toIso8601String()));
        expect(map['updatedAt'], equals(testUpdatedAt.toIso8601String()));
      });

      test('should deserialize from Map correctly', () {
        // Arrange
        final map = {
          'id': 'ca035',
          'teamMemberId': 'tm035',
          'initiativeId': 'init035',
          'role': 'backend',
          'allocatedWeeks': 3.0,
          'startDate': testStartDate.toIso8601String(),
          'endDate': testEndDate.toIso8601String(),
          'status': 'completed',
          'notes': 'API development completed',
          'createdAt': testCreatedAt.toIso8601String(),
          'updatedAt': testUpdatedAt.toIso8601String(),
        };

        // Act
        final allocation = CapacityAllocation.fromMap(map);

        // Assert
        expect(allocation.id, equals('ca035'));
        expect(allocation.teamMemberId, equals('tm035'));
        expect(allocation.initiativeId, equals('init035'));
        expect(allocation.role, equals(Role.backend));
        expect(allocation.allocatedWeeks, equals(3.0));
        expect(allocation.startDate, equals(testStartDate));
        expect(allocation.endDate, equals(testEndDate));
        expect(allocation.status, equals(AllocationStatus.completed));
        expect(allocation.notes, equals('API development completed'));
        expect(allocation.createdAt, equals(testCreatedAt));
        expect(allocation.updatedAt, equals(testUpdatedAt));
      });

      test('should handle serialization round-trip correctly', () {
        // Arrange
        final originalAllocation = CapacityAllocation(
          id: 'ca036',
          teamMemberId: 'tm036',
          initiativeId: 'init036',
          role: Role.qa,
          allocatedWeeks: 2.5,
          startDate: testStartDate,
          endDate: testEndDate,
          status: AllocationStatus.cancelled,
          notes: 'Project cancelled due to budget constraints',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = originalAllocation.toMap();
        final deserializedAllocation = CapacityAllocation.fromMap(map);

        // Assert
        expect(deserializedAllocation, equals(originalAllocation));
      });

      test('should handle deserialization with missing optional fields', () {
        // Arrange
        final minimalMap = {
          'id': 'ca037',
          'teamMemberId': 'tm037',
          'initiativeId': 'init037',
          'role': 'devops',
          'allocatedWeeks': 1.5,
          'startDate': testStartDate.toIso8601String(),
          'endDate': testEndDate.toIso8601String(),
        };

        // Act
        final allocation = CapacityAllocation.fromMap(minimalMap);

        // Assert
        expect(allocation.id, equals('ca037'));
        expect(allocation.role, equals(Role.devops));
        expect(allocation.status, equals(AllocationStatus.planned)); // default
        expect(allocation.notes, equals('')); // default
        expect(allocation.createdAt, isNull);
        expect(allocation.updatedAt, isNull);
      });
    });

    group('Copy and Mutation', () {
      test('should create copy with updated fields', () {
        // Arrange
        final originalAllocation = CapacityAllocation(
          id: 'ca038',
          teamMemberId: 'tm038',
          initiativeId: 'init038',
          role: Role.design,
          allocatedWeeks: 2.0,
          startDate: testStartDate,
          endDate: testEndDate,
          status: AllocationStatus.planned,
        );

        // Act
        final updatedAllocation = originalAllocation.copyWith(
          status: AllocationStatus.inProgress,
          allocatedWeeks: 2.5,
          notes: 'Started design work',
        );

        // Assert
        expect(updatedAllocation.id, equals(originalAllocation.id));
        expect(updatedAllocation.teamMemberId, equals(originalAllocation.teamMemberId));
        expect(updatedAllocation.initiativeId, equals(originalAllocation.initiativeId));
        expect(updatedAllocation.role, equals(originalAllocation.role));
        expect(updatedAllocation.startDate, equals(originalAllocation.startDate));
        expect(updatedAllocation.endDate, equals(originalAllocation.endDate));
        expect(updatedAllocation.status, equals(AllocationStatus.inProgress));
        expect(updatedAllocation.allocatedWeeks, equals(2.5));
        expect(updatedAllocation.notes, equals('Started design work'));
      });

      test('should preserve original when no fields updated in copy', () {
        // Arrange
        final originalAllocation = CapacityAllocation(
          id: 'ca039',
          teamMemberId: 'tm039',
          initiativeId: 'init039',
          role: Role.mobile,
          allocatedWeeks: 3.0,
          startDate: testStartDate,
          endDate: testEndDate,
        );

        // Act
        final copiedAllocation = originalAllocation.copyWith();

        // Assert
        expect(copiedAllocation, equals(originalAllocation));
        expect(identical(copiedAllocation, originalAllocation), isFalse);
      });
    });

    group('Equality and String Representation', () {
      test('should implement equality correctly', () {
        // Arrange
        final allocation1 = CapacityAllocation(
          id: 'ca040',
          teamMemberId: 'tm040',
          initiativeId: 'init040',
          role: Role.frontend,
          allocatedWeeks: 1.0,
          startDate: testStartDate,
          endDate: testEndDate,
        );

        final allocation2 = CapacityAllocation(
          id: 'ca040',
          teamMemberId: 'tm040',
          initiativeId: 'init040',
          role: Role.frontend,
          allocatedWeeks: 1.0,
          startDate: testStartDate,
          endDate: testEndDate,
        );

        final allocation3 = CapacityAllocation(
          id: 'ca041',
          teamMemberId: 'tm040',
          initiativeId: 'init040',
          role: Role.frontend,
          allocatedWeeks: 1.0,
          startDate: testStartDate,
          endDate: testEndDate,
        );

        // Act & Assert
        expect(allocation1, equals(allocation2));
        expect(allocation1, isNot(equals(allocation3)));
        expect(allocation1.hashCode, equals(allocation2.hashCode));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        final allocation = CapacityAllocation(
          id: 'ca042',
          teamMemberId: 'tm042',
          initiativeId: 'init042',
          role: Role.backend,
          allocatedWeeks: 3.5,
          startDate: testStartDate,
          endDate: testEndDate,
          status: AllocationStatus.inProgress,
        );

        // Act
        final stringRep = allocation.toString();

        // Assert
        expect(stringRep, contains('ca042'));
        expect(stringRep, contains('tm042'));
        expect(stringRep, contains('init042'));
        expect(stringRep, contains('Backend'));
        expect(stringRep, contains('3.5'));
        expect(stringRep, contains('In Progress'));
      });
    });
  });

  group('AllocationStatus Enum Tests', () {
    group('Status Properties', () {
      test('should identify active statuses correctly', () {
        // Act & Assert
        expect(AllocationStatus.planned.isActive, isFalse);
        expect(AllocationStatus.inProgress.isActive, isTrue);
        expect(AllocationStatus.completed.isActive, isFalse);
        expect(AllocationStatus.cancelled.isActive, isFalse);
      });

      test('should identify finished statuses correctly', () {
        // Act & Assert
        expect(AllocationStatus.planned.isFinished, isFalse);
        expect(AllocationStatus.inProgress.isFinished, isFalse);
        expect(AllocationStatus.completed.isFinished, isTrue);
        expect(AllocationStatus.cancelled.isFinished, isTrue);
      });

      test('should identify modifiable statuses correctly', () {
        // Act & Assert
        expect(AllocationStatus.planned.canBeModified, isTrue);
        expect(AllocationStatus.inProgress.canBeModified, isTrue);
        expect(AllocationStatus.completed.canBeModified, isFalse);
        expect(AllocationStatus.cancelled.canBeModified, isFalse);
      });

      test('should provide correct color indicators', () {
        // Act & Assert
        expect(AllocationStatus.planned.colorIndicator, equals('blue'));
        expect(AllocationStatus.inProgress.colorIndicator, equals('green'));
        expect(AllocationStatus.completed.colorIndicator, equals('gray'));
        expect(AllocationStatus.cancelled.colorIndicator, equals('red'));
      });

      test('should provide correct display names', () {
        // Act & Assert
        expect(AllocationStatus.planned.displayName, equals('Planned'));
        expect(AllocationStatus.inProgress.displayName, equals('In Progress'));
        expect(AllocationStatus.completed.displayName, equals('Completed'));
        expect(AllocationStatus.cancelled.displayName, equals('Cancelled'));
      });
    });
  });
}
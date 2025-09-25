/// Unit tests for QuarterPlan entity.
/// 
/// Tests comprehensive functionality including:
/// - Construction and property validation
/// - Capacity calculations and aggregations
/// - Business logic and utilization analysis
/// - Validation rules and referential integrity
/// - Serialization and deserialization
library;

import 'package:test/test.dart';
import 'package:capest_timeline/core/enums/role.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/quarter_plan.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/initiative.dart';
import 'package:capest_timeline/features/capacity_planning/domain/entities/capacity_allocation.dart';
import 'package:capest_timeline/features/team_management/domain/entities/team_member.dart';

void main() {
  group('QuarterPlan Entity Tests', () {
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;
    late List<Initiative> testInitiatives;
    late List<TeamMember> testTeamMembers;
    late List<CapacityAllocation> testAllocations;

    setUp(() {
      testCreatedAt = DateTime(2024, 5, 1);
      testUpdatedAt = DateTime(2024, 5, 15);

      // Create test initiatives
      testInitiatives = [
        Initiative(
          id: 'init001',
          name: 'Mobile App Redesign',
          description: 'Redesign mobile application UI',
          priority: 8,
          businessValue: 9,
          requiredRoles: {
            Role.frontend: 4.0,
            Role.design: 2.0,
          },
          estimatedEffortWeeks: 6.0,
          dependencies: [],
        ),
        Initiative(
          id: 'init002',
          name: 'API Modernization',
          description: 'Upgrade backend APIs to latest standards',
          priority: 6,
          businessValue: 7,
          requiredRoles: {
            Role.backend: 6.0,
            Role.devops: 2.0,
          },
          estimatedEffortWeeks: 8.0,
          dependencies: [],
        ),
      ];

      // Create test team members
      testTeamMembers = [
        TeamMember(
          id: 'tm001',
          name: 'Alice Frontend',
          email: 'alice@company.com',
          roles: {Role.frontend},
          weeklyCapacity: 1.0,
          skillLevel: 8,
          isActive: true,
        ),
        TeamMember(
          id: 'tm002',
          name: 'Bob Backend',
          email: 'bob@company.com',
          roles: {Role.backend},
          weeklyCapacity: 1.0,
          skillLevel: 9,
          isActive: true,
        ),
        TeamMember(
          id: 'tm003',
          name: 'Carol Designer',
          email: 'carol@company.com',
          roles: {Role.design},
          weeklyCapacity: 0.8,
          skillLevel: 7,
          isActive: true,
        ),
      ];

      // Create test allocations
      testAllocations = [
        CapacityAllocation(
          id: 'ca001',
          teamMemberId: 'tm001',
          initiativeId: 'init001',
          role: Role.frontend,
          allocatedWeeks: 3.0,
          startDate: DateTime(2024, 7, 1),
          endDate: DateTime(2024, 7, 21),
          status: AllocationStatus.planned,
        ),
        CapacityAllocation(
          id: 'ca002',
          teamMemberId: 'tm002',
          initiativeId: 'init002',
          role: Role.backend,
          allocatedWeeks: 5.0,
          startDate: DateTime(2024, 7, 15),
          endDate: DateTime(2024, 8, 19),
          status: AllocationStatus.planned,
        ),
      ];
    });

    group('Construction and Basic Properties', () {
      test('should create valid QuarterPlan with required fields', () {
        // Arrange & Act
        final quarterPlan = QuarterPlan(
          id: 'qp001',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Assert
        expect(quarterPlan.id, equals('qp001'));
        expect(quarterPlan.quarter, equals(3));
        expect(quarterPlan.year, equals(2024));
        expect(quarterPlan.initiatives, equals(testInitiatives));
        expect(quarterPlan.teamMembers, equals(testTeamMembers));
        expect(quarterPlan.allocations, equals(testAllocations));
        expect(quarterPlan.name, isNull);
        expect(quarterPlan.notes, equals(''));
        expect(quarterPlan.isLocked, isFalse);
        expect(quarterPlan.createdAt, isNull);
        expect(quarterPlan.updatedAt, isNull);
      });

      test('should create QuarterPlan with all optional fields', () {
        // Arrange & Act
        final quarterPlan = QuarterPlan(
          id: 'qp002',
          quarter: 4,
          year: 2024,
          name: 'Q4 2024 Strategic Plan',
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
          notes: 'Focus on mobile and API improvements',
          isLocked: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Assert
        expect(quarterPlan.id, equals('qp002'));
        expect(quarterPlan.quarter, equals(4));
        expect(quarterPlan.year, equals(2024));
        expect(quarterPlan.name, equals('Q4 2024 Strategic Plan'));
        expect(quarterPlan.notes, equals('Focus on mobile and API improvements'));
        expect(quarterPlan.isLocked, isTrue);
        expect(quarterPlan.createdAt, equals(testCreatedAt));
        expect(quarterPlan.updatedAt, equals(testUpdatedAt));
      });
    });

    group('Display Name and Date Range', () {
      test('should generate correct display name when name is provided', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp003',
          quarter: 1,
          year: 2025,
          name: 'New Year Initiatives',
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act & Assert
        expect(quarterPlan.displayName, equals('New Year Initiatives'));
      });

      test('should generate default display name when name is not provided', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp004',
          quarter: 2,
          year: 2025,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act & Assert
        expect(quarterPlan.displayName, equals('Q2 2025'));
      });

      test('should calculate correct date range for Q1', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp005',
          quarter: 1,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final (startDate, endDate) = quarterPlan.quarterDateRange;

        // Assert
        expect(startDate, equals(DateTime(2024, 1, 1)));
        expect(endDate, equals(DateTime(2024, 3, 31)));
      });

      test('should calculate correct date range for Q2', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp006',
          quarter: 2,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final (startDate, endDate) = quarterPlan.quarterDateRange;

        // Assert
        expect(startDate, equals(DateTime(2024, 4, 1)));
        expect(endDate, equals(DateTime(2024, 6, 30)));
      });

      test('should calculate correct date range for Q3', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp007',
          quarter: 3,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final (startDate, endDate) = quarterPlan.quarterDateRange;

        // Assert
        expect(startDate, equals(DateTime(2024, 7, 1)));
        expect(endDate, equals(DateTime(2024, 9, 30)));
      });

      test('should calculate correct date range for Q4', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp008',
          quarter: 4,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final (startDate, endDate) = quarterPlan.quarterDateRange;

        // Assert
        expect(startDate, equals(DateTime(2024, 10, 1)));
        expect(endDate, equals(DateTime(2024, 12, 31)));
      });
    });

    group('Capacity Calculations', () {
      test('should calculate total available capacity correctly', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp009',
          quarter: 3,
          year: 2024,
          initiatives: [],
          teamMembers: testTeamMembers,
          allocations: [],
        );

        // Act
        final totalCapacity = quarterPlan.totalAvailableCapacity;

        // Assert
        // Q3 2024 is 13 weeks (Jul 1 - Sep 30)
        // Alice: 1.0 * 13 = 13 weeks
        // Bob: 1.0 * 13 = 13 weeks  
        // Carol: 0.8 * 13 = 10.4 weeks
        // Total: 36.4 weeks
        expect(totalCapacity, closeTo(36.4, 0.1));
      });

      test('should calculate total allocated capacity correctly', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp010',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final totalAllocated = quarterPlan.totalAllocatedCapacity;

        // Assert
        // ca001: 3.0 weeks + ca002: 5.0 weeks = 8.0 weeks
        expect(totalAllocated, equals(8.0));
      });

      test('should calculate remaining capacity correctly', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp011',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final remaining = quarterPlan.remainingCapacity;

        // Assert
        // Available: ~36.4, Allocated: 8.0, Remaining: ~28.4
        expect(remaining, closeTo(28.4, 0.1));
      });

      test('should calculate capacity utilization correctly', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp012',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final utilization = quarterPlan.capacityUtilization;

        // Assert
        // 8.0 allocated / ~36.4 available * 100 = ~22%
        expect(utilization, closeTo(22.0, 2.0));
      });

      test('should identify over-allocated plans correctly', () {
        // Arrange
        final overAllocatedPlan = QuarterPlan(
          id: 'qp013',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: [
            // Massive over-allocation
            CapacityAllocation(
              id: 'ca003',
              teamMemberId: 'tm001',
              initiativeId: 'init001',
              role: Role.frontend,
              allocatedWeeks: 50.0, // Much more than available
              startDate: DateTime(2024, 7, 1),
              endDate: DateTime(2024, 9, 30),
            ),
          ],
        );

        // Act & Assert
        expect(overAllocatedPlan.isOverAllocated, isTrue);
      });

      test('should exclude cancelled allocations from capacity calculations', () {
        // Arrange
        final allocationsWithCancelled = [
          ...testAllocations,
          CapacityAllocation(
            id: 'ca004',
            teamMemberId: 'tm003',
            initiativeId: 'init001',
            role: Role.design,
            allocatedWeeks: 10.0, // Large allocation
            startDate: DateTime(2024, 7, 1),
            endDate: DateTime(2024, 9, 30),
            status: AllocationStatus.cancelled, // But cancelled
          ),
        ];

        final quarterPlan = QuarterPlan(
          id: 'qp014',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: allocationsWithCancelled,
        );

        // Act
        final totalAllocated = quarterPlan.totalAllocatedCapacity;

        // Assert
        // Should only count non-cancelled allocations (8.0 weeks)
        expect(totalAllocated, equals(8.0));
      });

      test('should exclude inactive team members from capacity calculations', () {
        // Arrange
        final membersWithInactive = [
          ...testTeamMembers,
          TeamMember(
            id: 'tm004',
            name: 'Dave Inactive',
            email: 'dave@company.com',
            roles: {Role.qa},
            weeklyCapacity: 1.0,
            skillLevel: 5,
            isActive: false, // Inactive
          ),
        ];

        final quarterPlan = QuarterPlan(
          id: 'qp015',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: membersWithInactive,
          allocations: [],
        );

        // Act
        final totalCapacity = quarterPlan.totalAvailableCapacity;

        // Assert
        // Should only count active members (same as before: ~36.4)
        expect(totalCapacity, closeTo(36.4, 0.1));
      });
    });

    group('Capacity Breakdown by Role', () {
      test('should calculate capacity breakdown by role correctly', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp016',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final breakdown = quarterPlan.capacityByRole;

        // Assert
        expect(breakdown.keys, containsAll([Role.frontend, Role.backend, Role.design]));
        
        // Frontend: Alice (13 weeks available, 3 weeks allocated)
        expect(breakdown[Role.frontend]!.available, closeTo(13.0, 0.1));
        expect(breakdown[Role.frontend]!.allocated, equals(3.0));
        
        // Backend: Bob (13 weeks available, 5 weeks allocated)
        expect(breakdown[Role.backend]!.available, closeTo(13.0, 0.1));
        expect(breakdown[Role.backend]!.allocated, equals(5.0));
        
        // Design: Carol (10.4 weeks available, 0 weeks allocated)
        expect(breakdown[Role.design]!.available, closeTo(10.4, 0.1));
        expect(breakdown[Role.design]!.allocated, equals(0.0));
      });

      test('should handle team members with multiple roles in breakdown', () {
        // Arrange
        final multiRoleMember = TeamMember(
          id: 'tm005',
          name: 'Eve Fullstack',
          email: 'eve@company.com',
          roles: {Role.frontend, Role.backend},
          weeklyCapacity: 1.0,
          skillLevel: 8,
          isActive: true,
        );

        final quarterPlan = QuarterPlan(
          id: 'qp017',
          quarter: 3,
          year: 2024,
          initiatives: [],
          teamMembers: [multiRoleMember],
          allocations: [],
        );

        // Act
        final breakdown = quarterPlan.capacityByRole;

        // Assert
        // Eve contributes 13 weeks to both frontend and backend
        expect(breakdown[Role.frontend]!.available, closeTo(13.0, 0.1));
        expect(breakdown[Role.backend]!.available, closeTo(13.0, 0.1));
      });
    });

    group('Under-allocation Detection', () {
      test('should identify under-allocated initiatives correctly', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp018',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final underAllocated = quarterPlan.underAllocatedInitiatives;

        // Assert
        // init001 needs 4.0 frontend + 2.0 design, only has 3.0 frontend allocated
        // init002 needs 6.0 backend + 2.0 devops, only has 5.0 backend allocated
        expect(underAllocated, hasLength(2));
        expect(underAllocated.map((i) => i.id), containsAll(['init001', 'init002']));
      });

      test('should not identify fully allocated initiatives as under-allocated', () {
        // Arrange
        final fullyAllocatedPlan = QuarterPlan(
          id: 'qp019',
          quarter: 3,
          year: 2024,
          initiatives: [testInitiatives.first], // Just one initiative
          teamMembers: testTeamMembers,
          allocations: [
            CapacityAllocation(
              id: 'ca005',
              teamMemberId: 'tm001',
              initiativeId: 'init001',
              role: Role.frontend,
              allocatedWeeks: 4.0, // Exactly what's needed
              startDate: DateTime(2024, 7, 1),
              endDate: DateTime(2024, 7, 28),
            ),
            CapacityAllocation(
              id: 'ca006',
              teamMemberId: 'tm003',
              initiativeId: 'init001',
              role: Role.design,
              allocatedWeeks: 2.0, // Exactly what's needed
              startDate: DateTime(2024, 7, 1),
              endDate: DateTime(2024, 7, 14),
            ),
          ],
        );

        // Act
        final underAllocated = fullyAllocatedPlan.underAllocatedInitiatives;

        // Assert
        expect(underAllocated, isEmpty);
      });
    });

    group('Over-allocation Detection', () {
      test('should identify over-allocated members correctly', () {
        // Arrange
        final overAllocationPlan = QuarterPlan(
          id: 'qp020',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: [
            CapacityAllocation(
              id: 'ca007',
              teamMemberId: 'tm001', // Alice has ~13 weeks available
              initiativeId: 'init001',
              role: Role.frontend,
              allocatedWeeks: 15.0, // Over-allocated
              startDate: DateTime(2024, 7, 1),
              endDate: DateTime(2024, 9, 30),
            ),
          ],
        );

        // Act
        final overAllocatedMembers = overAllocationPlan.overAllocatedMembers;

        // Assert
        expect(overAllocatedMembers, contains('tm001'));
      });

      test('should not identify properly allocated members as over-allocated', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp021',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations, // Normal allocations within capacity
        );

        // Act
        final overAllocatedMembers = quarterPlan.overAllocatedMembers;

        // Assert
        expect(overAllocatedMembers, isEmpty);
      });

      test('should exclude cancelled allocations from over-allocation detection', () {
        // Arrange
        final allocationPlan = QuarterPlan(
          id: 'qp022',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: [
            CapacityAllocation(
              id: 'ca008',
              teamMemberId: 'tm001',
              initiativeId: 'init001',
              role: Role.frontend,
              allocatedWeeks: 5.0, // Normal allocation
              startDate: DateTime(2024, 7, 1),
              endDate: DateTime(2024, 7, 28),
            ),
            CapacityAllocation(
              id: 'ca009',
              teamMemberId: 'tm001',
              initiativeId: 'init002',
              role: Role.frontend,
              allocatedWeeks: 20.0, // Would cause over-allocation
              startDate: DateTime(2024, 8, 1),
              endDate: DateTime(2024, 9, 30),
              status: AllocationStatus.cancelled, // But cancelled
            ),
          ],
        );

        // Act
        final overAllocatedMembers = allocationPlan.overAllocatedMembers;

        // Assert
        expect(overAllocatedMembers, isEmpty);
      });
    });

    group('Allocation Queries', () {
      test('should find all allocations for a specific member', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp023',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final aliceAllocations = quarterPlan.getAllocationsForMember('tm001');
        final bobAllocations = quarterPlan.getAllocationsForMember('tm002');

        // Assert
        expect(aliceAllocations, hasLength(1));
        expect(aliceAllocations.first.id, equals('ca001'));
        expect(bobAllocations, hasLength(1));
        expect(bobAllocations.first.id, equals('ca002'));
      });

      test('should find all allocations for a specific initiative', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp024',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final init001Allocations = quarterPlan.getAllocationsForInitiative('init001');
        final init002Allocations = quarterPlan.getAllocationsForInitiative('init002');

        // Assert
        expect(init001Allocations, hasLength(1));
        expect(init001Allocations.first.id, equals('ca001'));
        expect(init002Allocations, hasLength(1));
        expect(init002Allocations.first.id, equals('ca002'));
      });

      test('should exclude cancelled allocations from member and initiative queries', () {
        // Arrange
        final allocationsWithCancelled = [
          ...testAllocations,
          CapacityAllocation(
            id: 'ca010',
            teamMemberId: 'tm001',
            initiativeId: 'init001',
            role: Role.frontend,
            allocatedWeeks: 2.0,
            startDate: DateTime(2024, 8, 1),
            endDate: DateTime(2024, 8, 14),
            status: AllocationStatus.cancelled,
          ),
        ];

        final quarterPlan = QuarterPlan(
          id: 'qp025',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: allocationsWithCancelled,
        );

        // Act
        final aliceAllocations = quarterPlan.getAllocationsForMember('tm001');
        final init001Allocations = quarterPlan.getAllocationsForInitiative('init001');

        // Assert
        // Should not include cancelled allocation
        expect(aliceAllocations, hasLength(1));
        expect(aliceAllocations.first.id, equals('ca001'));
        expect(init001Allocations, hasLength(1));
        expect(init001Allocations.first.id, equals('ca001'));
      });
    });

    group('Plan Summary', () {
      test('should generate correct summary statistics', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp026',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final summary = quarterPlan.summary;

        // Assert
        expect(summary.totalInitiatives, equals(2));
        expect(summary.completedInitiatives, equals(0)); // None completed
        expect(summary.totalTeamMembers, equals(3)); // All active
        expect(summary.totalAllocations, equals(2)); // Both non-cancelled
        expect(summary.capacityUtilization, closeTo(22.0, 2.0));
        expect(summary.isOverAllocated, isFalse);
        expect(summary.underAllocatedInitiatives, equals(2)); // Both under-allocated
        expect(summary.overAllocatedMembers, equals(0));
        expect(summary.completionPercentage, equals(0.0));
        expect(summary.hasIssues, isTrue); // Has under-allocated initiatives
      });

      test('should calculate completion percentage correctly', () {
        // Arrange
        final completedAllocation = CapacityAllocation(
          id: 'ca011',
          teamMemberId: 'tm001',
          initiativeId: 'init001',
          role: Role.frontend,
          allocatedWeeks: 3.0,
          startDate: DateTime(2024, 7, 1),
          endDate: DateTime(2024, 7, 21),
          status: AllocationStatus.completed,
        );

        final quarterPlan = QuarterPlan(
          id: 'qp027',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: [completedAllocation],
        );

        // Act
        final summary = quarterPlan.summary;

        // Assert
        expect(summary.completedInitiatives, equals(1));
        expect(summary.completionPercentage, equals(50.0)); // 1 out of 2 initiatives
      });
    });

    group('Validation', () {
      test('should validate correct QuarterPlan successfully', () {
        // Arrange
        final validQuarterPlan = QuarterPlan(
          id: 'qp028',
          quarter: 2,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final result = validQuarterPlan.validate();

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should fail validation for empty ID', () {
        // Arrange
        final invalidQuarterPlan = QuarterPlan(
          id: '',
          quarter: 1,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final result = invalidQuarterPlan.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Quarter plan ID cannot be empty'));
      });

      test('should fail validation for invalid quarter', () {
        // Arrange
        final invalidQuarter1 = QuarterPlan(
          id: 'qp029',
          quarter: 0,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        final invalidQuarter2 = QuarterPlan(
          id: 'qp030',
          quarter: 5,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final result1 = invalidQuarter1.validate();
        final result2 = invalidQuarter2.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), contains('Quarter must be between 1 and 4'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), contains('Quarter must be between 1 and 4'));
      });

      test('should fail validation for invalid year', () {
        // Arrange
        final invalidYear1 = QuarterPlan(
          id: 'qp031',
          quarter: 1,
          year: 2010, // Too early
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        final invalidYear2 = QuarterPlan(
          id: 'qp032',
          quarter: 1,
          year: 2060, // Too late
          initiatives: [],
          teamMembers: [],
          allocations: [],
        );

        // Act
        final result1 = invalidYear1.validate();
        final result2 = invalidYear2.validate();

        // Assert
        expect(result1.isError, isTrue);
        expect(result1.error.allErrors.join(' '), contains('Year must be between 2020 and 2050'));
        expect(result2.isError, isTrue);
        expect(result2.error.allErrors.join(' '), contains('Year must be between 2020 and 2050'));
      });

      test('should fail validation for duplicate initiative IDs', () {
        // Arrange
        final duplicateInitiatives = [
          testInitiatives.first,
          testInitiatives.first, // Duplicate
        ];

        final quarterPlan = QuarterPlan(
          id: 'qp033',
          quarter: 1,
          year: 2024,
          initiatives: duplicateInitiatives,
          teamMembers: [],
          allocations: [],
        );

        // Act
        final result = quarterPlan.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Duplicate initiative IDs'));
      });

      test('should fail validation for duplicate team member IDs', () {
        // Arrange
        final duplicateMembers = [
          testTeamMembers.first,
          testTeamMembers.first, // Duplicate
        ];

        final quarterPlan = QuarterPlan(
          id: 'qp034',
          quarter: 1,
          year: 2024,
          initiatives: [],
          teamMembers: duplicateMembers,
          allocations: [],
        );

        // Act
        final result = quarterPlan.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Duplicate team member IDs'));
      });

      test('should fail validation for duplicate allocation IDs', () {
        // Arrange
        final duplicateAllocations = [
          testAllocations.first,
          testAllocations.first, // Duplicate
        ];

        final quarterPlan = QuarterPlan(
          id: 'qp035',
          quarter: 1,
          year: 2024,
          initiatives: [],
          teamMembers: [],
          allocations: duplicateAllocations,
        );

        // Act
        final result = quarterPlan.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Duplicate allocation IDs'));
      });

      test('should fail validation for referential integrity violations', () {
        // Arrange
        final invalidAllocation = CapacityAllocation(
          id: 'ca012',
          teamMemberId: 'tm999', // Non-existent member
          initiativeId: 'init999', // Non-existent initiative
          role: Role.frontend,
          allocatedWeeks: 2.0,
          startDate: DateTime(2024, 7, 1),
          endDate: DateTime(2024, 7, 14),
        );

        final quarterPlan = QuarterPlan(
          id: 'qp036',
          quarter: 1,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: [invalidAllocation],
        );

        // Act
        final result = quarterPlan.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('references unknown team member'));
        expect(result.error.allErrors.join(' '), contains('references unknown initiative'));
      });

      test('should fail validation for extreme over-allocation', () {
        // Arrange
        final extremeAllocations = List.generate(10, (index) => 
          CapacityAllocation(
            id: 'ca_extreme_$index',
            teamMemberId: 'tm001',
            initiativeId: 'init001',
            role: Role.frontend,
            allocatedWeeks: 20.0, // Extreme allocation
            startDate: DateTime(2024, 7, 1),
            endDate: DateTime(2024, 9, 30),
          ),
        );

        final quarterPlan = QuarterPlan(
          id: 'qp037',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: extremeAllocations,
        );

        // Act
        final result = quarterPlan.validate();

        // Assert
        expect(result.isError, isTrue);
        expect(result.error.allErrors.join(' '), contains('Extreme over-allocation detected'));
      });
    });

    group('Serialization', () {
      test('should serialize to Map correctly', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp038',
          quarter: 4,
          year: 2024,
          name: 'Year-end Sprint',
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
          notes: 'Focus on deliverables',
          isLocked: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = quarterPlan.toMap();

        // Assert
        expect(map['id'], equals('qp038'));
        expect(map['quarter'], equals(4));
        expect(map['year'], equals(2024));
        expect(map['name'], equals('Year-end Sprint'));
        expect(map['initiatives'], isA<List>());
        expect(map['initiatives'], hasLength(2));
        expect(map['teamMembers'], isA<List>());
        expect(map['teamMembers'], hasLength(3));
        expect(map['allocations'], isA<List>());
        expect(map['allocations'], hasLength(2));
        expect(map['notes'], equals('Focus on deliverables'));
        expect(map['isLocked'], isTrue);
        expect(map['createdAt'], equals(testCreatedAt.toIso8601String()));
        expect(map['updatedAt'], equals(testUpdatedAt.toIso8601String()));
      });

      test('should deserialize from Map correctly', () {
        // Arrange
        final map = {
          'id': 'qp039',
          'quarter': 1,
          'year': 2025,
          'name': 'New Year Plan',
          'initiatives': testInitiatives.map((i) => i.toMap()).toList(),
          'teamMembers': testTeamMembers.map((m) => m.toMap()).toList(),
          'allocations': testAllocations.map((a) => a.toMap()).toList(),
          'notes': 'Fresh start',
          'isLocked': false,
          'createdAt': testCreatedAt.toIso8601String(),
          'updatedAt': testUpdatedAt.toIso8601String(),
        };

        // Act
        final quarterPlan = QuarterPlan.fromMap(map);

        // Assert
        expect(quarterPlan.id, equals('qp039'));
        expect(quarterPlan.quarter, equals(1));
        expect(quarterPlan.year, equals(2025));
        expect(quarterPlan.name, equals('New Year Plan'));
        expect(quarterPlan.initiatives, hasLength(2));
        expect(quarterPlan.teamMembers, hasLength(3));
        expect(quarterPlan.allocations, hasLength(2));
        expect(quarterPlan.notes, equals('Fresh start'));
        expect(quarterPlan.isLocked, isFalse);
        expect(quarterPlan.createdAt, equals(testCreatedAt));
        expect(quarterPlan.updatedAt, equals(testUpdatedAt));
      });

      test('should handle serialization round-trip correctly', () {
        // Arrange
        final originalQuarterPlan = QuarterPlan(
          id: 'qp040',
          quarter: 2,
          year: 2024,
          name: 'Mid-year Review',
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
          notes: 'Performance review period',
          isLocked: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        // Act
        final map = originalQuarterPlan.toMap();
        final deserializedQuarterPlan = QuarterPlan.fromMap(map);

        // Assert
        expect(deserializedQuarterPlan, equals(originalQuarterPlan));
      });

      test('should handle deserialization with missing optional fields', () {
        // Arrange
        final minimalMap = {
          'id': 'qp041',
          'quarter': 3,
          'year': 2024,
          'initiatives': <Map<String, dynamic>>[],
          'teamMembers': <Map<String, dynamic>>[],
          'allocations': <Map<String, dynamic>>[],
        };

        // Act
        final quarterPlan = QuarterPlan.fromMap(minimalMap);

        // Assert
        expect(quarterPlan.id, equals('qp041'));
        expect(quarterPlan.quarter, equals(3));
        expect(quarterPlan.year, equals(2024));
        expect(quarterPlan.name, isNull);
        expect(quarterPlan.notes, equals(''));
        expect(quarterPlan.isLocked, isFalse);
        expect(quarterPlan.createdAt, isNull);
        expect(quarterPlan.updatedAt, isNull);
      });
    });

    group('Copy and Mutation', () {
      test('should create copy with updated fields', () {
        // Arrange
        final originalQuarterPlan = QuarterPlan(
          id: 'qp042',
          quarter: 1,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
          isLocked: false,
        );

        // Act
        final updatedQuarterPlan = originalQuarterPlan.copyWith(
          name: 'Updated Plan Name',
          isLocked: true,
          notes: 'Plan finalized',
        );

        // Assert
        expect(updatedQuarterPlan.id, equals(originalQuarterPlan.id));
        expect(updatedQuarterPlan.quarter, equals(originalQuarterPlan.quarter));
        expect(updatedQuarterPlan.year, equals(originalQuarterPlan.year));
        expect(updatedQuarterPlan.initiatives, equals(originalQuarterPlan.initiatives));
        expect(updatedQuarterPlan.teamMembers, equals(originalQuarterPlan.teamMembers));
        expect(updatedQuarterPlan.allocations, equals(originalQuarterPlan.allocations));
        expect(updatedQuarterPlan.name, equals('Updated Plan Name'));
        expect(updatedQuarterPlan.isLocked, isTrue);
        expect(updatedQuarterPlan.notes, equals('Plan finalized'));
      });

      test('should preserve original when no fields updated in copy', () {
        // Arrange
        final originalQuarterPlan = QuarterPlan(
          id: 'qp043',
          quarter: 2,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final copiedQuarterPlan = originalQuarterPlan.copyWith();

        // Assert
        expect(copiedQuarterPlan, equals(originalQuarterPlan));
        expect(identical(copiedQuarterPlan, originalQuarterPlan), isFalse);
      });
    });

    group('Equality and String Representation', () {
      test('should implement equality correctly', () {
        // Arrange
        final quarterPlan1 = QuarterPlan(
          id: 'qp044',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        final quarterPlan2 = QuarterPlan(
          id: 'qp044',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        final quarterPlan3 = QuarterPlan(
          id: 'qp045',
          quarter: 3,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act & Assert
        expect(quarterPlan1, equals(quarterPlan2));
        expect(quarterPlan1, isNot(equals(quarterPlan3)));
        expect(quarterPlan1.hashCode, equals(quarterPlan2.hashCode));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        final quarterPlan = QuarterPlan(
          id: 'qp046',
          quarter: 4,
          year: 2024,
          initiatives: testInitiatives,
          teamMembers: testTeamMembers,
          allocations: testAllocations,
        );

        // Act
        final stringRep = quarterPlan.toString();

        // Assert
        expect(stringRep, contains('qp046'));
        expect(stringRep, contains('Q4 2024'));
        expect(stringRep, contains('initiatives: 2'));
        expect(stringRep, contains('members: 3'));
        expect(stringRep, contains('allocations: 2'));
        expect(stringRep, contains('utilization:'));
      });
    });
  });

  group('CapacityBreakdown Tests', () {
    group('Construction and Properties', () {
      test('should create CapacityBreakdown with values', () {
        // Arrange & Act
        final breakdown = CapacityBreakdown(
          available: 10.0,
          allocated: 7.0,
        );

        // Assert
        expect(breakdown.available, equals(10.0));
        expect(breakdown.allocated, equals(7.0));
        expect(breakdown.remaining, equals(3.0));
        expect(breakdown.utilization, equals(70.0));
        expect(breakdown.isOverAllocated, isFalse);
      });

      test('should create empty CapacityBreakdown', () {
        // Arrange & Act
        final breakdown = CapacityBreakdown.empty();

        // Assert
        expect(breakdown.available, equals(0.0));
        expect(breakdown.allocated, equals(0.0));
        expect(breakdown.remaining, equals(0.0));
        expect(breakdown.utilization, equals(0.0));
        expect(breakdown.isOverAllocated, isFalse);
      });

      test('should identify over-allocated breakdown', () {
        // Arrange & Act
        final breakdown = CapacityBreakdown(
          available: 5.0,
          allocated: 7.0,
        );

        // Assert
        expect(breakdown.isOverAllocated, isTrue);
        expect(breakdown.remaining, equals(-2.0));
        expect(breakdown.utilization, equals(140.0));
      });

      test('should handle zero available capacity', () {
        // Arrange & Act
        final breakdown = CapacityBreakdown(
          available: 0.0,
          allocated: 5.0,
        );

        // Assert
        expect(breakdown.utilization, equals(0.0)); // Prevents division by zero
        expect(breakdown.isOverAllocated, isTrue);
      });
    });

    group('Copy and String Representation', () {
      test('should create copy with updated values', () {
        // Arrange
        final original = CapacityBreakdown(
          available: 8.0,
          allocated: 5.0,
        );

        // Act
        final updated = original.copyWith(allocated: 6.0);

        // Assert
        expect(updated.available, equals(8.0));
        expect(updated.allocated, equals(6.0));
        expect(updated.utilization, equals(75.0));
      });

      test('should provide meaningful string representation', () {
        // Arrange
        final breakdown = CapacityBreakdown(
          available: 12.5,
          allocated: 8.3,
        );

        // Act
        final stringRep = breakdown.toString();

        // Assert
        expect(stringRep, contains('12.5'));
        expect(stringRep, contains('8.3'));
        expect(stringRep, contains('66.4%'));
      });
    });
  });

  group('QuarterPlanSummary Tests', () {
    group('Construction and Calculations', () {
      test('should create QuarterPlanSummary with all properties', () {
        // Arrange & Act
        final summary = QuarterPlanSummary(
          totalInitiatives: 5,
          completedInitiatives: 2,
          totalTeamMembers: 8,
          totalAllocations: 12,
          capacityUtilization: 85.5,
          isOverAllocated: false,
          underAllocatedInitiatives: 1,
          overAllocatedMembers: 0,
        );

        // Assert
        expect(summary.totalInitiatives, equals(5));
        expect(summary.completedInitiatives, equals(2));
        expect(summary.totalTeamMembers, equals(8));
        expect(summary.totalAllocations, equals(12));
        expect(summary.capacityUtilization, equals(85.5));
        expect(summary.isOverAllocated, isFalse);
        expect(summary.underAllocatedInitiatives, equals(1));
        expect(summary.overAllocatedMembers, equals(0));
        expect(summary.completionPercentage, equals(40.0)); // 2/5 * 100
        expect(summary.hasIssues, isTrue); // Has under-allocated initiatives
      });

      test('should handle zero initiatives for completion percentage', () {
        // Arrange & Act
        final summary = QuarterPlanSummary(
          totalInitiatives: 0,
          completedInitiatives: 0,
          totalTeamMembers: 5,
          totalAllocations: 0,
          capacityUtilization: 0.0,
          isOverAllocated: false,
          underAllocatedInitiatives: 0,
          overAllocatedMembers: 0,
        );

        // Assert
        expect(summary.completionPercentage, equals(0.0));
        expect(summary.hasIssues, isFalse);
      });

      test('should identify plans with issues correctly', () {
        // Arrange
        final summaryWithOverAllocation = QuarterPlanSummary(
          totalInitiatives: 3,
          completedInitiatives: 1,
          totalTeamMembers: 5,
          totalAllocations: 8,
          capacityUtilization: 120.0,
          isOverAllocated: true,
          underAllocatedInitiatives: 0,
          overAllocatedMembers: 0,
        );

        final summaryWithUnderAllocation = QuarterPlanSummary(
          totalInitiatives: 4,
          completedInitiatives: 1,
          totalTeamMembers: 6,
          totalAllocations: 10,
          capacityUtilization: 80.0,
          isOverAllocated: false,
          underAllocatedInitiatives: 2,
          overAllocatedMembers: 0,
        );

        final summaryWithOverAllocatedMembers = QuarterPlanSummary(
          totalInitiatives: 3,
          completedInitiatives: 1,
          totalTeamMembers: 4,
          totalAllocations: 7,
          capacityUtilization: 95.0,
          isOverAllocated: false,
          underAllocatedInitiatives: 0,
          overAllocatedMembers: 1,
        );

        final summaryWithoutIssues = QuarterPlanSummary(
          totalInitiatives: 2,
          completedInitiatives: 1,
          totalTeamMembers: 5,
          totalAllocations: 6,
          capacityUtilization: 85.0,
          isOverAllocated: false,
          underAllocatedInitiatives: 0,
          overAllocatedMembers: 0,
        );

        // Act & Assert
        expect(summaryWithOverAllocation.hasIssues, isTrue);
        expect(summaryWithUnderAllocation.hasIssues, isTrue);
        expect(summaryWithOverAllocatedMembers.hasIssues, isTrue);
        expect(summaryWithoutIssues.hasIssues, isFalse);
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        // Arrange
        final summary = QuarterPlanSummary(
          totalInitiatives: 6,
          completedInitiatives: 3,
          totalTeamMembers: 10,
          totalAllocations: 15,
          capacityUtilization: 92.3,
          isOverAllocated: false,
          underAllocatedInitiatives: 1,
          overAllocatedMembers: 0,
        );

        // Act
        final stringRep = summary.toString();

        // Assert
        expect(stringRep, contains('initiatives: 6'));
        expect(stringRep, contains('completion: 50.0%'));
        expect(stringRep, contains('utilization: 92.3%'));
        expect(stringRep, contains('issues: true'));
      });
    });
  });
}
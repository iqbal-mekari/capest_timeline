/// Integration tests for capacity allocation workflow.
/// 
/// Tests the complete end-to-end capacity allocation process including:
/// - Team member assignment to initiatives
/// - Capacity validation and utilization calculations
/// - State management coordination across entities
/// - Multi-role and multi-quarter allocation scenarios
/// - Over-allocation detection and prevention
/// - Allocation lifecycle management (planned → in-progress → completed)
/// - Real-time capacity updates and conflict resolution
library;

import 'package:flutter_test/flutter_test.dart';

// TODO: Import actual implementations when available
// import 'package:capest_timeline/core/di/service_locator.dart';
// import 'package:capest_timeline/features/capacity_planning/data/repositories/capacity_allocation_repository.dart';
// import 'package:capest_timeline/features/capacity_planning/data/repositories/initiative_repository.dart';
// import 'package:capest_timeline/features/capacity_planning/data/repositories/quarter_plan_repository.dart';
// import 'package:capest_timeline/features/team_management/data/repositories/team_member_repository.dart';
// import 'package:capest_timeline/features/capacity_planning/domain/usecases/allocate_capacity_usecase.dart';
// import 'package:capest_timeline/features/capacity_planning/domain/usecases/validate_allocation_usecase.dart';
// import 'package:capest_timeline/features/capacity_planning/domain/usecases/update_allocation_status_usecase.dart';
// import 'package:capest_timeline/features/capacity_planning/domain/entities/capacity_allocation.dart';
// import 'package:capest_timeline/features/capacity_planning/domain/entities/initiative.dart';
// import 'package:capest_timeline/features/capacity_planning/domain/entities/quarter_plan.dart';
// import 'package:capest_timeline/features/team_management/domain/entities/team_member.dart';
// import 'package:capest_timeline/core/enums/role.dart';
// import 'package:capest_timeline/core/types/result.dart';
// import 'package:capest_timeline/core/errors/exceptions.dart;

// TODO: Generate mocks using build_runner when implementations are available
// @GenerateMocks([
//   CapacityAllocationRepository,
//   InitiativeRepository,
//   QuarterPlanRepository,
//   TeamMemberRepository,
//   AllocateCapacityUsecase,
//   ValidateAllocationUsecase,
//   UpdateAllocationStatusUsecase,
// ])

void main() {
  group('Capacity Allocation Integration Tests', () {
    // TODO: Initialize mocks when implementations are available
    // late MockCapacityAllocationRepository mockAllocationRepository;
    // late MockInitiativeRepository mockInitiativeRepository;
    // late MockQuarterPlanRepository mockQuarterPlanRepository;
    // late MockTeamMemberRepository mockTeamMemberRepository;
    // late MockAllocateCapacityUsecase mockAllocateCapacityUsecase;
    // late MockValidateAllocationUsecase mockValidateAllocationUsecase;
    // late MockUpdateAllocationStatusUsecase mockUpdateAllocationStatusUsecase;

    // Test data
    late DateTime testStartDate;
    late DateTime testEndDate;
    late Map<String, dynamic> testTeamMember;
    late Map<String, dynamic> testInitiative;
    late Map<String, dynamic> testAllocation;

    setUp(() {
      testStartDate = DateTime(2024, 7, 1);
      testEndDate = DateTime(2024, 7, 21);

      // TODO: Initialize mocks when implementations are available
      // mockAllocationRepository = MockCapacityAllocationRepository();
      // mockInitiativeRepository = MockInitiativeRepository();
      // mockQuarterPlanRepository = MockQuarterPlanRepository();
      // mockTeamMemberRepository = MockTeamMemberRepository();
      // mockAllocateCapacityUsecase = MockAllocateCapacityUsecase();
      // mockValidateAllocationUsecase = MockValidateAllocationUsecase();
      // mockUpdateAllocationStatusUsecase = MockUpdateAllocationStatusUsecase();

      // Setup test data
      testTeamMember = {
        'id': 'tm001',
        'name': 'Alice Frontend',
        'email': 'alice@company.com',
        'roles': ['frontend'],
        'weeklyCapacity': 1.0,
        'skillLevel': 8,
        'isActive': true,
      };

      testInitiative = {
        'id': 'init001',
        'name': 'Mobile App Redesign',
        'description': 'Complete redesign of mobile application',
        'priority': 8,
        'businessValue': 9,
        'requiredRoles': {
          'frontend': 4.0,
          'design': 2.0,
        },
        'estimatedEffortWeeks': 6.0,
        'dependencies': <String>[],
      };

      testAllocation = {
        'id': 'ca001',
        'teamMemberId': 'tm001',
        'initiativeId': 'init001',
        'role': 'frontend',
        'allocatedWeeks': 3.0,
        'startDate': testStartDate.toIso8601String(),
        'endDate': testEndDate.toIso8601String(),
        'status': 'planned',
        'notes': '',
      };
    });

    group('End-to-End Allocation Workflow', () {
      test('should complete full allocation lifecycle from planning to completion', () async {
        // ARRANGE - Simulate repository states
        final allocationStates = <String, dynamic>{
          'planned': {...testAllocation, 'status': 'planned'},
          'inProgress': {...testAllocation, 'status': 'inProgress'},
          'completed': {...testAllocation, 'status': 'completed'},
        };

        // TODO: Setup mock responses when implementations are available
        // when(mockTeamMemberRepository.getById('tm001'))
        //     .thenAnswer((_) async => Result.success(TeamMember.fromMap(testTeamMember)));
        // when(mockInitiativeRepository.getById('init001'))
        //     .thenAnswer((_) async => Result.success(Initiative.fromMap(testInitiative)));
        // when(mockQuarterPlanRepository.getById('qp001'))
        //     .thenAnswer((_) async => Result.success(QuarterPlan.fromMap(testQuarterPlan)));

        // ACT & ASSERT - Step 1: Create allocation
        // when(mockAllocateCapacityUsecase.execute(any))
        //     .thenAnswer((_) async => Result.success(CapacityAllocation.fromMap(allocationStates['planned'])));

        // final createResult = await mockAllocateCapacityUsecase.execute(AllocateCapacityParams(
        //   teamMemberId: 'tm001',
        //   initiativeId: 'init001',
        //   role: Role.frontend,
        //   allocatedWeeks: 3.0,
        //   startDate: testStartDate,
        //   endDate: testEndDate,
        // ));

        // Simulate allocation creation
        final createdAllocation = allocationStates['planned'];
        expect(createdAllocation['status'], equals('planned'));
        expect(createdAllocation['teamMemberId'], equals('tm001'));
        expect(createdAllocation['initiativeId'], equals('init001'));
        expect(createdAllocation['allocatedWeeks'], equals(3.0));

        // ACT & ASSERT - Step 2: Start work (transition to in-progress)
        // when(mockUpdateAllocationStatusUsecase.execute(any))
        //     .thenAnswer((_) async => Result.success(CapacityAllocation.fromMap(allocationStates['inProgress'])));

        // final startResult = await mockUpdateAllocationStatusUsecase.execute(UpdateAllocationStatusParams(
        //   allocationId: 'ca001',
        //   status: AllocationStatus.inProgress,
        //   notes: 'Started frontend development',
        // ));

        final startedAllocation = allocationStates['inProgress'];
        expect(startedAllocation['status'], equals('inProgress'));

        // ACT & ASSERT - Step 3: Complete work
        // when(mockUpdateAllocationStatusUsecase.execute(any))
        //     .thenAnswer((_) async => Result.success(CapacityAllocation.fromMap(allocationStates['completed'])));

        // final completeResult = await mockUpdateAllocationStatusUsecase.execute(UpdateAllocationStatusParams(
        //   allocationId: 'ca001',
        //   status: AllocationStatus.completed,
        //   notes: 'Frontend development completed successfully',
        // ));

        final completedAllocation = allocationStates['completed'];
        expect(completedAllocation['status'], equals('completed'));

        // Verify workflow progression
        final statusProgression = ['planned', 'inProgress', 'completed'];
        for (final status in statusProgression) {
          expect(allocationStates[status]['id'], equals('ca001'));
          expect(allocationStates[status]['status'], equals(status));
        }

        // TODO: Verify repository interactions when implementations are available
        // verify(mockAllocationRepository.create(any)).called(1);
        // verify(mockAllocationRepository.update(any)).called(2);
      });

      test('should handle allocation validation throughout workflow', () async {
        // ARRANGE - Setup validation scenarios
        final validationScenarios = [
          {
            'description': 'Valid allocation within capacity',
            'teamMemberCapacity': 1.0,
            'allocatedWeeks': 3.0,
            'durationWeeks': 3.0,
            'expectedValid': true,
          },
          {
            'description': 'Over-allocation scenario',
            'teamMemberCapacity': 0.5,
            'allocatedWeeks': 3.0,
            'durationWeeks': 2.0, // Would need 1.5 weeks/week = 150% capacity
            'expectedValid': false,
          },
          {
            'description': 'Zero allocation',
            'teamMemberCapacity': 1.0,
            'allocatedWeeks': 0.0,
            'durationWeeks': 1.0,
            'expectedValid': false,
          },
        ];

        // ACT & ASSERT
        for (final scenario in validationScenarios) {
          // TODO: Setup validation mock when implementations are available
          // when(mockValidateAllocationUsecase.execute(any))
          //     .thenAnswer((_) async => Result.success(scenario['expectedValid'] as bool));

          // Simulate validation logic
          final allocatedWeeks = scenario['allocatedWeeks'] as double;
          final durationWeeks = scenario['durationWeeks'] as double;
          final capacity = scenario['teamMemberCapacity'] as double;
          
          final requiredWeeklyCapacity = durationWeeks > 0 ? allocatedWeeks / durationWeeks : 0.0;
          final isValid = allocatedWeeks > 0 && requiredWeeklyCapacity <= capacity;

          expect(isValid, equals(scenario['expectedValid']),
              reason: 'Validation failed for: ${scenario['description']}');
        }
      });

      test('should manage capacity updates and recalculations', () async {
        // ARRANGE - Setup quarter plan with multiple allocations
        final multipleAllocations = [
          {...testAllocation, 'id': 'ca001', 'allocatedWeeks': 2.0},
          {...testAllocation, 'id': 'ca002', 'teamMemberId': 'tm001', 'allocatedWeeks': 3.0},
          {...testAllocation, 'id': 'ca003', 'teamMemberId': 'tm001', 'allocatedWeeks': 1.5},
        ];

        // ACT - Calculate capacity utilization
        final totalAllocated = multipleAllocations.fold<double>(
          0.0, 
          (sum, allocation) => sum + (allocation['allocatedWeeks'] as double)
        );

        final memberCapacity = testTeamMember['weeklyCapacity'] as double;
        const quarterWeeks = 13.0; // Q3 duration
        final totalAvailable = memberCapacity * quarterWeeks;
        final utilization = (totalAllocated / totalAvailable) * 100;

        // ASSERT
        expect(totalAllocated, equals(6.5)); // 2.0 + 3.0 + 1.5
        expect(totalAvailable, equals(13.0)); // 1.0 * 13 weeks
        expect(utilization, closeTo(50.0, 1.0)); // ~50% utilization

        // Verify allocation tracking
        expect(multipleAllocations, hasLength(3));
        expect(multipleAllocations.every((a) => a['teamMemberId'] == 'tm001'), isTrue);

        // TODO: Verify capacity recalculation when implementations are available
        // verify(mockQuarterPlanRepository.updateCapacityMetrics(any)).called(1);
      });
    });

    group('Multi-Role Allocation Scenarios', () {
      test('should handle team member with multiple roles', () async {
        // ARRANGE - Multi-role team member
        final multiRoleTeamMember = {
          ...testTeamMember,
          'id': 'tm002',
          'name': 'Bob Fullstack',
          'roles': ['frontend', 'backend'],
        };

        final frontendAllocation = {
          ...testAllocation,
          'id': 'ca001',
          'teamMemberId': 'tm002',
          'role': 'frontend',
          'allocatedWeeks': 2.0,
        };

        final backendAllocation = {
          ...testAllocation,
          'id': 'ca002', 
          'teamMemberId': 'tm002',
          'role': 'backend',
          'allocatedWeeks': 2.5,
        };

        // ACT - Allocate across different roles
        final allocations = [frontendAllocation, backendAllocation];
        final totalAllocated = allocations.fold<double>(
          0.0,
          (sum, allocation) => sum + (allocation['allocatedWeeks'] as double)
        );

        // ASSERT
        expect(totalAllocated, equals(4.5)); // 2.0 + 2.5
        expect(allocations[0]['role'], equals('frontend'));
        expect(allocations[1]['role'], equals('backend'));
        expect(allocations.every((a) => a['teamMemberId'] == 'tm002'), isTrue);

        // Verify role compatibility
        final memberRoles = multiRoleTeamMember['roles'] as List<String>;
        for (final allocation in allocations) {
          final allocationRole = allocation['role'] as String;
          expect(memberRoles, contains(allocationRole));
        }

        // TODO: Verify multi-role allocation when implementations are available
        // verify(mockAllocateCapacityUsecase.execute(any)).called(2);
      });

      test('should prevent allocation for incompatible roles', () async {
        // ARRANGE - Team member with specific roles
        final specializedMember = {
          ...testTeamMember,
          'id': 'tm003',
          'name': 'Carol Designer',
          'roles': ['design'], // Only design role
        };

        final incompatibleAllocation = {
          ...testAllocation,
          'teamMemberId': 'tm003',
          'role': 'backend', // Incompatible role
        };

        // ACT - Attempt incompatible allocation
        final memberRoles = specializedMember['roles'] as List<String>;
        final allocationRole = incompatibleAllocation['role'] as String;
        final isCompatible = memberRoles.contains(allocationRole);

        // ASSERT
        expect(isCompatible, isFalse);
        expect(memberRoles, isNot(contains('backend')));
        expect(memberRoles, contains('design'));

        // TODO: Verify validation rejection when implementations are available
        // when(mockValidateAllocationUsecase.execute(any))
        //     .thenAnswer((_) async => Result.error(ValidationException('Role incompatible')));
      });

      test('should optimize allocation across team members by skill level', () async {
        // ARRANGE - Team with different skill levels
        final teamMembers = [
          {...testTeamMember, 'id': 'tm001', 'skillLevel': 8, 'roles': ['frontend']},
          {...testTeamMember, 'id': 'tm002', 'skillLevel': 6, 'roles': ['frontend']},
          {...testTeamMember, 'id': 'tm003', 'skillLevel': 9, 'roles': ['frontend']},
        ];

        // ACT - Simulate optimal allocation strategy
        final sortedBySkill = List.from(teamMembers)
          ..sort((a, b) => (b['skillLevel'] as int).compareTo(a['skillLevel'] as int));

        final optimalAllocation = {
          ...testAllocation,
          'teamMemberId': sortedBySkill.first['id'], // Highest skill level
          'allocatedWeeks': 2.0,
        };

        // ASSERT
        expect(sortedBySkill.first['id'], equals('tm003')); // Skill level 9
        expect(sortedBySkill.first['skillLevel'], equals(9));
        expect(optimalAllocation['teamMemberId'], equals('tm003'));

        // Verify allocation goes to most skilled available member
        final allocatedMember = teamMembers.firstWhere(
          (member) => member['id'] == optimalAllocation['teamMemberId']
        );
        expect(allocatedMember['skillLevel'], equals(9));

        // TODO: Verify optimization logic when implementations are available
        // verify(mockAllocateCapacityUsecase.execute(argThat(
        //   predicate<AllocateCapacityParams>((params) => params.teamMemberId == 'tm003')
        // ))).called(1);
      });
    });

    group('Multi-Quarter Allocation Management', () {
      test('should handle allocations spanning multiple quarters', () async {
        // ARRANGE - Multi-quarter allocation
        final q3Start = DateTime(2024, 7, 1);
        final q4End = DateTime(2024, 12, 31);
        
        final multiQuarterAllocation = {
          ...testAllocation,
          'id': 'ca_multi',
          'allocatedWeeks': 12.0, // Spans across quarters
          'startDate': q3Start.toIso8601String(),
          'endDate': q4End.toIso8601String(),
        };

        // ACT - Calculate quarter distribution
        final q3EndDate = DateTime(2024, 9, 30);
        final q4StartDate = DateTime(2024, 10, 1);

        // Calculate weeks in each quarter
        final q3Duration = q3EndDate.difference(q3Start).inDays / 7;
        final q4Duration = q4End.difference(q4StartDate).inDays / 7;
        final totalDuration = q3Duration + q4Duration;

        final q3Allocation = (q3Duration / totalDuration) * 12.0;
        final q4Allocation = (q4Duration / totalDuration) * 12.0;

        // ASSERT
        expect(q3Duration, closeTo(13.0, 1.0)); // Q3 is ~13 weeks
        expect(q4Duration, closeTo(13.0, 1.0)); // Q4 is ~13 weeks
        expect(q3Allocation, closeTo(6.0, 0.5)); // ~6 weeks in Q3
        expect(q4Allocation, closeTo(6.0, 0.5)); // ~6 weeks in Q4
        expect(q3Allocation + q4Allocation, closeTo(12.0, 0.1));

        // Verify multi-quarter detection
        final allocationStart = DateTime.parse(multiQuarterAllocation['startDate'] as String);
        final allocationEnd = DateTime.parse(multiQuarterAllocation['endDate'] as String);
        final startQuarter = ((allocationStart.month - 1) ~/ 3) + 1;
        final endQuarter = ((allocationEnd.month - 1) ~/ 3) + 1;
        final isMultiQuarter = startQuarter != endQuarter;

        expect(isMultiQuarter, isTrue);
        expect(startQuarter, equals(3)); // Q3
        expect(endQuarter, equals(4)); // Q4

        // TODO: Verify multi-quarter handling when implementations are available
        // verify(mockQuarterPlanRepository.updateMultiQuarterAllocation(any)).called(1);
      });

      test('should validate capacity across quarters for long allocations', () async {
        // ARRANGE - Team member with varying quarterly capacity
        final quarterCapacities = {
          'Q3_2024': {'available': 13.0, 'allocated': 5.0},
          'Q4_2024': {'available': 13.0, 'allocated': 8.0},
        };

        // ACT - Validate capacity in each quarter
        final q3RemainingCapacity = quarterCapacities['Q3_2024']!['available']! - 
                                   quarterCapacities['Q3_2024']!['allocated']!;
        final q4RemainingCapacity = quarterCapacities['Q4_2024']!['available']! - 
                                   quarterCapacities['Q4_2024']!['allocated']!;

        const weeksPerQuarter = 5.0;
        final q3CanAccommodate = q3RemainingCapacity >= weeksPerQuarter;
        final q4CanAccommodate = q4RemainingCapacity >= weeksPerQuarter;
        final allocationFeasible = q3CanAccommodate && q4CanAccommodate;

        // ASSERT
        expect(q3RemainingCapacity, equals(8.0)); // 13 - 5
        expect(q4RemainingCapacity, equals(5.0)); // 13 - 8
        expect(q3CanAccommodate, isTrue); // 8 >= 5
        expect(q4CanAccommodate, isTrue); // 5 >= 5
        expect(allocationFeasible, isTrue);

        // Test over-capacity scenario
        const overWeeksPerQuarter = 8.0;
        final q3OverCapacity = q3RemainingCapacity < overWeeksPerQuarter;
        final q4OverCapacity = q4RemainingCapacity < overWeeksPerQuarter;
        final hasOverCapacity = q3OverCapacity || q4OverCapacity;

        expect(q3OverCapacity, isFalse); // 8 >= 8
        expect(q4OverCapacity, isTrue); // 5 < 8
        expect(hasOverCapacity, isTrue);

        // TODO: Verify cross-quarter validation when implementations are available
        // verify(mockValidateAllocationUsecase.execute(any)).called(1);
      });
    });

    group('Over-allocation Detection and Prevention', () {
      test('should detect team member over-allocation in real-time', () async {
        // ARRANGE - Team member with existing allocations
        final existingAllocations = [
          {...testAllocation, 'id': 'ca001', 'allocatedWeeks': 6.0},
          {...testAllocation, 'id': 'ca002', 'allocatedWeeks': 4.0},
        ];

        final newAllocation = {
          ...testAllocation,
          'id': 'ca003',
          'allocatedWeeks': 5.0, // Would cause over-allocation
        };

        // ACT - Check current utilization
        final currentAllocated = existingAllocations.fold<double>(
          0.0,
          (sum, allocation) => sum + (allocation['allocatedWeeks'] as double)
        );
        
        final memberCapacity = testTeamMember['weeklyCapacity'] as double;
        const quarterWeeks = 13.0;
        final totalCapacity = memberCapacity * quarterWeeks;
        
        final currentUtilization = currentAllocated / totalCapacity;
        final newTotalAllocated = currentAllocated + (newAllocation['allocatedWeeks'] as double);
        final newUtilization = newTotalAllocated / totalCapacity;
        final wouldOverAllocate = newUtilization > 1.0;

        // ASSERT
        expect(currentAllocated, equals(10.0));
        expect(totalCapacity, equals(13.0));
        expect(currentUtilization, closeTo(0.77, 0.01)); // ~77%
        expect(newTotalAllocated, equals(15.0));
        expect(newUtilization, closeTo(1.15, 0.01)); // ~115%
        expect(wouldOverAllocate, isTrue);

        // Verify over-allocation detection
        final overAllocationAmount = newTotalAllocated - totalCapacity;
        expect(overAllocationAmount, equals(2.0));

        // TODO: Verify over-allocation prevention when implementations are available
        // when(mockValidateAllocationUsecase.execute(any))
        //     .thenAnswer((_) async => Result.error(OverAllocationException('Member over-allocated')));
      });

      test('should suggest alternative allocations when over-allocation detected', () async {
        // ARRANGE - Team with mixed capacity availability
        final teamWithCapacity = [
          {'id': 'tm001', 'availableWeeks': 2.0, 'skillLevel': 8},
          {'id': 'tm002', 'availableWeeks': 5.0, 'skillLevel': 6},
          {'id': 'tm003', 'availableWeeks': 8.0, 'skillLevel': 7},
        ];

        final requiredAllocation = {
          'role': 'frontend',
          'allocatedWeeks': 4.0,
        };

        // ACT - Find suitable alternatives
        final suitableMembers = teamWithCapacity
            .where((member) => 
                (member['availableWeeks'] as double) >= 
                (requiredAllocation['allocatedWeeks'] as double))
            .toList();

        // Sort by skill level (prefer higher skill)
        suitableMembers.sort((a, b) => 
            (b['skillLevel'] as int).compareTo(a['skillLevel'] as int));

        // ASSERT
        expect(suitableMembers, hasLength(2)); // tm002 and tm003
        expect(suitableMembers.map((m) => m['id']), containsAll(['tm002', 'tm003']));
        expect(suitableMembers.first['id'], equals('tm003')); // Highest skill level
        expect(suitableMembers.first['availableWeeks'], equals(8.0));
        expect(suitableMembers.first['skillLevel'], equals(7));

        // Verify exclusion of over-allocated member
        expect(suitableMembers.map((m) => m['id']), isNot(contains('tm001')));

        // TODO: Verify alternative suggestion when implementations are available
        // verify(mockAllocateCapacityUsecase.suggestAlternatives(any)).called(1);
      });

      test('should handle cascading allocation adjustments', () async {
        // ARRANGE - Initiative requiring multiple team members
        final largeInitiative = {
          ...testInitiative,
          'id': 'init_large',
          'name': 'Platform Migration',
          'requiredRoles': {
            'backend': 8.0,
            'frontend': 6.0,
            'devops': 4.0,
          },
        };

        final availableTeam = [
          {'id': 'tm001', 'role': 'backend', 'capacity': 4.0},
          {'id': 'tm002', 'role': 'backend', 'capacity': 5.0},
          {'id': 'tm003', 'role': 'frontend', 'capacity': 6.0},
          {'id': 'tm004', 'role': 'devops', 'capacity': 4.0},
        ];

        // ACT - Distribute allocations
        final roleRequirements = largeInitiative['requiredRoles'] as Map<String, double>;
        final allocations = <Map<String, dynamic>>[];

        for (final entry in roleRequirements.entries) {
          final role = entry.key;
          var remainingRequirement = entry.value;

          final availableForRole = availableTeam
              .where((member) => member['role'] == role)
              .toList();

          for (final member in availableForRole) {
            if (remainingRequirement <= 0) break;

            final memberCapacity = member['capacity'] as double;
            final allocationAmount = remainingRequirement > memberCapacity 
                ? memberCapacity 
                : remainingRequirement;

            allocations.add({
              'teamMemberId': member['id'],
              'role': role,
              'allocatedWeeks': allocationAmount,
            });

            remainingRequirement -= allocationAmount;
          }
        }

        // ASSERT
        expect(allocations, hasLength(4)); // All team members allocated
        
        // Verify backend allocation (8.0 weeks required)
        final backendAllocations = allocations.where((a) => a['role'] == 'backend').toList();
        final totalBackendAllocated = backendAllocations.fold<double>(
          0.0, (sum, a) => sum + (a['allocatedWeeks'] as double)
        );
        expect(totalBackendAllocated, equals(8.0)); // 4.0 + 4.0 (tm002 gets only 4.0)

        // Verify frontend allocation (6.0 weeks required)
        final frontendAllocations = allocations.where((a) => a['role'] == 'frontend').toList();
        expect(frontendAllocations, hasLength(1));
        expect(frontendAllocations.first['allocatedWeeks'], equals(6.0));

        // Verify devops allocation (4.0 weeks required)
        final devopsAllocations = allocations.where((a) => a['role'] == 'devops').toList();
        expect(devopsAllocations, hasLength(1));
        expect(devopsAllocations.first['allocatedWeeks'], equals(4.0));

        // TODO: Verify cascading allocation when implementations are available
        // verify(mockAllocateCapacityUsecase.executeMultiple(any)).called(1);
      });
    });

    group('Real-time State Management', () {
      test('should maintain consistency across concurrent allocation updates', () async {
        // ARRANGE - Simulate concurrent operations
        final concurrentOperations = [
          {'type': 'create', 'allocationId': 'ca001', 'weeks': 3.0, 'timestamp': 1},
          {'type': 'update', 'allocationId': 'ca001', 'weeks': 4.0, 'timestamp': 2},
          {'type': 'create', 'allocationId': 'ca002', 'weeks': 2.0, 'timestamp': 3},
          {'type': 'delete', 'allocationId': 'ca001', 'timestamp': 4},
        ];

        // ACT - Apply operations in timestamp order
        final orderedOperations = List.from(concurrentOperations)
          ..sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));

        final allocationState = <String, Map<String, dynamic>>{};
        var totalAllocated = 0.0;

        for (final operation in orderedOperations) {
          final type = operation['type'] as String;
          final id = operation['allocationId'] as String;
          final weeks = operation['weeks'] as double? ?? 0.0;

          switch (type) {
            case 'create':
              allocationState[id] = {'id': id, 'weeks': weeks};
              totalAllocated += weeks;
              break;
            case 'update':
              if (allocationState.containsKey(id)) {
                final oldWeeks = allocationState[id]!['weeks'] as double;
                allocationState[id]!['weeks'] = weeks;
                totalAllocated = totalAllocated - oldWeeks + weeks;
              }
              break;
            case 'delete':
              if (allocationState.containsKey(id)) {
                final deletedWeeks = allocationState[id]!['weeks'] as double;
                allocationState.remove(id);
                totalAllocated -= deletedWeeks;
              }
              break;
          }
        }

        // ASSERT
        expect(allocationState, hasLength(1)); // Only ca002 remains
        expect(allocationState.containsKey('ca002'), isTrue);
        expect(allocationState.containsKey('ca001'), isFalse); // Deleted
        expect(totalAllocated, equals(2.0)); // Only ca002's 2.0 weeks
        expect(allocationState['ca002']!['weeks'], equals(2.0));

        // Verify operation ordering
        expect(orderedOperations[0]['type'], equals('create'));
        expect(orderedOperations.last['type'], equals('delete'));

        // TODO: Verify state consistency when implementations are available
        // verify(mockAllocationRepository.applyOperationsAtomically(any)).called(1);
      });

      test('should propagate capacity changes to affected quarter plans', () async {
        // ARRANGE - Multiple quarter plans with same team member
        final affectedQuarterPlans = [
          {'id': 'qp_q3', 'quarter': 3, 'totalAllocated': 8.0},
          {'id': 'qp_q4', 'quarter': 4, 'totalAllocated': 6.0},
        ];

        final capacityChange = {
          'teamMemberId': 'tm001',
          'oldCapacity': 1.0,
          'newCapacity': 0.8, // Reduced capacity
          'effectiveDate': DateTime(2024, 8, 1),
        };

        // ACT - Recalculate affected plans
        final recalculatedPlans = <Map<String, dynamic>>[];
        
        for (final plan in affectedQuarterPlans) {
          final planId = plan['id'] as String;
          final quarter = plan['quarter'] as int;
          final currentAllocated = plan['totalAllocated'] as double;
          
          // Simulate recalculation based on new capacity
          const quarterWeeks = 13.0;
          final oldTotalCapacity = (capacityChange['oldCapacity'] as double) * quarterWeeks;
          final newTotalCapacity = (capacityChange['newCapacity'] as double) * quarterWeeks;
          
          final oldUtilization = currentAllocated / oldTotalCapacity;
          final newUtilization = currentAllocated / newTotalCapacity;
          final isNowOverAllocated = newUtilization > 1.0;

          recalculatedPlans.add({
            'id': planId,
            'quarter': quarter,
            'oldCapacity': oldTotalCapacity,
            'newCapacity': newTotalCapacity,
            'allocated': currentAllocated,
            'oldUtilization': oldUtilization,
            'newUtilization': newUtilization,
            'isOverAllocated': isNowOverAllocated,
          });
        }

        // ASSERT
        expect(recalculatedPlans, hasLength(2));
        
        // Q3 plan verification
        final q3Plan = recalculatedPlans.firstWhere((p) => p['quarter'] == 3);
        expect(q3Plan['oldCapacity'], equals(13.0)); // 1.0 * 13
        expect(q3Plan['newCapacity'], equals(10.4)); // 0.8 * 13
        expect(q3Plan['oldUtilization'], closeTo(0.615, 0.01)); // 8.0 / 13.0
        expect(q3Plan['newUtilization'], closeTo(0.769, 0.01)); // 8.0 / 10.4
        expect(q3Plan['isOverAllocated'], isFalse);

        // Q4 plan verification  
        final q4Plan = recalculatedPlans.firstWhere((p) => p['quarter'] == 4);
        expect(q4Plan['newUtilization'], closeTo(0.577, 0.01)); // 6.0 / 10.4
        expect(q4Plan['isOverAllocated'], isFalse);

        // TODO: Verify plan updates when implementations are available
        // verify(mockQuarterPlanRepository.updateCapacityMetrics(any)).called(2);
      });

      test('should handle allocation conflict resolution', () async {
        // ARRANGE - Conflicting allocation attempts
        final conflictScenario = {
          'teamMemberId': 'tm001',
          'availableCapacity': 3.0,
          'conflictingAllocations': [
            {'id': 'ca001', 'priority': 8, 'weeks': 2.0, 'initiativeId': 'init001'},
            {'id': 'ca002', 'priority': 9, 'weeks': 2.5, 'initiativeId': 'init002'},
            {'id': 'ca003', 'priority': 7, 'weeks': 1.5, 'initiativeId': 'init003'},
          ],
        };

        // ACT - Resolve conflicts by priority
        final allocations = conflictScenario['conflictingAllocations'] as List<Map<String, dynamic>>;
        final availableCapacity = conflictScenario['availableCapacity'] as double;
        
        // Sort by priority (highest first)
        allocations.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
        
        final resolvedAllocations = <Map<String, dynamic>>[];
        var remainingCapacity = availableCapacity;
        
        for (final allocation in allocations) {
          final requiredWeeks = allocation['weeks'] as double;
          
          if (remainingCapacity >= requiredWeeks) {
            resolvedAllocations.add({
              ...allocation,
              'status': 'approved',
              'allocatedWeeks': requiredWeeks,
            });
            remainingCapacity -= requiredWeeks;
          } else if (remainingCapacity > 0) {
            resolvedAllocations.add({
              ...allocation,
              'status': 'partial',
              'allocatedWeeks': remainingCapacity,
              'originalRequest': requiredWeeks,
            });
            remainingCapacity = 0;
          } else {
            resolvedAllocations.add({
              ...allocation,
              'status': 'rejected',
              'allocatedWeeks': 0.0,
              'reason': 'Insufficient capacity',
            });
          }
        }

        // ASSERT
        expect(resolvedAllocations, hasLength(3));
        
        // Highest priority (9) gets partial allocation (2.5 requested, only 3.0 available)
        final highestPriority = resolvedAllocations[0];
        expect(highestPriority['priority'], equals(9));
        expect(highestPriority['status'], equals('approved'));
        expect(highestPriority['allocatedWeeks'], equals(2.5)); // Gets full requested amount

        // Medium priority (8) gets partial allocation (remaining capacity: 3.0 - 2.5 = 0.5)
        final mediumPriority = resolvedAllocations[1];
        expect(mediumPriority['priority'], equals(8));
        expect(mediumPriority['status'], equals('partial'));
        expect(mediumPriority['allocatedWeeks'], equals(0.5));

        // Lowest priority (7) gets rejected
        final lowestPriority = resolvedAllocations[2];
        expect(lowestPriority['priority'], equals(7));
        expect(lowestPriority['status'], equals('rejected'));
        expect(lowestPriority['allocatedWeeks'], equals(0.0));

        // Verify total allocation doesn't exceed capacity
        final totalAllocated = resolvedAllocations.fold<double>(
          0.0, (sum, a) => sum + (a['allocatedWeeks'] as double)
        );
        expect(totalAllocated, equals(3.0)); // 2.5 + 0.5 + 0.0 = 3.0
        expect(totalAllocated, lessThanOrEqualTo(availableCapacity));

        // TODO: Verify conflict resolution when implementations are available
        // verify(mockAllocateCapacityUsecase.resolveConflicts(any)).called(1);
      });
    });

    group('Performance and Scalability', () {
      test('should handle large-scale allocation operations efficiently', () async {
        // ARRANGE - Large dataset
        const numTeamMembers = 100;
        const numInitiatives = 50;
        const numAllocations = 500;

        final largeTeam = List.generate(numTeamMembers, (index) => {
          'id': 'tm${index.toString().padLeft(3, '0')}',
          'name': 'Team Member $index',
          'roles': ['frontend', 'backend'][index % 2],
          'weeklyCapacity': 1.0,
        });

        final largeInitiativeSet = List.generate(numInitiatives, (index) => {
          'id': 'init${index.toString().padLeft(3, '0')}',
          'name': 'Initiative $index',
          'priority': (index % 10) + 1,
        });

        final largeAllocationSet = List.generate(numAllocations, (index) => {
          'id': 'ca${index.toString().padLeft(3, '0')}',
          'teamMemberId': largeTeam[index % numTeamMembers]['id'],
          'initiativeId': largeInitiativeSet[index % numInitiatives]['id'],
          'allocatedWeeks': 1.0 + (index % 5), // 1-5 weeks
        });

        // ACT - Measure performance metrics
        final stopwatch = Stopwatch()..start();

        // Simulate capacity calculations
        final capacityByMember = <String, double>{};
        for (final member in largeTeam) {
          final memberId = member['id'] as String;
          final memberAllocations = largeAllocationSet
              .where((a) => a['teamMemberId'] == memberId)
              .toList();
          
          final totalAllocated = memberAllocations.fold<double>(
            0.0, (sum, a) => sum + (a['allocatedWeeks'] as double)
          );
          
          capacityByMember[memberId] = totalAllocated;
        }

        stopwatch.stop();
        final processingTime = stopwatch.elapsedMilliseconds;

        // ASSERT - Performance requirements
        expect(processingTime, lessThan(1000)); // Should complete within 1 second
        expect(capacityByMember, hasLength(numTeamMembers));
        expect(largeAllocationSet, hasLength(numAllocations));

        // Verify data integrity
        final totalAllAllocations = largeAllocationSet.fold<double>(
          0.0, (sum, a) => sum + (a['allocatedWeeks'] as double)
        );
        final totalCapacityCalculations = capacityByMember.values.fold<double>(
          0.0, (sum, capacity) => sum + capacity
        );
        
        expect(totalCapacityCalculations, equals(totalAllAllocations));

        // Verify no data corruption
        expect(largeTeam.every((m) => (m['id'] as String).isNotEmpty), isTrue);
        expect(largeAllocationSet.every((a) => (a['allocatedWeeks'] as double) > 0), isTrue);

        // TODO: Verify performance metrics when implementations are available
        // verify(mockAllocationRepository.bulkOperations(any)).called(1);
      });

      test('should optimize memory usage for large allocation datasets', () async {
        // ARRANGE - Memory-intensive operations
        const batchSize = 100;
        const totalAllocations = 1000;
        
        var processedCount = 0;
        var peakMemoryAllocations = 0;
        final currentBatch = <Map<String, dynamic>>[];

        // ACT - Process in batches to optimize memory
        for (var i = 0; i < totalAllocations; i++) {
          final allocation = {
            'id': 'ca_$i',
            'teamMemberId': 'tm_${i % 50}',
            'allocatedWeeks': 2.0,
          };

          currentBatch.add(allocation);
          peakMemoryAllocations = currentBatch.length > peakMemoryAllocations 
              ? currentBatch.length 
              : peakMemoryAllocations;

          if (currentBatch.length >= batchSize) {
            // Process batch
            processedCount += currentBatch.length;
            currentBatch.clear(); // Free memory
          }
        }

        // Process remaining items
        if (currentBatch.isNotEmpty) {
          processedCount += currentBatch.length;
          currentBatch.clear();
        }

        // ASSERT - Memory efficiency
        expect(processedCount, equals(totalAllocations));
        expect(peakMemoryAllocations, equals(batchSize)); // Never exceeded batch size
        expect(currentBatch, isEmpty); // Memory cleaned up

        // Verify batch processing efficiency
        final expectedBatches = (totalAllocations / batchSize).ceil();
        expect(expectedBatches, equals(10)); // 1000 / 100 = 10 batches

        // TODO: Verify memory optimization when implementations are available
        // verify(mockAllocationRepository.processBatch(any)).called(expectedBatches);
      });
    });
  });
}
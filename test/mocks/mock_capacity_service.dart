import 'package:capest_timeline/services/capacity_service.dart';
import 'package:capest_timeline/services/storage_service.dart';
import 'package:capest_timeline/models/models.dart';
import 'package:capest_timeline/core/errors/kanban_service_exceptions.dart';

/// Mock implementation of CapacityService for testing error scenarios
class MockCapacityService extends CapacityService {
  // Error simulation flags
  bool shouldFailCalculation = false;
  bool shouldRejectOverAllocation = false;
  bool shouldReturnEmptyTeamData = false;

  // Error messages
  String calculationFailureMessage = 'Mock capacity calculation failure';

  // Mock data
  List<TeamMember> mockTeamMembers = [];
  List<Assignment> mockAssignments = [];

  MockCapacityService(StorageService storageService) : super(storageService: storageService);

  @override
  Future<List<CapacityData>> calculateTeamCapacity({
    required DateTime startDate,
    required DateTime endDate,
    String? platformFilter,
  }) async {
    if (shouldFailCalculation) {
      throw CapacityCalculationException(calculationFailureMessage);
    }

    if (shouldReturnEmptyTeamData) {
      throw const MissingDataException('No team member data available');
    }

    // Return mock capacity data
    return [
      CapacityData(
        totalCapacity: 80.0, // 2 team members * 40 hours
        usedCapacity: 40.0,  // 50% utilization
        availableCapacity: 40.0,
        utilizationPercentage: 50.0,
        isOverAllocated: false,
        weekDate: startDate,
        teamMembers: mockTeamMembers,
      ),
    ];
  }

  @override
  Future<List<CapacityPeriod>> getCapacityPeriods(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (shouldFailCalculation) {
      throw CapacityCalculationException(calculationFailureMessage);
    }

    if (shouldReturnEmptyTeamData) {
      throw const MissingDataException('No team member data available');
    }

    // Generate mock capacity periods
    final capacityPeriods = <CapacityPeriod>[];
    var currentWeek = startDate;
    
    while (currentWeek.isBefore(endDate) || currentWeek.isAtSameMomentAs(endDate)) {
      final weekEnd = currentWeek.add(const Duration(days: 6));

      capacityPeriods.add(CapacityPeriod(
        weekStart: currentWeek,
        weekEnd: weekEnd,
        assignments: mockAssignments,
        totalCapacityAvailable: mockTeamMembers.length * 40.0, // 40 hours per person
      ));

      currentWeek = currentWeek.add(const Duration(days: 7));
    }

    return capacityPeriods;
  }

  @override
  Future<List<String>> detectConflicts({
    required DateTime startDate,
    required DateTime endDate,
    String? platformFilter,
  }) async {
    if (shouldFailCalculation) {
      throw CapacityCalculationException(calculationFailureMessage);
    }

    if (shouldRejectOverAllocation) {
      return ['Mock conflict: Over-allocation detected'];
    }

    return []; // No conflicts in mock
  }

  @override
  Future<Map<String, double>> calculateUtilization({
    required DateTime startDate,
    required DateTime endDate,
    String? roleFilter,
  }) async {
    if (shouldFailCalculation) {
      throw CapacityCalculationException(calculationFailureMessage);
    }

    return {
      'averageUtilization': 50.0,
      'totalCapacity': 80.0,
      'totalUtilized': 40.0,
      'averageCapacityPerWeek': 80.0,
      'averageUtilizedPerWeek': 40.0,
      'periodCount': 1.0,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> suggestAllocation({
    required Initiative initiative,
    required DateTime preferredStartDate,
    DateTime? deadline,
  }) async {
    if (shouldFailCalculation) {
      throw const CapacityCalculationException('Failed to suggest allocation');
    }

    if (shouldReturnEmptyTeamData && mockTeamMembers.isEmpty) {
      throw const MissingDataException('No team members available for allocation');
    }

    return []; // Mock empty suggestions
  }

  @override
  Future<Map<String, dynamic>> getMemberAvailability({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (shouldFailCalculation) {
      throw const CapacityCalculationException('Failed to get member availability');
    }

    return {
      'available': true,
      'weeklyCapacityHours': 40.0,
      'weeklyUtilizationHours': 20.0,
      'availableHours': 20.0,
      'utilizationPercentage': 50.0,
      'isOverAllocated': false,
      'assignments': [],
    };
  }

  @override
  Future<Map<String, dynamic>> getCapacityUtilization(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (shouldFailCalculation) {
      throw const CapacityCalculationException('Failed to get capacity utilization');
    }

    return {
      'overall': {
        'totalCapacity': 80.0,
        'utilizedCapacity': 40.0,
        'utilizationPercentage': 50.0,
        'memberCount': 2,
      },
      'byMember': {},
      'dateRange': {
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> validateCapacityConstraints(
    List<Assignment> proposedAssignments,
  ) async {
    if (shouldFailCalculation) {
      throw const CapacityCalculationException('Failed to validate capacity constraints');
    }

    if (shouldRejectOverAllocation) {
      return {
        'isValid': false,
        'violations': [
          {
            'type': 'overallocation',
            'message': 'Mock over-allocation violation',
          }
        ],
        'warnings': [],
        'validatedAssignments': proposedAssignments.length,
      };
    }

    return {
      'isValid': true,
      'violations': [],
      'warnings': [],
      'validatedAssignments': proposedAssignments.length,
    };
  }

  /// Reset all error simulation flags
  void resetErrorFlags() {
    shouldFailCalculation = false;
    shouldRejectOverAllocation = false;
    shouldReturnEmptyTeamData = false;
  }

  /// Set mock team members for testing
  void setMockTeamMembers(List<TeamMember> members) {
    mockTeamMembers = members;
  }

  /// Set mock assignments for testing
  void setMockAssignments(List<Assignment> assignments) {
    mockAssignments = assignments;
  }
}
import 'dart:math' as math;
import '../models/models.dart';
import 'storage_service.dart';

/// Service for handling capacity calculations and team management
class CapacityService {
  const CapacityService({
    required this.storageService,
  });

  final StorageService storageService;

  /// Calculate team capacity for a specific time range
  Future<List<CapacityData>> calculateTeamCapacity({
    required DateTime startDate,
    required DateTime endDate,
    String? platformFilter,
  }) async {
    final teamMembers = await storageService.loadTeamMembers();
    final assignments = await storageService.loadAssignments();

    final capacityPeriods = <CapacityData>[];
    
    // Generate weekly periods
    DateTime currentWeek = _getWeekStart(startDate);
    while (currentWeek.isBefore(endDate) || currentWeek.isAtSameMomentAs(endDate)) {
      final weekEnd = currentWeek.add(const Duration(days: 6));
      
      // Filter active team members for this week
      final activeMembers = teamMembers.where((member) {
        if (!member.isActive) return false;
        if (member.startDate != null && currentWeek.isBefore(member.startDate!)) return false;
        if (member.endDate != null && currentWeek.isAfter(member.endDate!)) return false;
        if (platformFilter != null && !member.skills.contains(platformFilter)) return false;
        return true;
      }).toList();

      // Calculate capacity for the week
      final weekCapacity = _calculateWeekCapacity(
        currentWeek,
        weekEnd,
        activeMembers,
        assignments,
      );

      capacityPeriods.add(weekCapacity);
      currentWeek = currentWeek.add(const Duration(days: 7));
    }

    return capacityPeriods;
  }

  /// Get capacity periods with detailed assignment information
  Future<List<CapacityPeriod>> getCapacityPeriods(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final teamMembers = await storageService.loadTeamMembers();
    final assignments = await storageService.loadAssignments();

    final periods = <CapacityPeriod>[];
    
    DateTime currentWeek = _getWeekStart(startDate);
    while (currentWeek.isBefore(endDate) || currentWeek.isAtSameMomentAs(endDate)) {
      final weekEnd = currentWeek.add(const Duration(days: 6));
      
      // Get assignments for this week
      final weekAssignments = assignments.where((assignment) {
        return assignment.overlapsWithRange(currentWeek, weekEnd);
      }).toList();

      // Get active team members for this week
      final activeMembers = teamMembers.where((member) {
        if (!member.isActive) return false;
        if (member.startDate != null && currentWeek.isBefore(member.startDate!)) return false;
        if (member.endDate != null && currentWeek.isAfter(member.endDate!)) return false;
        return true;
      }).toList();

      final period = CapacityPeriod.fromTeamMembers(
        weekStart: currentWeek,
        weekEnd: weekEnd,
        teamMembers: activeMembers,
        assignments: weekAssignments,
      );

      periods.add(period);
      currentWeek = currentWeek.add(const Duration(days: 7));
    }

    return periods;
  }

  /// Check for capacity conflicts and over-allocations
  Future<List<String>> detectConflicts({
    required DateTime startDate,
    required DateTime endDate,
    String? platformFilter,
  }) async {
    final conflicts = <String>[];
    final capacityPeriods = await getCapacityPeriods(startDate, endDate);

    for (final period in capacityPeriods) {
      if (period.calculatedIsOverAllocated) {
        final overAllocation = period.calculatedUtilizedCapacity - period.totalCapacityAvailable;
        conflicts.add(
          '${period.shortWeekDisplay}: Over-allocated by ${overAllocation.toStringAsFixed(1)} hours'
        );
      }

      // Check for individual member over-allocations
      for (final member in period.teamMembers) {
        final memberUtilization = period.getMemberUtilization(member.id);
        final memberCapacity = member.weeklyCapacity * 40; // Convert to hours
        
        if (memberUtilization > memberCapacity) {
          final overAllocation = memberUtilization - memberCapacity;
          conflicts.add(
            '${period.shortWeekDisplay}: ${member.name} over-allocated by ${overAllocation.toStringAsFixed(1)} hours'
          );
        }
      }

      // Check for platform-specific conflicts if filter is applied
      if (platformFilter != null) {
        final platformCapacity = period.getPlatformCapacity(platformFilter);
        final platformMembers = period.teamMembers
            .where((m) => m.skills.contains(platformFilter))
            .toList();
        final totalPlatformCapacity = platformMembers
            .fold(0.0, (sum, m) => sum + m.weeklyCapacity * 40);

        if (platformCapacity > totalPlatformCapacity) {
          final overAllocation = platformCapacity - totalPlatformCapacity;
          conflicts.add(
            '${period.shortWeekDisplay}: $platformFilter over-allocated by ${overAllocation.toStringAsFixed(1)} hours'
          );
        }
      }
    }

    return conflicts;
  }

  /// Calculate utilization metrics for the team
  Future<Map<String, double>> calculateUtilization({
    required DateTime startDate,
    required DateTime endDate,
    String? roleFilter,
  }) async {
    final capacityPeriods = await getCapacityPeriods(startDate, endDate);
    
    double totalCapacity = 0.0;
    double totalUtilized = 0.0;
    int periodCount = 0;

    for (final period in capacityPeriods) {
      totalCapacity += period.totalCapacityAvailable;
      totalUtilized += period.calculatedUtilizedCapacity;
      periodCount++;
    }

    final averageUtilization = totalCapacity > 0 ? (totalUtilized / totalCapacity) * 100 : 0.0;
    final averageCapacityPerWeek = periodCount > 0 ? totalCapacity / periodCount : 0.0;
    final averageUtilizedPerWeek = periodCount > 0 ? totalUtilized / periodCount : 0.0;

    return {
      'averageUtilization': averageUtilization,
      'totalCapacity': totalCapacity,
      'totalUtilized': totalUtilized,
      'averageCapacityPerWeek': averageCapacityPerWeek,
      'averageUtilizedPerWeek': averageUtilizedPerWeek,
      'periodCount': periodCount.toDouble(),
    };
  }

  /// Suggest optimal allocation for an initiative
  Future<List<Map<String, dynamic>>> suggestAllocation({
    required Initiative initiative,
    required DateTime preferredStartDate,
    DateTime? deadline,
  }) async {
    final suggestions = <Map<String, dynamic>>[];
    final teamMembers = await storageService.loadTeamMembers();

    for (final variant in initiative.variants) {
      final requiredSkills = variant.platformType;
      final estimatedHours = variant.estimatedWeeks * 40; // Convert weeks to hours

      // Find team members with matching skills
      final suitableMembers = teamMembers.where((member) {
        return member.isActive && 
               member.skills.contains(requiredSkills) &&
               (member.startDate == null || !preferredStartDate.isBefore(member.startDate!)) &&
               (member.endDate == null || !preferredStartDate.isAfter(member.endDate!));
      }).toList();

      if (suitableMembers.isNotEmpty) {
        // Sort members by availability and skills
        suitableMembers.sort((a, b) {
          // Prioritize members with higher skill levels or more experience
          final aSkillLevel = a.skillLevel ?? 0.5;
          final bSkillLevel = b.skillLevel ?? 0.5;
          return bSkillLevel.compareTo(aSkillLevel);
        });

        suggestions.add({
          'variantId': variant.id,
          'platformType': variant.platformType,
          'estimatedHours': estimatedHours,
          'suggestedMembers': suitableMembers.take(3).map((m) => {
            'memberId': m.id,
            'memberName': m.name,
            'weeklyCapacity': m.weeklyCapacity,
            'skills': m.skills,
            'skillLevel': m.skillLevel ?? 0.5,
          }).toList(),
          'recommendedStartDate': preferredStartDate.toIso8601String(),
          'estimatedEndDate': preferredStartDate
              .add(Duration(days: (variant.estimatedWeeks * 7).round()))
              .toIso8601String(),
        });
      }
    }

    return suggestions;
  }

  /// Get team member availability for a specific time range
  Future<Map<String, dynamic>> getMemberAvailability({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final member = await _getTeamMember(memberId);
    if (member == null) {
      return {
        'available': false,
        'reason': 'Team member not found',
      };
    }

    final assignments = await storageService.loadAssignments();
    final memberAssignments = assignments
        .where((a) => a.memberId == memberId)
        .where((a) => a.overlapsWithRange(startDate, endDate))
        .toList();

    // Calculate weekly availability
    final weeklyCapacity = member.weeklyCapacity * 40; // Convert to hours
    final weeklyUtilization = memberAssignments
        .fold(0.0, (sum, assignment) => sum + assignment.hoursPerWeek);
    
    final availableHours = weeklyCapacity - weeklyUtilization;
    final utilizationPercentage = weeklyCapacity > 0 
        ? (weeklyUtilization / weeklyCapacity) * 100 
        : 0.0;

    // Check if member is available during the requested period
    final isAvailable = member.isActive &&
        (member.startDate == null || !endDate.isBefore(member.startDate!)) &&
        (member.endDate == null || !startDate.isAfter(member.endDate!));

    return {
      'available': isAvailable,
      'weeklyCapacityHours': weeklyCapacity,
      'weeklyUtilizationHours': weeklyUtilization,
      'availableHours': math.max(0.0, availableHours),
      'utilizationPercentage': utilizationPercentage,
      'isOverAllocated': weeklyUtilization > weeklyCapacity,
      'assignments': memberAssignments.map((a) => {
        'assignmentId': a.id,
        'hoursPerWeek': a.hoursPerWeek,
        'startWeek': a.startWeek.toIso8601String(),
        'endWeek': a.calculatedEndWeek.toIso8601String(),
        'platformType': a.platformType.name,
      }).toList(),
    };
  }

  /// Helper method to calculate capacity for a specific week
  CapacityData _calculateWeekCapacity(
    DateTime weekStart,
    DateTime weekEnd,
    List<TeamMember> activeMembers,
    List<Assignment> allAssignments,
  ) {
    // Calculate total available capacity for the week
    final totalCapacity = activeMembers.fold(0.0, (sum, member) {
      return sum + (member.weeklyCapacity * 40); // Convert to hours
    });

    // Get assignments that overlap with this week
    final weekAssignments = allAssignments.where((assignment) {
      return assignment.overlapsWithRange(weekStart, weekEnd);
    }).toList();

    // Calculate used capacity
    final usedCapacity = weekAssignments.fold(0.0, (sum, assignment) {
      return sum + assignment.hoursPerWeek;
    });

    final availableCapacity = totalCapacity - usedCapacity;
    final utilizationPercentage = totalCapacity > 0 
        ? (usedCapacity / totalCapacity) * 100 
        : 0.0;
    final isOverAllocated = usedCapacity > totalCapacity;

    return CapacityData(
      totalCapacity: totalCapacity,
      usedCapacity: usedCapacity,
      availableCapacity: math.max(0.0, availableCapacity),
      utilizationPercentage: utilizationPercentage,
      isOverAllocated: isOverAllocated,
      weekDate: weekStart,
      teamMembers: activeMembers,
    );
  }

  /// Helper method to get the start of the week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Helper method to get team member by ID
  Future<TeamMember?> _getTeamMember(String memberId) async {
    final members = await storageService.loadTeamMembers();
    try {
      return members.firstWhere((m) => m.id == memberId);
    } catch (e) {
      return null;
    }
  }

  /// Get capacity utilization for a date range
  Future<Map<String, dynamic>> getCapacityUtilization(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final teamMembers = await storageService.loadTeamMembers();
    final assignments = await storageService.loadAssignments();

    final utilizationData = <String, dynamic>{};
    final overallStats = <String, dynamic>{
      'totalCapacity': 0.0,
      'utilizedCapacity': 0.0,
      'utilizationPercentage': 0.0,
      'memberCount': teamMembers.length,
    };

    double totalCapacity = 0.0;
    double utilizedCapacity = 0.0;

    for (final member in teamMembers) {
      if (!member.isActive) continue;

      final memberAssignments = assignments
          .where((a) => a.memberId == member.id)
          .where((a) => a.startWeek.isAfter(startDate.subtract(const Duration(days: 1))) &&
                       a.startWeek.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      final memberCapacity = member.weeklyCapacity;
      final memberUtilization = memberAssignments.fold(
        0.0,
        (sum, assignment) => sum + assignment.allocatedWeeks * 40.0, // Convert weeks to hours
      );

      totalCapacity += memberCapacity;
      utilizedCapacity += memberUtilization;

      utilizationData[member.id] = {
        'memberName': member.name,
        'capacity': memberCapacity,
        'utilization': memberUtilization,
        'utilizationPercentage': memberCapacity > 0 
            ? (memberUtilization / memberCapacity * 100).clamp(0.0, 100.0) 
            : 0.0,
        'assignments': memberAssignments.length,
      };
    }

    overallStats['totalCapacity'] = totalCapacity;
    overallStats['utilizedCapacity'] = utilizedCapacity;
    overallStats['utilizationPercentage'] = totalCapacity > 0 
        ? (utilizedCapacity / totalCapacity * 100).clamp(0.0, 100.0) 
        : 0.0;

    return {
      'overall': overallStats,
      'byMember': utilizationData,
      'dateRange': {
        'start': startDate.toIso8601String(),
        'end': endDate.toIso8601String(),
      },
    };
  }

  /// Validate capacity constraints for assignments
  Future<Map<String, dynamic>> validateCapacityConstraints(
    List<Assignment> proposedAssignments,
  ) async {
    final teamMembers = await storageService.loadTeamMembers();
    final existingAssignments = await storageService.loadAssignments();

    final violations = <Map<String, dynamic>>[];
    final warnings = <Map<String, dynamic>>[];
    bool isValid = true;

    for (final assignment in proposedAssignments) {
      final member = teamMembers.firstWhere(
        (m) => m.id == assignment.memberId,
        orElse: () => throw Exception('Team member not found: ${assignment.memberId}'),
      );

      if (!member.isActive) {
        violations.add({
          'type': 'inactive_member',
          'memberId': member.id,
          'memberName': member.name,
          'message': 'Cannot assign to inactive team member',
        });
        isValid = false;
        continue;
      }

      // Check for overlapping assignments in the same week
      final conflictingAssignments = existingAssignments
          .where((a) => a.memberId == assignment.memberId)
          .where((a) => a.startWeek.isAtSameMomentAs(assignment.startWeek))
          .toList();

      final totalWeeksForWeek = conflictingAssignments.fold(
        assignment.allocatedWeeks,
        (sum, a) => sum + a.allocatedWeeks,
      );

      if (totalWeeksForWeek > 1.0) {
        violations.add({
          'type': 'overallocation',
          'memberId': member.id,
          'memberName': member.name,
          'weekDate': assignment.startWeek.toIso8601String(),
          'allocatedWeeks': totalWeeksForWeek,
          'message': 'Member over-allocated for week (${totalWeeksForWeek.toStringAsFixed(2)} weeks)',
        });
        isValid = false;
      } else if (totalWeeksForWeek > 0.8) {
        warnings.add({
          'type': 'high_utilization',
          'memberId': member.id,
          'memberName': member.name,
          'weekDate': assignment.startWeek.toIso8601String(),
          'allocatedWeeks': totalWeeksForWeek,
          'message': 'High utilization for week (${totalWeeksForWeek.toStringAsFixed(2)} weeks)',
        });
      }
    }

    return {
      'isValid': isValid,
      'violations': violations,
      'warnings': warnings,
      'validatedAssignments': proposedAssignments.length,
    };
  }
}
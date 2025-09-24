import '../entities/team_member.dart';
import '../repositories/team_management_repository.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/enums/role.dart';

/// Use case for adding a new team member
class AddTeamMember {
  const AddTeamMember({
    required this.teamRepository,
  });

  final TeamManagementRepository teamRepository;

  Future<Result<TeamMember, Exception>> execute({
    required String name,
    required String email,
    required Set<Role> roles,
    required double weeklyCapacity,
    int skillLevel = 5,
    List<UnavailablePeriod> unavailablePeriods = const [],
    String notes = '',
    bool isActive = true,
  }) async {
    // Generate unique ID
    final memberId = 'member_${DateTime.now().millisecondsSinceEpoch}';

    // Create the team member
    final member = TeamMember(
      id: memberId,
      name: name,
      email: email,
      roles: roles,
      weeklyCapacity: weeklyCapacity,
      skillLevel: skillLevel,
      unavailablePeriods: unavailablePeriods,
      notes: notes,
      isActive: isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Validate the team member
    final validationResult = member.validate();
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Check for conflicts (duplicate email, etc.)
    final conflictResult = await teamRepository.checkMemberConflicts(member);
    if (conflictResult.isError) {
      return Result.error(conflictResult.error);
    }

    final conflicts = conflictResult.value;
    if (conflicts.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Team member conflicts detected',
          ValidationErrorType.duplicateName,
          {'conflicts': conflicts},
        ),
      );
    }

    // Save the team member
    final saveResult = await teamRepository.saveMember(member);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return Result.success(member);
  }
}

/// Use case for updating team member information
class UpdateTeamMember {
  const UpdateTeamMember({
    required this.teamRepository,
  });

  final TeamManagementRepository teamRepository;

  Future<Result<TeamMember, Exception>> execute({
    required String memberId,
    String? name,
    String? email,
    Set<Role>? roles,
    double? weeklyCapacity,
    int? skillLevel,
    List<UnavailablePeriod>? unavailablePeriods,
    String? notes,
    bool? isActive,
  }) async {
    // Load existing member
    final memberResult = await teamRepository.loadMember(memberId);
    if (memberResult.isError) {
      return Result.error(memberResult.error);
    }

    final existingMember = memberResult.value;
    if (existingMember == null) {
      return Result.error(
        ValidationException(
          'Team member not found: $memberId',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': ['Member does not exist']},
        ),
      );
    }

    // Create updated member
    final updatedMember = existingMember.copyWith(
      name: name,
      email: email,
      roles: roles,
      weeklyCapacity: weeklyCapacity,
      skillLevel: skillLevel,
      unavailablePeriods: unavailablePeriods,
      notes: notes,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );

    // Validate the updated member
    final validationResult = updatedMember.validate();
    if (validationResult.isError) {
      return Result.error(validationResult.error);
    }

    // Check for conflicts if email changed
    if (email != null && email != existingMember.email) {
      final conflictResult = await teamRepository.checkMemberConflicts(updatedMember);
      if (conflictResult.isError) {
        return Result.error(conflictResult.error);
      }

      final conflicts = conflictResult.value;
      if (conflicts.isNotEmpty) {
        return Result.error(
          ValidationException(
            'Team member conflicts detected',
            ValidationErrorType.duplicateName,
            {'conflicts': conflicts},
          ),
        );
      }
    }

    // Save the updated member
    final saveResult = await teamRepository.saveMember(updatedMember);
    if (saveResult.isError) {
      return Result.error(saveResult.error);
    }

    return Result.success(updatedMember);
  }
}

/// Use case for managing team member availability
class ManageTeamMemberAvailability {
  const ManageTeamMemberAvailability({
    required this.teamRepository,
  });

  final TeamManagementRepository teamRepository;

  /// Adds an unavailable period to a team member
  Future<Result<void, Exception>> addUnavailablePeriod({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String notes = '',
  }) async {
    // Validate dates
    if (startDate.isAfter(endDate)) {
      return Result.error(
        ValidationException(
          'Start date must be before or equal to end date',
          ValidationErrorType.invalidTimeRange,
          {'dates': ['Invalid date range']},
        ),
      );
    }

    // Load existing member
    final memberResult = await teamRepository.loadMember(memberId);
    if (memberResult.isError) {
      return Result.error(memberResult.error);
    }

    final member = memberResult.value;
    if (member == null) {
      return Result.error(
        ValidationException(
          'Team member not found: $memberId',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': ['Member does not exist']},
        ),
      );
    }

    // Create unavailable period
    final period = UnavailablePeriod(
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      notes: notes,
    );

    // Check for overlaps with existing periods
    for (final existingPeriod in member.unavailablePeriods) {
      if (_periodsOverlap(period, existingPeriod)) {
        return Result.error(
          ValidationException(
            'Unavailable period overlaps with existing period',
            ValidationErrorType.businessRuleViolation,
            {'period': ['Overlaps with existing unavailable period']},
          ),
        );
      }
    }

    // Add the period using repository
    final addResult = await teamRepository.addUnavailablePeriod(memberId, period);
    if (addResult.isError) {
      return Result.error(addResult.error);
    }

    return const Result.success(null);
  }

  /// Removes an unavailable period from a team member
  Future<Result<void, Exception>> removeUnavailablePeriod({
    required String memberId,
    required UnavailablePeriod period,
  }) async {
    // Load existing member to verify period exists
    final memberResult = await teamRepository.loadMember(memberId);
    if (memberResult.isError) {
      return Result.error(memberResult.error);
    }

    final member = memberResult.value;
    if (member == null) {
      return Result.error(
        ValidationException(
          'Team member not found: $memberId',
          ValidationErrorType.referentialIntegrityViolation,
          {'memberId': ['Member does not exist']},
        ),
      );
    }

    // Check if period exists
    final periodExists = member.unavailablePeriods.any(
      (p) => p.startDate == period.startDate && 
             p.endDate == period.endDate && 
             p.reason == period.reason,
    );

    if (!periodExists) {
      return Result.error(
        ValidationException(
          'Unavailable period not found',
          ValidationErrorType.referentialIntegrityViolation,
          {'period': ['Period does not exist']},
        ),
      );
    }

    // Remove the period using repository
    final removeResult = await teamRepository.removeUnavailablePeriod(memberId, period);
    if (removeResult.isError) {
      return Result.error(removeResult.error);
    }

    return const Result.success(null);
  }

  /// Checks if two unavailable periods overlap
  bool _periodsOverlap(UnavailablePeriod period1, UnavailablePeriod period2) {
    return period1.startDate.isBefore(period2.endDate) &&
           period2.startDate.isBefore(period1.endDate);
  }
}

/// Use case for analyzing team capacity and utilization
class AnalyzeTeamCapacity {
  const AnalyzeTeamCapacity({
    required this.teamRepository,
  });

  final TeamManagementRepository teamRepository;

  Future<Result<TeamCapacityAnalysis, Exception>> execute({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Validate date range
    if (startDate.isAfter(endDate)) {
      return Result.error(
        ValidationException(
          'Start date must be before or equal to end date',
          ValidationErrorType.invalidTimeRange,
          {'dates': ['Invalid date range']},
        ),
      );
    }

    // Get team statistics
    final statsResult = await teamRepository.getTeamStatistics();
    if (statsResult.isError) {
      return Result.error(statsResult.error);
    }

    // Get capacity summary for the date range
    final capacityResult = await teamRepository.getCapacitySummary(startDate, endDate);
    if (capacityResult.isError) {
      return Result.error(capacityResult.error);
    }

    // Get role distribution
    final roleDistResult = await teamRepository.getRoleDistribution();
    if (roleDistResult.isError) {
      return Result.error(roleDistResult.error);
    }

    final stats = statsResult.value;
    final capacitySummary = capacityResult.value;
    final roleDistribution = roleDistResult.value;

    // Create analysis
    final analysis = TeamCapacityAnalysis(
      dateRange: (startDate, endDate),
      teamStatistics: stats,
      capacitySummary: capacitySummary,
      roleDistribution: roleDistribution,
      recommendations: _generateRecommendations(stats, capacitySummary, roleDistribution),
    );

    return Result.success(analysis);
  }

  /// Generates recommendations based on team analysis
  List<String> _generateRecommendations(
    TeamStatistics stats,
    TeamCapacitySummary capacity,
    Map<Role, int> roleDistribution,
  ) {
    final recommendations = <String>[];

    // Check capacity utilization
    if (capacity.totalAvailableCapacity < 10.0) {
      recommendations.add('Low team capacity detected. Consider hiring additional team members.');
    }

    // Check role distribution
    for (final role in Role.values) {
      final count = roleDistribution[role] ?? 0;
      final (minRecommended, maxRecommended) = role.recommendedTeamSize;
      
      if (count < minRecommended) {
        recommendations.add(
          'Consider adding more ${role.displayName} team members (current: $count, recommended: $minRecommended-$maxRecommended).',
        );
      } else if (count > maxRecommended) {
        recommendations.add(
          'Consider balancing ${role.displayName} team members (current: $count, recommended: $minRecommended-$maxRecommended).',
        );
      }
    }

    // Check skill level distribution
    if (stats.averageSkillLevel < 4.0) {
      recommendations.add('Consider training programs to improve average team skill level.');
    } else if (stats.averageSkillLevel > 8.0) {
      recommendations.add('High-skilled team detected. Consider mentoring programs for knowledge sharing.');
    }

    // Check inactive members
    if (stats.inactiveMembers > stats.activeMembers * 0.2) {
      recommendations.add('High number of inactive members. Review team composition.');
    }

    return recommendations;
  }
}

/// Use case for searching and filtering team members
class SearchTeamMembers {
  const SearchTeamMembers({
    required this.teamRepository,
  });

  final TeamManagementRepository teamRepository;

  Future<Result<List<TeamMember>, Exception>> execute({
    String? searchQuery,
    Set<Role>? roleFilter,
    bool? activeOnly,
    int? minSkillLevel,
    int? maxSkillLevel,
  }) async {
    List<TeamMember> members;

    // Start with appropriate base list
    if (activeOnly == true) {
      final result = await teamRepository.listActiveMembers();
      if (result.isError) return Result.error(result.error);
      members = result.value;
    } else {
      final result = await teamRepository.listMembers();
      if (result.isError) return Result.error(result.error);
      members = result.value;
    }

    // Apply search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      members = members.where((member) =>
        member.name.toLowerCase().contains(query) ||
        member.email.toLowerCase().contains(query) ||
        member.notes.toLowerCase().contains(query)
      ).toList();
    }

    // Apply role filter
    if (roleFilter != null && roleFilter.isNotEmpty) {
      members = members.where((member) =>
        member.roles.any((role) => roleFilter.contains(role))
      ).toList();
    }

    // Apply skill level filter
    if (minSkillLevel != null) {
      members = members.where((member) => member.skillLevel >= minSkillLevel).toList();
    }

    if (maxSkillLevel != null) {
      members = members.where((member) => member.skillLevel <= maxSkillLevel).toList();
    }

    return Result.success(members);
  }
}

/// Analysis data for team capacity
class TeamCapacityAnalysis {
  const TeamCapacityAnalysis({
    required this.dateRange,
    required this.teamStatistics,
    required this.capacitySummary,
    required this.roleDistribution,
    required this.recommendations,
  });

  final (DateTime startDate, DateTime endDate) dateRange;
  final TeamStatistics teamStatistics;
  final TeamCapacitySummary capacitySummary;
  final Map<Role, int> roleDistribution;
  final List<String> recommendations;

  bool get hasRecommendations => recommendations.isNotEmpty;
  int get totalWeeks => dateRange.$2.difference(dateRange.$1).inDays ~/ 7;
}
import '../../domain/entities/team_member.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/enums/role.dart';

/// Repository interface for team management operations.
/// 
/// This repository handles persistence and retrieval of:
/// - Team members and their information
/// - Skill profiles and availability
/// - Role assignments and capabilities
abstract class TeamManagementRepository {
  /// Saves a team member
  Future<Result<void, StorageException>> saveMember(TeamMember member);

  /// Loads a team member by ID
  Future<Result<TeamMember?, StorageException>> loadMember(String memberId);

  /// Lists all team members
  Future<Result<List<TeamMember>, StorageException>> listMembers();

  /// Lists only active team members
  Future<Result<List<TeamMember>, StorageException>> listActiveMembers();

  /// Lists team members with specific role
  Future<Result<List<TeamMember>, StorageException>> listMembersByRole(Role role);

  /// Lists team members with any of the specified roles
  Future<Result<List<TeamMember>, StorageException>> listMembersByRoles(
    Set<Role> roles,
  );

  /// Deletes a team member by ID
  Future<Result<void, StorageException>> deleteMember(String memberId);

  /// Checks if a team member exists
  Future<Result<bool, StorageException>> memberExists(String memberId);

  /// Searches team members by name or email
  Future<Result<List<TeamMember>, StorageException>> searchMembers(
    String query,
  );

  /// Updates team member availability status
  Future<Result<void, StorageException>> updateMemberStatus(
    String memberId,
    bool isActive,
  );

  /// Adds an unavailable period to a team member
  Future<Result<void, StorageException>> addUnavailablePeriod(
    String memberId,
    UnavailablePeriod period,
  );

  /// Removes an unavailable period from a team member
  Future<Result<void, StorageException>> removeUnavailablePeriod(
    String memberId,
    UnavailablePeriod period,
  );

  /// Updates team member roles
  Future<Result<void, StorageException>> updateMemberRoles(
    String memberId,
    Set<Role> roles,
  );

  /// Updates team member capacity
  Future<Result<void, StorageException>> updateMemberCapacity(
    String memberId,
    double weeklyCapacity,
  );

  /// Updates team member skill level
  Future<Result<void, StorageException>> updateMemberSkillLevel(
    String memberId,
    int skillLevel,
  );

  /// Bulk operations
  /// Saves multiple team members at once
  Future<Result<void, StorageException>> saveMembers(
    List<TeamMember> members,
  );

  /// Gets team statistics
  Future<Result<TeamStatistics, StorageException>> getTeamStatistics();

  /// Gets capacity summary for a date range
  Future<Result<TeamCapacitySummary, StorageException>> getCapacitySummary(
    DateTime startDate,
    DateTime endDate,
  );

  /// Gets role distribution across the team
  Future<Result<Map<Role, int>, StorageException>> getRoleDistribution();

  /// Validates team member data before saving
  Future<Result<void, ValidationException>> validateMember(TeamMember member);

  /// Checks for conflicts (duplicate emails, etc.)
  Future<Result<List<String>, ValidationException>> checkMemberConflicts(
    TeamMember member,
  );

  /// Gets the last modified timestamp for team data
  Future<Result<DateTime?, StorageException>> getTeamLastModified();

  /// Backs up team data to a JSON string
  Future<Result<String, StorageException>> exportTeam();

  /// Restores team data from a JSON string
  Future<Result<void, StorageException>> importTeam(String jsonData);
}

/// Statistics about the team
class TeamStatistics {
  const TeamStatistics({
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.totalCapacity,
    required this.averageSkillLevel,
    required this.roleDistribution,
    required this.capacityDistribution,
  });

  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final double totalCapacity;
  final double averageSkillLevel;
  final Map<Role, int> roleDistribution;
  final Map<String, double> capacityDistribution; // capacity range -> count

  Map<String, dynamic> toMap() {
    return {
      'totalMembers': totalMembers,
      'activeMembers': activeMembers,
      'inactiveMembers': inactiveMembers,
      'totalCapacity': totalCapacity,
      'averageSkillLevel': averageSkillLevel,
      'roleDistribution': roleDistribution.map(
        (role, count) => MapEntry(role.name, count),
      ),
      'capacityDistribution': capacityDistribution,
    };
  }

  factory TeamStatistics.fromMap(Map<String, dynamic> map) {
    return TeamStatistics(
      totalMembers: map['totalMembers'] as int,
      activeMembers: map['activeMembers'] as int,
      inactiveMembers: map['inactiveMembers'] as int,
      totalCapacity: (map['totalCapacity'] as num).toDouble(),
      averageSkillLevel: (map['averageSkillLevel'] as num).toDouble(),
      roleDistribution: (map['roleDistribution'] as Map<String, dynamic>).map(
        (roleString, count) => MapEntry(
          Role.values.firstWhere((r) => r.name == roleString),
          count as int,
        ),
      ),
      capacityDistribution: Map<String, double>.from(
        map['capacityDistribution'] as Map<String, dynamic>,
      ),
    );
  }
}

/// Team capacity summary for a date range
class TeamCapacitySummary {
  const TeamCapacitySummary({
    required this.startDate,
    required this.endDate,
    required this.totalAvailableCapacity,
    required this.capacityByRole,
    required this.unavailableCapacity,
    required this.memberCapacities,
  });

  final DateTime startDate;
  final DateTime endDate;
  final double totalAvailableCapacity;
  final Map<Role, double> capacityByRole;
  final double unavailableCapacity;
  final Map<String, double> memberCapacities; // memberId -> available capacity

  double get netAvailableCapacity => totalAvailableCapacity - unavailableCapacity;

  Map<String, dynamic> toMap() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalAvailableCapacity': totalAvailableCapacity,
      'capacityByRole': capacityByRole.map(
        (role, capacity) => MapEntry(role.name, capacity),
      ),
      'unavailableCapacity': unavailableCapacity,
      'memberCapacities': memberCapacities,
    };
  }

  factory TeamCapacitySummary.fromMap(Map<String, dynamic> map) {
    return TeamCapacitySummary(
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      totalAvailableCapacity: (map['totalAvailableCapacity'] as num).toDouble(),
      capacityByRole: (map['capacityByRole'] as Map<String, dynamic>).map(
        (roleString, capacity) => MapEntry(
          Role.values.firstWhere((r) => r.name == roleString),
          (capacity as num).toDouble(),
        ),
      ),
      unavailableCapacity: (map['unavailableCapacity'] as num).toDouble(),
      memberCapacities: Map<String, double>.from(
        map['memberCapacities'] as Map<String, dynamic>,
      ),
    );
  }
}
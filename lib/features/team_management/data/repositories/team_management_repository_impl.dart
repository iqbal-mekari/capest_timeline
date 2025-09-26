import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/enums/role.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/repositories/team_management_repository.dart';

class TeamManagementRepositoryImpl implements TeamManagementRepository {
  final SharedPreferences _prefs;
  
  // Storage keys
  static const String _teamMembersKey = 'team_members';
  static const String _lastModifiedKey = 'team_last_modified';
  
  const TeamManagementRepositoryImpl(this._prefs);

  @override
  Future<Result<void, StorageException>> saveMember(TeamMember member) async {
    try {
      final membersResult = await _getTeamMembersMap();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final members = membersResult.value;
      members[member.id] = member.toMap();

      final success = await _prefs.setString(_teamMembersKey, jsonEncode(members));
      if (!success) {
        return Result.error(StorageException(
          'Failed to save team member',
          StorageErrorType.unknown,
        ));
      }

      await _updateLastModified();
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save team member: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<TeamMember?, StorageException>> loadMember(String memberId) async {
    try {
      final membersResult = await _getTeamMembersMap();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final memberData = membersResult.value[memberId];
      if (memberData == null) {
        return const Result.success(null);
      }

      final member = TeamMember.fromMap(memberData as Map<String, dynamic>);
      return Result.success(member);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load team member: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<List<TeamMember>, StorageException>> listMembers() async {
    try {
      final membersResult = await _getTeamMembersMap();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final members = membersResult.value.values
          .map((data) => TeamMember.fromMap(data as Map<String, dynamic>))
          .toList();

      return Result.success(members);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list team members: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  @override
  Future<Result<List<TeamMember>, StorageException>> listActiveMembers() async {
    try {
      final membersResult = await listMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final activeMembers = membersResult.value.where((m) => m.isActive).toList();
      return Result.success(activeMembers);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list active team members: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<List<TeamMember>, StorageException>> listMembersByRole(Role role) async {
    try {
      final membersResult = await listMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final roleMembers = membersResult.value
          .where((m) => m.roles.contains(role))
          .toList();
      return Result.success(roleMembers);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list members by role: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<List<TeamMember>, StorageException>> listMembersByRoles(Set<Role> roles) async {
    try {
      final membersResult = await listMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final matchingMembers = membersResult.value
          .where((m) => m.roles.any((role) => roles.contains(role)))
          .toList();
      return Result.success(matchingMembers);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to list members by roles: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> deleteMember(String memberId) async {
    try {
      final membersResult = await _getTeamMembersMap();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final members = membersResult.value;
      members.remove(memberId);

      final success = await _prefs.setString(_teamMembersKey, jsonEncode(members));
      if (!success) {
        return Result.error(StorageException(
          'Failed to delete team member',
          StorageErrorType.unknown,
        ));
      }

      await _updateLastModified();
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to delete team member: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<bool, StorageException>> memberExists(String memberId) async {
    try {
      final membersResult = await _getTeamMembersMap();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      return Result.success(membersResult.value.containsKey(memberId));
    } catch (e) {
      return Result.error(StorageException(
        'Failed to check team member existence: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<List<TeamMember>, StorageException>> searchMembers(String query) async {
    try {
      final membersResult = await listMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final queryLower = query.toLowerCase();
      final matchingMembers = membersResult.value.where((member) {
        return member.name.toLowerCase().contains(queryLower) ||
               member.email.toLowerCase().contains(queryLower) ||
               member.roles.any((role) => role.displayName.toLowerCase().contains(queryLower));
      }).toList();

      return Result.success(matchingMembers);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to search team members: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateMemberStatus(String memberId, bool isActive) async {
    try {
      final memberResult = await loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(memberResult.error);
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(StorageException(
          'Team member not found: $memberId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedMember = member.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      return await saveMember(updatedMember);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update member status: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> addUnavailablePeriod(
    String memberId,
    UnavailablePeriod period,
  ) async {
    try {
      final memberResult = await loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(memberResult.error);
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(StorageException(
          'Team member not found: $memberId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedPeriods = List<UnavailablePeriod>.from(member.unavailablePeriods);
      updatedPeriods.add(period);

      final updatedMember = member.copyWith(
        unavailablePeriods: updatedPeriods,
        updatedAt: DateTime.now(),
      );

      return await saveMember(updatedMember);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to add unavailable period: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> removeUnavailablePeriod(
    String memberId,
    UnavailablePeriod period,
  ) async {
    try {
      final memberResult = await loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(memberResult.error);
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(StorageException(
          'Team member not found: $memberId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedPeriods = member.unavailablePeriods
          .where((p) => p != period)
          .toList();

      final updatedMember = member.copyWith(
        unavailablePeriods: updatedPeriods,
        updatedAt: DateTime.now(),
      );

      return await saveMember(updatedMember);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to remove unavailable period: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateMemberRoles(
    String memberId,
    Set<Role> roles,
  ) async {
    try {
      final memberResult = await loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(memberResult.error);
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(StorageException(
          'Team member not found: $memberId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedMember = member.copyWith(
        roles: roles,
        updatedAt: DateTime.now(),
      );

      return await saveMember(updatedMember);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update member roles: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateMemberCapacity(
    String memberId,
    double weeklyCapacity,
  ) async {
    try {
      final memberResult = await loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(memberResult.error);
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(StorageException(
          'Team member not found: $memberId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedMember = member.copyWith(
        weeklyCapacity: weeklyCapacity,
        updatedAt: DateTime.now(),
      );

      return await saveMember(updatedMember);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update member capacity: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> updateMemberSkillLevel(
    String memberId,
    int skillLevel,
  ) async {
    try {
      final memberResult = await loadMember(memberId);
      if (memberResult.isError) {
        return Result.error(memberResult.error);
      }

      final member = memberResult.value;
      if (member == null) {
        return Result.error(StorageException(
          'Team member not found: $memberId',
          StorageErrorType.dataCorrupted,
        ));
      }

      final updatedMember = member.copyWith(
        skillLevel: skillLevel,
        updatedAt: DateTime.now(),
      );

      return await saveMember(updatedMember);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to update member skill level: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> saveMembers(List<TeamMember> members) async {
    try {
      final membersMap = <String, dynamic>{};
      for (final member in members) {
        membersMap[member.id] = member.toMap();
      }

      final success = await _prefs.setString(_teamMembersKey, jsonEncode(membersMap));
      if (!success) {
        return Result.error(StorageException(
          'Failed to save team members',
          StorageErrorType.unknown,
        ));
      }

      await _updateLastModified();
      return const Result.success(null);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to save team members: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<TeamStatistics, StorageException>> getTeamStatistics() async {
    try {
      final membersResult = await listMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final members = membersResult.value;
      final activeMembers = members.where((m) => m.isActive).toList();
      
      // Calculate role distribution
      final roleDistribution = <Role, int>{};
      for (final member in activeMembers) {
        for (final role in member.roles) {
          roleDistribution[role] = (roleDistribution[role] ?? 0) + 1;
        }
      }

      // Calculate capacity distribution
      final capacityDistribution = <String, double>{};
      for (final member in activeMembers) {
        final capacity = member.weeklyCapacity;
        String range;
        if (capacity <= 0.25) {
          range = '0-25%';
        } else if (capacity <= 0.5) {
          range = '26-50%';
        } else if (capacity <= 0.75) {
          range = '51-75%';
        } else {
          range = '76-100%';
        }
        
        capacityDistribution[range] = (capacityDistribution[range] ?? 0) + 1;
      }

      final statistics = TeamStatistics(
        totalMembers: members.length,
        activeMembers: activeMembers.length,
        inactiveMembers: members.length - activeMembers.length,
        totalCapacity: activeMembers.fold(0.0, (sum, m) => sum + m.weeklyCapacity),
        averageSkillLevel: activeMembers.isNotEmpty
            ? activeMembers.fold(0.0, (sum, m) => sum + m.skillLevel) / activeMembers.length
            : 0.0,
        roleDistribution: roleDistribution,
        capacityDistribution: capacityDistribution,
      );

      return Result.success(statistics);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get team statistics: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<TeamCapacitySummary, StorageException>> getCapacitySummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final membersResult = await listActiveMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final members = membersResult.value;
      
      // Calculate capacity by role and member
      final capacityByRole = <Role, double>{};
      final memberCapacities = <String, double>{};
      var totalAvailableCapacity = 0.0;
      var unavailableCapacity = 0.0;

      for (final member in members) {
        final availableCapacity = member.calculateAvailableCapacity(startDate, endDate);
        final totalCapacity = (endDate.difference(startDate).inDays / 7.0) * member.weeklyCapacity;
        
        memberCapacities[member.id] = availableCapacity;
        totalAvailableCapacity += totalCapacity;
        unavailableCapacity += (totalCapacity - availableCapacity);

        // Distribute capacity across roles
        final capacityPerRole = availableCapacity / member.roles.length;
        for (final role in member.roles) {
          capacityByRole[role] = (capacityByRole[role] ?? 0) + capacityPerRole;
        }
      }

      final summary = TeamCapacitySummary(
        startDate: startDate,
        endDate: endDate,
        totalAvailableCapacity: totalAvailableCapacity,
        capacityByRole: capacityByRole,
        unavailableCapacity: unavailableCapacity,
        memberCapacities: memberCapacities,
      );

      return Result.success(summary);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get capacity summary: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<Map<Role, int>, StorageException>> getRoleDistribution() async {
    try {
      final statsResult = await getTeamStatistics();
      if (statsResult.isError) {
        return Result.error(statsResult.error);
      }

      return Result.success(statsResult.value.roleDistribution);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get role distribution: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, ValidationException>> validateMember(TeamMember member) async {
    return member.validate();
  }

  @override
  Future<Result<List<String>, ValidationException>> checkMemberConflicts(TeamMember member) async {
    try {
      final membersResult = await listMembers();
      if (membersResult.isError) {
        return Result.error(ValidationException(
          'Failed to check member conflicts',
          ValidationErrorType.referentialIntegrityViolation,
        ));
      }

      final conflicts = <String>[];
      final existingMembers = membersResult.value.where((m) => m.id != member.id);

      // Check for duplicate email
      for (final existing in existingMembers) {
        if (existing.email.toLowerCase() == member.email.toLowerCase()) {
          conflicts.add('Email address already exists: ${member.email}');
          break;
        }
      }

      return Result.success(conflicts);
    } catch (e) {
      return Result.error(ValidationException(
        'Failed to check member conflicts: $e',
        ValidationErrorType.referentialIntegrityViolation,
      ));
    }
  }

  @override
  Future<Result<DateTime?, StorageException>> getTeamLastModified() async {
    try {
      final timestampString = _prefs.getString(_lastModifiedKey);
      if (timestampString == null) {
        return const Result.success(null);
      }

      final timestamp = DateTime.parse(timestampString);
      return Result.success(timestamp);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to get team last modified: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<String, StorageException>> exportTeam() async {
    try {
      final membersResult = await listMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }

      final exportData = {
        'teamMembers': membersResult.value.map((m) => m.toMap()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };

      final jsonString = jsonEncode(exportData);
      return Result.success(jsonString);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to export team: $e',
        StorageErrorType.unknown,
      ));
    }
  }

  @override
  Future<Result<void, StorageException>> importTeam(String jsonData) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      final List<dynamic> membersList = importData['teamMembers'] as List<dynamic>;
      
      final members = membersList
          .map((data) => TeamMember.fromMap(data as Map<String, dynamic>))
          .toList();

      return await saveMembers(members);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to import team: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  // Private helper methods
  Future<Result<Map<String, dynamic>, StorageException>> _getTeamMembersMap() async {
    try {
      final jsonString = _prefs.getString(_teamMembersKey);
      if (jsonString == null) {
        return const Result.success({});
      }

      final Map<String, dynamic> members = jsonDecode(jsonString);
      return Result.success(members);
    } catch (e) {
      return Result.error(StorageException(
        'Failed to load team members map: $e',
        StorageErrorType.dataCorrupted,
      ));
    }
  }

  Future<void> _updateLastModified() async {
    try {
      await _prefs.setString(_lastModifiedKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Last modified update failure is not critical
    }
  }
}
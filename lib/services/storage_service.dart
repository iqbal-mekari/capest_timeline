import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Service for handling data persistence using SharedPreferences
class StorageService {
  const StorageService({
    required this.sharedPreferences,
  });

  final SharedPreferences sharedPreferences;

  // Storage keys
  static const String _keyInitiatives = 'kanban_initiatives';
  static const String _keyPlatformVariants = 'kanban_platform_variants';
  static const String _keyTeamMembers = 'kanban_team_members';
  static const String _keyAssignments = 'kanban_assignments';
  static const String _keyKanbanState = 'kanban_state';

  /// Save complete kanban state to storage
  Future<void> saveKanbanState(Map<String, dynamic> kanbanState) async {
    // Validate required keys exist
    if (!kanbanState.containsKey('initiatives') ||
        !kanbanState.containsKey('platformVariants') ||
        !kanbanState.containsKey('teamMembers') ||
        !kanbanState.containsKey('assignments')) {
      throw ArgumentError('KanbanState must contain initiatives, platformVariants, teamMembers, and assignments');
    }

    // Store each component separately for individual access
    await sharedPreferences.setString(
      _keyInitiatives, 
      jsonEncode(kanbanState['initiatives']),
    );
    await sharedPreferences.setString(
      _keyPlatformVariants, 
      jsonEncode(kanbanState['platformVariants']),
    );
    await sharedPreferences.setString(
      _keyTeamMembers, 
      jsonEncode(kanbanState['teamMembers']),
    );
    await sharedPreferences.setString(
      _keyAssignments, 
      jsonEncode(kanbanState['assignments']),
    );

    // Store complete state with timestamp
    final stateWithTimestamp = {
      ...kanbanState,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await sharedPreferences.setString(_keyKanbanState, jsonEncode(stateWithTimestamp));
  }

  /// Load complete kanban state from storage
  Future<Map<String, dynamic>?> loadKanbanState() async {
    final stateString = sharedPreferences.getString(_keyKanbanState);
    if (stateString == null) return null;
    
    try {
      final stateMap = jsonDecode(stateString) as Map<String, dynamic>;
      return stateMap;
    } catch (e) {
      return null;
    }
  }

  /// Save initiative to storage
  Future<void> saveInitiative(Initiative initiative) async {
    final initiatives = await loadInitiatives();
    final index = initiatives.indexWhere((i) => i.id == initiative.id);
    
    if (index >= 0) {
      initiatives[index] = initiative;
    } else {
      initiatives.add(initiative);
    }

    final jsonList = initiatives.map((i) => i.toJson()).toList();
    await sharedPreferences.setString(_keyInitiatives, jsonEncode(jsonList));
  }

  /// Load all initiatives from storage
  Future<List<Initiative>> loadInitiatives() async {
    final jsonString = sharedPreferences.getString(_keyInitiatives);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Initiative.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save platform variant to storage
  Future<void> savePlatformVariant(PlatformVariant variant) async {
    final variants = await loadPlatformVariants();
    final index = variants.indexWhere((v) => v.id == variant.id);
    
    if (index >= 0) {
      variants[index] = variant;
    } else {
      variants.add(variant);
    }

    final jsonList = variants.map((v) => v.toJson()).toList();
    await sharedPreferences.setString(_keyPlatformVariants, jsonEncode(jsonList));
  }

  /// Load all platform variants from storage
  Future<List<PlatformVariant>> loadPlatformVariants() async {
    final jsonString = sharedPreferences.getString(_keyPlatformVariants);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => PlatformVariant.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save team member to storage
  Future<void> saveTeamMember(TeamMember member) async {
    final members = await loadTeamMembers();
    final index = members.indexWhere((m) => m.id == member.id);
    
    if (index >= 0) {
      members[index] = member;
    } else {
      members.add(member);
    }

    final jsonList = members.map((m) => m.toJson()).toList();
    await sharedPreferences.setString(_keyTeamMembers, jsonEncode(jsonList));
  }

  /// Load all team members from storage
  Future<List<TeamMember>> loadTeamMembers() async {
    final jsonString = sharedPreferences.getString(_keyTeamMembers);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => TeamMember.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save assignment to storage
  Future<void> saveAssignment(Assignment assignment) async {
    final assignments = await loadAssignments();
    final index = assignments.indexWhere((a) => a.id == assignment.id);
    
    if (index >= 0) {
      assignments[index] = assignment;
    } else {
      assignments.add(assignment);
    }

    final jsonList = assignments.map((a) => a.toJson()).toList();
    await sharedPreferences.setString(_keyAssignments, jsonEncode(jsonList));
  }

  /// Load all assignments from storage
  Future<List<Assignment>> loadAssignments() async {
    final jsonString = sharedPreferences.getString(_keyAssignments);
    if (jsonString == null) return [];
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => Assignment.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all stored data
  Future<void> clearAllData() async {
    await Future.wait([
      sharedPreferences.remove(_keyInitiatives),
      sharedPreferences.remove(_keyPlatformVariants),
      sharedPreferences.remove(_keyTeamMembers),
      sharedPreferences.remove(_keyAssignments),
      sharedPreferences.remove(_keyKanbanState),
    ]);
  }

  /// Delete initiative from storage
  Future<void> deleteInitiative(String initiativeId) async {
    final initiatives = await loadInitiatives();
    initiatives.removeWhere((i) => i.id == initiativeId);
    
    final jsonList = initiatives.map((i) => i.toJson()).toList();
    await sharedPreferences.setString(_keyInitiatives, jsonEncode(jsonList));
  }

  /// Delete assignment from storage
  Future<void> deleteAssignment(String assignmentId) async {
    final assignments = await loadAssignments();
    assignments.removeWhere((a) => a.id == assignmentId);
    
    final jsonList = assignments.map((a) => a.toJson()).toList();
    await sharedPreferences.setString(_keyAssignments, jsonEncode(jsonList));
  }

  /// Get last updated timestamp
  Future<DateTime?> getLastUpdated() async {
    final stateJson = sharedPreferences.getString(_keyKanbanState);
    if (stateJson == null) return null;
    
    try {
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      final lastUpdatedStr = state['lastUpdated'] as String?;
      return lastUpdatedStr != null ? DateTime.parse(lastUpdatedStr) : null;
    } catch (e) {
      return null;
    }
  }
}
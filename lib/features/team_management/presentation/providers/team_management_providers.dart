/// UI state management using ChangeNotifier for team management features.
/// 
/// This file contains ChangeNotifier classes that manage UI state for
/// team management screens and components.
library;

import 'package:flutter/foundation.dart';

// Core imports
import '../../../../core/enums/role.dart';

// Domain entities
import '../../domain/entities/team_member.dart';

// Use cases
import '../../domain/usecases/team_management_usecases.dart';

/// State management for team member operations
class TeamMemberProvider extends ChangeNotifier {
  TeamMemberProvider({
    required AddTeamMember addTeamMember,
    required UpdateTeamMember updateTeamMember,
    required SearchTeamMembers searchTeamMembers,
  }) : _addTeamMember = addTeamMember,
       _updateTeamMember = updateTeamMember,
       _searchTeamMembers = searchTeamMembers;

  final AddTeamMember _addTeamMember;
  final UpdateTeamMember _updateTeamMember;
  final SearchTeamMembers _searchTeamMembers;

  // State variables
  List<TeamMember> _teamMembers = [];
  List<TeamMember> _filteredMembers = [];
  bool _isLoading = false;
  String? _error;
  TeamMember? _selectedMember;
  
  // Search and filter state
  String _searchQuery = '';
  Set<Role> _roleFilter = {};
  bool _activeOnly = true;
  int? _minSkillLevel;
  int? _maxSkillLevel;

  // Getters
  List<TeamMember> get teamMembers => _filteredMembers;
  List<TeamMember> get allMembers => _teamMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  TeamMember? get selectedMember => _selectedMember;
  
  // Filter getters
  String get searchQuery => _searchQuery;
  Set<Role> get roleFilter => _roleFilter;
  bool get activeOnly => _activeOnly;
  int? get minSkillLevel => _minSkillLevel;
  int? get maxSkillLevel => _maxSkillLevel;
  bool get hasActiveFilters => _searchQuery.isNotEmpty || 
                               _roleFilter.isNotEmpty || 
                               _minSkillLevel != null || 
                               _maxSkillLevel != null;

  /// Adds a new team member
  Future<bool> addMember({
    required String name,
    required String email,
    required Set<Role> roles,
    required double weeklyCapacity,
    int skillLevel = 5,
    List<UnavailablePeriod> unavailablePeriods = const [],
    String notes = '',
    bool isActive = true,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _addTeamMember.execute(
      name: name,
      email: email,
      roles: roles,
      weeklyCapacity: weeklyCapacity,
      skillLevel: skillLevel,
      unavailablePeriods: unavailablePeriods,
      notes: notes,
      isActive: isActive,
    );

    if (result.isSuccess) {
      _teamMembers.add(result.value);
      await _applyFilters();
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Updates an existing team member
  Future<bool> updateMember({
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
    _setLoading(true);
    _clearError();

    final result = await _updateTeamMember.execute(
      memberId: memberId,
      name: name,
      email: email,
      roles: roles,
      weeklyCapacity: weeklyCapacity,
      skillLevel: skillLevel,
      unavailablePeriods: unavailablePeriods,
      notes: notes,
      isActive: isActive,
    );

    if (result.isSuccess) {
      final index = _teamMembers.indexWhere((m) => m.id == memberId);
      if (index != -1) {
        _teamMembers[index] = result.value;
        if (_selectedMember?.id == memberId) {
          _selectedMember = result.value;
        }
        await _applyFilters();
      }
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Searches team members with current filters
  Future<void> searchMembers() async {
    _setLoading(true);
    _clearError();

    final result = await _searchTeamMembers.execute(
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      roleFilter: _roleFilter.isNotEmpty ? _roleFilter : null,
      activeOnly: _activeOnly,
      minSkillLevel: _minSkillLevel,
      maxSkillLevel: _maxSkillLevel,
    );

    if (result.isSuccess) {
      _teamMembers = result.value;
      _filteredMembers = result.value;
      _setLoading(false);
    } else {
      _setError(result.error.toString());
      _setLoading(false);
    }
  }

  /// Updates search query
  Future<void> updateSearchQuery(String query) async {
    _searchQuery = query;
    await _applyFilters();
  }

  /// Updates role filter
  Future<void> updateRoleFilter(Set<Role> roles) async {
    _roleFilter = roles;
    await _applyFilters();
  }

  /// Toggles active only filter
  Future<void> toggleActiveOnly(bool activeOnly) async {
    _activeOnly = activeOnly;
    await _applyFilters();
  }

  /// Updates skill level range filter
  Future<void> updateSkillLevelRange(int? minLevel, int? maxLevel) async {
    _minSkillLevel = minLevel;
    _maxSkillLevel = maxLevel;
    await _applyFilters();
  }

  /// Clears all filters
  Future<void> clearFilters() async {
    _searchQuery = '';
    _roleFilter = {};
    _activeOnly = true;
    _minSkillLevel = null;
    _maxSkillLevel = null;
    await _applyFilters();
  }

  /// Selects a team member
  void selectMember(TeamMember? member) {
    _selectedMember = member;
    notifyListeners();
  }

  /// Refreshes the team member list
  Future<void> refresh() async {
    await searchMembers();
  }

  /// Applies current filters to the team member list
  Future<void> _applyFilters() async {
    await searchMembers();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

/// State management for team availability operations
class AvailabilityProvider extends ChangeNotifier {
  AvailabilityProvider({
    required ManageTeamMemberAvailability manageAvailability,
  }) : _manageAvailability = manageAvailability;

  final ManageTeamMemberAvailability _manageAvailability;

  // State variables
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Adds an unavailable period to a team member
  Future<bool> addUnavailablePeriod({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String notes = '',
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _manageAvailability.addUnavailablePeriod(
      memberId: memberId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      notes: notes,
    );

    if (result.isSuccess) {
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Removes an unavailable period from a team member
  Future<bool> removeUnavailablePeriod({
    required String memberId,
    required UnavailablePeriod period,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _manageAvailability.removeUnavailablePeriod(
      memberId: memberId,
      period: period,
    );

    if (result.isSuccess) {
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

/// State management for team capacity analysis
class TeamCapacityProvider extends ChangeNotifier {
  TeamCapacityProvider({
    required AnalyzeTeamCapacity analyzeCapacity,
  }) : _analyzeCapacity = analyzeCapacity;

  final AnalyzeTeamCapacity _analyzeCapacity;

  // State variables
  TeamCapacityAnalysis? _analysis;
  bool _isLoading = false;
  String? _error;
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  // Getters
  TeamCapacityAnalysis? get analysis => _analysis;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasAnalysis => _analysis != null;
  DateTime? get currentStartDate => _currentStartDate;
  DateTime? get currentEndDate => _currentEndDate;

  /// Analyzes team capacity for a date range
  Future<bool> analyzeCapacity({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _analyzeCapacity.execute(
      startDate: startDate,
      endDate: endDate,
    );

    if (result.isSuccess) {
      _analysis = result.value;
      _currentStartDate = startDate;
      _currentEndDate = endDate;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Refreshes the current analysis
  Future<void> refresh() async {
    if (_currentStartDate != null && _currentEndDate != null) {
      await analyzeCapacity(
        startDate: _currentStartDate!,
        endDate: _currentEndDate!,
      );
    }
  }

  /// Clears the current analysis
  void clearAnalysis() {
    _analysis = null;
    _currentStartDate = null;
    _currentEndDate = null;
    _clearError();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
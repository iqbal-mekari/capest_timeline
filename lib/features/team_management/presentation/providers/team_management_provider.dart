import 'package:flutter/foundation.dart';

import '../../../../core/enums/role.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/team_member.dart';
import '../../domain/usecases/team_management_usecases.dart';

/// Main provider for team management operations.
/// 
/// This provider handles:
/// - Team member CRUD operations
/// - Team member search and filtering
/// - Availability management
/// - Team capacity analysis
/// - Form state management for team member dialogs
class TeamManagementProvider extends ChangeNotifier {
  TeamManagementProvider({
    required AddTeamMember addTeamMember,
    required UpdateTeamMember updateTeamMember,
    required SearchTeamMembers searchTeamMembers,
    required ManageTeamMemberAvailability manageAvailability,
    required AnalyzeTeamCapacity analyzeCapacity,
  }) : _addTeamMember = addTeamMember,
       _updateTeamMember = updateTeamMember,
       _searchTeamMembers = searchTeamMembers,
       _manageAvailability = manageAvailability,
       _analyzeCapacity = analyzeCapacity;

  final AddTeamMember _addTeamMember;
  final UpdateTeamMember _updateTeamMember;
  final SearchTeamMembers _searchTeamMembers;
  final ManageTeamMemberAvailability _manageAvailability;
  final AnalyzeTeamCapacity _analyzeCapacity;

  // State variables
  List<TeamMember> _teamMembers = [];
  List<TeamMember> _filteredMembers = [];
  bool _isLoading = false;
  String? _error;
  TeamMember? _selectedMember;
  TeamCapacityAnalysis? _capacityAnalysis;
  
  // Search and filter state
  String _searchQuery = '';
  Set<Role> _roleFilter = {};
  bool _activeOnly = true;
  int? _minSkillLevel;
  int? _maxSkillLevel;

  // Form state for add/edit dialogs
  bool _isFormLoading = false;
  Map<String, String> _formErrors = {};

  // Getters
  List<TeamMember> get teamMembers => _filteredMembers;
  List<TeamMember> get allMembers => List.unmodifiable(_teamMembers);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  TeamMember? get selectedMember => _selectedMember;
  TeamCapacityAnalysis? get capacityAnalysis => _capacityAnalysis;
  
  // Filter getters
  String get searchQuery => _searchQuery;
  Set<Role> get roleFilter => Set.unmodifiable(_roleFilter);
  bool get activeOnly => _activeOnly;
  int? get minSkillLevel => _minSkillLevel;
  int? get maxSkillLevel => _maxSkillLevel;
  bool get hasActiveFilters => _searchQuery.isNotEmpty || 
                               _roleFilter.isNotEmpty || 
                               _minSkillLevel != null || 
                               _maxSkillLevel != null;

  // Form state getters
  bool get isFormLoading => _isFormLoading;
  Map<String, String> get formErrors => Map.unmodifiable(_formErrors);
  bool get hasFormErrors => _formErrors.isNotEmpty;

  /// Loads all team members
  Future<void> loadTeamMembers() async {
    _setLoading(true);
    _clearError();

    final result = await _searchTeamMembers.execute(
      searchQuery: null,
      roleFilter: null,
      activeOnly: null,
    );

    if (result.isSuccess) {
      _teamMembers = result.value;
      await _applyFilters();
      _setLoading(false);
    } else {
      _setError(result.error.toString());
      _setLoading(false);
    }
  }

  /// Adds a new team member
  Future<bool> addTeamMember({
    required String name,
    required String email,
    required Set<Role> roles,
    required double weeklyCapacity,
    int skillLevel = 5,
    List<UnavailablePeriod> unavailablePeriods = const [],
    String notes = '',
    bool isActive = true,
  }) async {
    _setFormLoading(true);
    _clearFormErrors();

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
      _setFormLoading(false);
      return true;
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
      return false;
    }
  }

  /// Updates an existing team member
  Future<bool> updateTeamMember({
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
    _setFormLoading(true);
    _clearFormErrors();

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
      _setFormLoading(false);
      return true;
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
      return false;
    }
  }

  /// Searches team members with current filters
  Future<void> searchTeamMembers() async {
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

  /// Updates search query and applies filters
  Future<void> updateSearchQuery(String query) async {
    _searchQuery = query;
    await _applyFilters();
  }

  /// Updates role filter and applies filters
  Future<void> updateRoleFilter(Set<Role> roles) async {
    _roleFilter = roles;
    await _applyFilters();
  }

  /// Toggles active only filter and applies filters
  Future<void> toggleActiveOnly(bool activeOnly) async {
    _activeOnly = activeOnly;
    await _applyFilters();
  }

  /// Updates skill level range filter and applies filters
  Future<void> updateSkillLevelRange(int? minLevel, int? maxLevel) async {
    _minSkillLevel = minLevel;
    _maxSkillLevel = maxLevel;
    await _applyFilters();
  }

  /// Clears all filters and reloads data
  Future<void> clearFilters() async {
    _searchQuery = '';
    _roleFilter = {};
    _activeOnly = true;
    _minSkillLevel = null;
    _maxSkillLevel = null;
    await _applyFilters();
  }

  /// Selects a team member
  void selectTeamMember(TeamMember? member) {
    _selectedMember = member;
    notifyListeners();
  }

  /// Adds an unavailable period to a team member
  Future<bool> addUnavailablePeriod({
    required String memberId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    String notes = '',
  }) async {
    _setFormLoading(true);
    _clearFormErrors();

    final result = await _manageAvailability.addUnavailablePeriod(
      memberId: memberId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      notes: notes,
    );

    if (result.isSuccess) {
      // Refresh the team member data since availability changed
      await loadTeamMembers();
      _setFormLoading(false);
      return true;
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
      return false;
    }
  }

  /// Removes an unavailable period from a team member
  Future<bool> removeUnavailablePeriod({
    required String memberId,
    required UnavailablePeriod period,
  }) async {
    _setFormLoading(true);
    _clearFormErrors();

    final result = await _manageAvailability.removeUnavailablePeriod(
      memberId: memberId,
      period: period,
    );

    if (result.isSuccess) {
      // Refresh the team member data since availability changed
      await loadTeamMembers();
      _setFormLoading(false);
      return true;
    } else {
      _handleFormValidationError(result.error);
      _setFormLoading(false);
      return false;
    }
  }

  /// Analyzes team capacity for a date range
  Future<bool> analyzeTeamCapacity({
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
      _capacityAnalysis = result.value;
      _setLoading(false);
      return true;
    } else {
      _setError(result.error.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Clears the current capacity analysis
  void clearCapacityAnalysis() {
    _capacityAnalysis = null;
    notifyListeners();
  }

  /// Refreshes the team member list
  Future<void> refresh() async {
    await loadTeamMembers();
  }

  /// Applies current filters to the team member list
  Future<void> _applyFilters() async {
    await searchTeamMembers();
  }

  /// Handles form validation errors
  void _handleFormValidationError(Exception error) {
    _formErrors.clear();
    
    if (error is ValidationException) {
      if (error.fieldErrors.isNotEmpty) {
        _formErrors.addAll(error.fieldErrors.map(
          (key, value) => MapEntry(key, value.join(', '))
        ));
      } else {
        _formErrors['general'] = error.message;
      }
    } else {
      _formErrors['general'] = error.toString();
    }
    
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setFormLoading(bool loading) {
    _isFormLoading = loading;
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

  void _clearFormErrors() {
    _formErrors.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _teamMembers.clear();
    _filteredMembers.clear();
    _formErrors.clear();
    super.dispose();
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/capacity_allocation.dart';
import '../../domain/entities/initiative.dart';
import '../../domain/entities/quarter_plan.dart';
import '../../../team_management/domain/entities/team_member.dart';
import '../widgets/drag_drop_allocation_widget.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';

/// State management provider for capacity planning operations.
/// 
/// This provider handles:
/// - Quarter plan state management
/// - Drag and drop operations
/// - Real-time validation and conflict detection
/// - Allocation CRUD operations
/// - Undo/redo functionality
class CapacityPlanningProvider extends ChangeNotifier {
  CapacityPlanningProvider({
    QuarterPlan? initialPlan,
  }) : _currentPlan = initialPlan;

  QuarterPlan? _currentPlan;
  QuarterPlan? _planBeforeChanges;
  
  // Drag and drop state
  bool _isDragInProgress = false;
  AllocationDragData? _currentDragData;
  List<String> _validDropTargets = [];
  Map<String, List<ValidationException>> _dragValidationErrors = {};
  
  // Selection state
  Set<String> _selectedAllocationIds = {};
  
  // Undo/redo state
  final List<QuarterPlan> _undoStack = [];
  final List<QuarterPlan> _redoStack = [];
  static const int _maxUndoStackSize = 20;

  // Getters
  QuarterPlan? get currentPlan => _currentPlan;
  bool get isDragInProgress => _isDragInProgress;
  AllocationDragData? get currentDragData => _currentDragData;
  List<String> get validDropTargets => List.unmodifiable(_validDropTargets);
  Set<String> get selectedAllocationIds => Set.unmodifiable(_selectedAllocationIds);
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get hasUnsavedChanges => _planBeforeChanges != null;

  /// Sets the current quarter plan
  void setQuarterPlan(QuarterPlan plan) {
    _saveToUndoStack();
    _currentPlan = plan;
    _planBeforeChanges ??= plan;
    notifyListeners();
  }

  /// Creates a new quarter plan
  Result<void, ValidationException> createQuarterPlan(QuarterPlan plan) {
    final validation = plan.validate();
    if (validation.isError) {
      return validation;
    }

    _saveToUndoStack();
    _currentPlan = plan;
    _planBeforeChanges = null; // New plan, no unsaved changes
    _clearSelection();
    notifyListeners();
    
    return const Result.success(null);
  }

  /// Adds an initiative to the current plan
  Result<void, ValidationException> addInitiative(Initiative initiative) {
    if (_currentPlan == null) {
      return Result.error(ValidationException(
        'No quarter plan loaded',
        ValidationErrorType.missingRequiredField,
      ));
    }

    final validation = initiative.validate();
    if (validation.isError) {
      return validation;
    }

    // Check for duplicate names
    final existingNames = _currentPlan!.initiatives.map((i) => i.name.toLowerCase());
    if (existingNames.contains(initiative.name.toLowerCase())) {
      return Result.error(ExceptionFactory.duplicateName('Initiative', initiative.name));
    }

    _saveToUndoStack();
    final updatedInitiatives = [..._currentPlan!.initiatives, initiative];
    _currentPlan = _currentPlan!.copyWith(initiatives: updatedInitiatives);
    _markAsChanged();
    notifyListeners();
    
    return const Result.success(null);
  }

  /// Adds a team member to the current plan
  Result<void, ValidationException> addTeamMember(TeamMember teamMember) {
    if (_currentPlan == null) {
      return Result.error(ValidationException(
        'No quarter plan loaded',
        ValidationErrorType.missingRequiredField,
      ));
    }

    final validation = teamMember.validate();
    if (validation.isError) {
      return validation;
    }

    // Check for duplicate names or emails
    final existing = _currentPlan!.teamMembers;
    if (existing.any((m) => m.name.toLowerCase() == teamMember.name.toLowerCase())) {
      return Result.error(ExceptionFactory.duplicateName('Team member', teamMember.name));
    }
    if (existing.any((m) => m.email.toLowerCase() == teamMember.email.toLowerCase())) {
      return Result.error(ValidationException(
        'Team member with email "${teamMember.email}" already exists',
        ValidationErrorType.duplicateName,
      ));
    }

    _saveToUndoStack();
    final updatedMembers = [..._currentPlan!.teamMembers, teamMember];
    _currentPlan = _currentPlan!.copyWith(teamMembers: updatedMembers);
    _markAsChanged();
    notifyListeners();
    
    return const Result.success(null);
  }

  /// Creates a new capacity allocation
  Result<void, ValidationException> createAllocation(CapacityAllocation allocation) {
    if (_currentPlan == null) {
      return Result.error(ValidationException(
        'No quarter plan loaded',
        ValidationErrorType.missingRequiredField,
      ));
    }

    final validation = allocation.validate();
    if (validation.isError) {
      return validation;
    }

    // Validate business rules
    final businessValidation = _validateAllocationBusinessRules(allocation);
    if (businessValidation.isError) {
      return businessValidation;
    }

    _saveToUndoStack();
    final updatedAllocations = [..._currentPlan!.allocations, allocation];
    _currentPlan = _currentPlan!.copyWith(allocations: updatedAllocations);
    _markAsChanged();
    notifyListeners();
    
    return const Result.success(null);
  }

  /// Validates business rules for an allocation
  Result<void, ValidationException> _validateAllocationBusinessRules(CapacityAllocation allocation) {
    if (_currentPlan == null) return const Result.success(null);

    final errors = <String>[];

    // Check if team member exists and can fulfill role
    final teamMember = _currentPlan!.teamMembers
        .where((m) => m.id == allocation.teamMemberId)
        .firstOrNull;
    
    if (teamMember == null) {
      errors.add('Team member not found: ${allocation.teamMemberId}');
    } else if (!teamMember.canFulfillRole(allocation.role)) {
      errors.add('Team member ${teamMember.name} cannot fulfill ${allocation.role.displayName} role');
    }

    // Check if initiative exists
    final initiative = _currentPlan!.initiatives
        .where((i) => i.id == allocation.initiativeId)
        .firstOrNull;
    
    if (initiative == null) {
      errors.add('Initiative not found: ${allocation.initiativeId}');
    }

    // Check for capacity over-allocation
    if (teamMember != null) {
      final totalAllocated = _currentPlan!.allocations
          .where((a) => a.teamMemberId == teamMember.id && 
                       a.id != allocation.id && 
                       !a.isCancelled)
          .map((a) => a.allocatedWeeks)
          .fold(0.0, (sum, weeks) => sum + weeks) + allocation.allocatedWeeks;

      if (totalAllocated > teamMember.quarterlyCapacity) {
        errors.add('Over-allocation detected for ${teamMember.name}: '
                  '${totalAllocated.toStringAsFixed(1)} weeks allocated, '
                  'but only ${teamMember.quarterlyCapacity.toStringAsFixed(1)} weeks available');
      }
    }

    if (errors.isNotEmpty) {
      return Result.error(ValidationException(
        'Allocation validation failed',
        ValidationErrorType.businessRuleViolation,
        {'allocation': errors},
      ));
    }

    return const Result.success(null);
  }

  /// Starts a drag operation
  void startDragOperation(AllocationDragData dragData) {
    _isDragInProgress = true;
    _currentDragData = dragData;
    _calculateValidDropTargets(dragData);
    notifyListeners();
  }

  /// Ends a drag operation
  void endDragOperation() {
    _isDragInProgress = false;
    _currentDragData = null;
    _validDropTargets.clear();
    _dragValidationErrors.clear();
    notifyListeners();
  }

  /// Updates drag feedback during drag operations
  void updateDragFeedback(Offset globalPosition) {
    if (!_isDragInProgress || _currentDragData == null) return;
    
    // Real-time validation could be performed here
    // For now, we'll just notify listeners for potential UI updates
    notifyListeners();
  }

  /// Calculates valid drop targets for the current drag operation
  void _calculateValidDropTargets(AllocationDragData dragData) {
    if (_currentPlan == null) return;

    _validDropTargets.clear();
    _dragValidationErrors.clear();

    for (final teamMember in _currentPlan!.teamMembers.where((m) => m.isActive)) {
      final targetKey = '${teamMember.id}';
      
      // Check if team member can fulfill the role
      if (!teamMember.canFulfillRole(dragData.allocation.role)) {
        _dragValidationErrors[targetKey] = [
          ValidationException(
            'Cannot allocate ${teamMember.name} to ${dragData.allocation.role.displayName} role: '
            'team member does not have this role capability.',
            ValidationErrorType.businessRuleViolation,
          )
        ];
        continue;
      }

      // Check capacity constraints
      final currentAllocations = _currentPlan!.allocations
          .where((a) => a.teamMemberId == teamMember.id && 
                       a.id != dragData.allocation.id && 
                       !a.isCancelled)
          .map((a) => a.allocatedWeeks)
          .fold(0.0, (sum, weeks) => sum + weeks);

      if (currentAllocations + dragData.allocation.allocatedWeeks > teamMember.quarterlyCapacity) {
        _dragValidationErrors[targetKey] = [
          ExceptionFactory.capacityOverallocated(
            teamMember.name,
            currentAllocations + dragData.allocation.allocatedWeeks,
            teamMember.quarterlyCapacity,
          )
        ];
        continue;
      }

      _validDropTargets.add(targetKey);
    }
  }

  /// Validates if an allocation can be moved to a new position
  bool validateAllocationMove(
    CapacityAllocation allocation,
    String newTeamMemberId,
    DateTime newStartDate,
    DateTime newEndDate,
  ) {
    if (_currentPlan == null) return false;

    final teamMember = _currentPlan!.teamMembers
        .where((m) => m.id == newTeamMemberId)
        .firstOrNull;
    
    if (teamMember == null || !teamMember.canFulfillRole(allocation.role)) {
      return false;
    }

    // Check for capacity conflicts in the new time range
    final availableCapacity = teamMember.calculateAvailableCapacity(newStartDate, newEndDate);
    final existingAllocations = _currentPlan!.allocations
        .where((a) => a.teamMemberId == newTeamMemberId && 
                     a.id != allocation.id && 
                     !a.isCancelled &&
                     !(a.endDate.isBefore(newStartDate) || a.startDate.isAfter(newEndDate)))
        .map((a) => a.allocatedWeeks)
        .fold(0.0, (sum, weeks) => sum + weeks);

    return existingAllocations + allocation.allocatedWeeks <= availableCapacity;
  }

  /// Moves an allocation to a new position
  Result<void, ValidationException> moveAllocation(
    CapacityAllocation allocation,
    String newTeamMemberId,
    DateTime newStartDate,
  ) {
    if (_currentPlan == null) {
      return Result.error(ValidationException(
        'No quarter plan loaded',
        ValidationErrorType.missingRequiredField,
      ));
    }

    final newEndDate = newStartDate.add(Duration(days: (allocation.durationInWeeks * 7).round()));
    
    if (!validateAllocationMove(allocation, newTeamMemberId, newStartDate, newEndDate)) {
      return Result.error(ValidationException(
        'Invalid allocation move: conflicts detected',
        ValidationErrorType.businessRuleViolation,
      ));
    }

    _saveToUndoStack();
    
    final updatedAllocation = allocation.copyWith(
      teamMemberId: newTeamMemberId,
      startDate: newStartDate,
      endDate: newEndDate,
      updatedAt: DateTime.now(),
    );

    final updatedAllocations = _currentPlan!.allocations
        .map((a) => a.id == allocation.id ? updatedAllocation : a)
        .toList();

    _currentPlan = _currentPlan!.copyWith(allocations: updatedAllocations);
    _markAsChanged();
    notifyListeners();
    
    return const Result.success(null);
  }

  /// Checks if an allocation has conflicts
  bool hasAllocationConflict(CapacityAllocation allocation) {
    if (_currentPlan == null) return false;

    final overlappingAllocations = _currentPlan!.allocations
        .where((a) => a.teamMemberId == allocation.teamMemberId &&
                     a.id != allocation.id &&
                     !a.isCancelled &&
                     !(a.endDate.isBefore(allocation.startDate) || 
                       a.startDate.isAfter(allocation.endDate)))
        .toList();

    return overlappingAllocations.isNotEmpty;
  }

  /// Checks if a team member is over-allocated
  bool isTeamMemberOverallocated(String teamMemberId) {
    if (_currentPlan == null) return false;

    final teamMember = _currentPlan!.teamMembers
        .where((m) => m.id == teamMemberId)
        .firstOrNull;
    
    if (teamMember == null) return false;

    final totalAllocated = _currentPlan!.allocations
        .where((a) => a.teamMemberId == teamMemberId && !a.isCancelled)
        .map((a) => a.allocatedWeeks)
        .fold(0.0, (sum, weeks) => sum + weeks);

    return totalAllocated > teamMember.quarterlyCapacity;
  }

  /// Toggles selection of an allocation
  void toggleAllocationSelection(String allocationId) {
    if (_selectedAllocationIds.contains(allocationId)) {
      _selectedAllocationIds.remove(allocationId);
    } else {
      _selectedAllocationIds.add(allocationId);
    }
    notifyListeners();
  }

  /// Clears all selections
  void _clearSelection() {
    _selectedAllocationIds.clear();
  }

  /// Saves current state to undo stack
  void _saveToUndoStack() {
    if (_currentPlan == null) return;

    _undoStack.add(_currentPlan!);
    if (_undoStack.length > _maxUndoStackSize) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear(); // Clear redo stack when new action is performed
  }

  /// Undoes the last action
  void undo() {
    if (!canUndo || _currentPlan == null) return;

    _redoStack.add(_currentPlan!);
    _currentPlan = _undoStack.removeLast();
    notifyListeners();
  }

  /// Redoes the last undone action
  void redo() {
    if (!canRedo) return;

    _undoStack.add(_currentPlan!);
    _currentPlan = _redoStack.removeLast();
    notifyListeners();
  }

  /// Marks the plan as having unsaved changes
  void _markAsChanged() {
    _planBeforeChanges ??= _currentPlan;
  }

  /// Marks the plan as saved (no unsaved changes)
  void markAsSaved() {
    _planBeforeChanges = null;
    notifyListeners();
  }

  /// Discards unsaved changes
  void discardChanges() {
    if (_planBeforeChanges != null) {
      _currentPlan = _planBeforeChanges;
      _planBeforeChanges = null;
      _clearSelection();
      notifyListeners();
    }
  }

  /// Gets validation errors for drag targets
  List<ValidationException> getDragValidationErrors(String targetKey) {
    return _dragValidationErrors[targetKey] ?? [];
  }

  @override
  void dispose() {
    _undoStack.clear();
    _redoStack.clear();
    _selectedAllocationIds.clear();
    super.dispose();
  }
}
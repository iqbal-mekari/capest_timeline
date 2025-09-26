import 'package:equatable/equatable.dart';

import '../../../../core/enums/role.dart';
import '../../../../core/types/result.dart';
import '../../../../core/errors/exceptions.dart';
import 'initiative.dart';
import '../../../team_management/domain/entities/team_member.dart';
import 'capacity_allocation.dart';

/// Represents a complete quarter plan containing initiatives, team members, and allocations.
/// 
/// A QuarterPlan is the main aggregate that contains:
/// - All initiatives planned for the quarter
/// - All team members available for the quarter
/// - All capacity allocations between members and initiatives
/// - Overall planning metadata and status
class QuarterPlan extends Equatable {
  const QuarterPlan({
    required this.id,
    required this.quarter,
    required this.year,
    required this.initiatives,
    required this.teamMembers,
    required this.allocations,
    this.name,
    this.notes = '',
    this.isLocked = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Unique identifier for this quarter plan
  final String id;

  /// Quarter number (1-4)
  final int quarter;

  /// Year of this plan
  final int year;

  /// Optional custom name for this plan
  final String? name;

  /// All initiatives in this quarter plan
  final List<Initiative> initiatives;

  /// All team members available for this quarter
  final List<TeamMember> teamMembers;

  /// All capacity allocations for this quarter
  final List<CapacityAllocation> allocations;

  /// Optional notes about this quarter plan
  final String notes;

  /// Whether this plan is locked from further changes
  final bool isLocked;

  /// When this plan was created
  final DateTime? createdAt;

  /// When this plan was last updated
  final DateTime? updatedAt;

  /// Gets a display name for this quarter plan
  String get displayName => name ?? 'Q$quarter $year';

  /// Gets the date range for this quarter
  (DateTime startDate, DateTime endDate) get quarterDateRange {
    final startMonth = (quarter - 1) * 3 + 1;
    final startDate = DateTime(year, startMonth, 1);
    final endDate = DateTime(year, startMonth + 3, 0); // Last day of quarter
    return (startDate, endDate);
  }

  /// Gets total available capacity across all team members for this quarter
  double get totalAvailableCapacity {
    final (startDate, endDate) = quarterDateRange;
    return teamMembers
        .where((member) => member.isActive)
        .map((member) => member.calculateAvailableCapacity(startDate, endDate))
        .fold(0.0, (sum, capacity) => sum + capacity);
  }

  /// Gets total allocated capacity across all allocations
  double get totalAllocatedCapacity {
    return allocations
        .where((allocation) => !allocation.isCancelled)
        .map((allocation) => allocation.allocatedWeeks)
        .fold(0.0, (sum, weeks) => sum + weeks);
  }

  /// Gets remaining unallocated capacity
  double get remainingCapacity => totalAvailableCapacity - totalAllocatedCapacity;

  /// Gets capacity utilization percentage
  double get capacityUtilization {
    if (totalAvailableCapacity == 0) return 0.0;
    return (totalAllocatedCapacity / totalAvailableCapacity) * 100;
  }

  /// Checks if the plan is over-allocated (utilization > 100%)
  bool get isOverAllocated => capacityUtilization > 100.0;

  /// Gets capacity breakdown by role
  Map<Role, CapacityBreakdown> get capacityByRole {
    final breakdown = <Role, CapacityBreakdown>{};
    
    // Initialize with available capacity from team members
    for (final member in teamMembers.where((m) => m.isActive)) {
      final (startDate, endDate) = quarterDateRange;
      final memberCapacity = member.calculateAvailableCapacity(startDate, endDate);
      
      for (final role in member.roles) {
        final current = breakdown[role] ?? CapacityBreakdown.empty();
        breakdown[role] = current.copyWith(
          available: current.available + memberCapacity,
        );
      }
    }

    // Add allocated capacity
    for (final allocation in allocations.where((a) => !a.isCancelled)) {
      final current = breakdown[allocation.role] ?? CapacityBreakdown.empty();
      breakdown[allocation.role] = current.copyWith(
        allocated: current.allocated + allocation.allocatedWeeks,
      );
    }

    return breakdown;
  }

  /// Gets initiatives that are not fully allocated
  List<Initiative> get underAllocatedInitiatives {
    return initiatives.where((initiative) {
      for (final entry in initiative.requiredRoles.entries) {
        final role = entry.key;
        final required = entry.value;
        final allocated = allocations
            .where((a) => a.initiativeId == initiative.id && 
                         a.role == role && 
                         !a.isCancelled)
            .map((a) => a.allocatedWeeks)
            .fold(0.0, (sum, weeks) => sum + weeks);
        
        if (allocated < required) return true;
      }
      return false;
    }).toList();
  }

  /// Gets team members that are over-allocated
  List<String> get overAllocatedMembers {
    final (startDate, endDate) = quarterDateRange;
    final overAllocated = <String>[];
    
    for (final member in teamMembers.where((m) => m.isActive)) {
      final available = member.calculateAvailableCapacity(startDate, endDate);
      final allocated = allocations
          .where((a) => a.teamMemberId == member.id && !a.isCancelled)
          .map((a) => a.allocatedWeeks)
          .fold(0.0, (sum, weeks) => sum + weeks);
      
      if (allocated > available) {
        overAllocated.add(member.id);
      }
    }
    
    return overAllocated;
  }

  /// Gets summary statistics for this plan
  QuarterPlanSummary get summary {
    return QuarterPlanSummary(
      totalInitiatives: initiatives.length,
      completedInitiatives: allocations
          .where((a) => a.isCompleted)
          .map((a) => a.initiativeId)
          .toSet()
          .length,
      totalTeamMembers: teamMembers.where((m) => m.isActive).length,
      totalAllocations: allocations.where((a) => !a.isCancelled).length,
      capacityUtilization: capacityUtilization,
      isOverAllocated: isOverAllocated,
      underAllocatedInitiatives: underAllocatedInitiatives.length,
      overAllocatedMembers: overAllocatedMembers.length,
    );
  }

  /// Finds all allocations for a specific team member
  List<CapacityAllocation> getAllocationsForMember(String memberId) {
    return allocations
        .where((allocation) => 
            allocation.teamMemberId == memberId && !allocation.isCancelled)
        .toList();
  }

  /// Finds all allocations for a specific initiative
  List<CapacityAllocation> getAllocationsForInitiative(String initiativeId) {
    return allocations
        .where((allocation) => 
            allocation.initiativeId == initiativeId && !allocation.isCancelled)
        .toList();
  }

  /// Validates the entire quarter plan
  Result<void, ValidationException> validate() {
    final errors = <String>[];

    // Basic validation
    if (id.trim().isEmpty) {
      errors.add('Quarter plan ID cannot be empty');
    }

    if (quarter < 1 || quarter > 4) {
      errors.add('Quarter must be between 1 and 4');
    }

    if (year < 2020 || year > 2050) {
      errors.add('Year must be between 2020 and 2050');
    }

    // Validate individual entities
    for (int i = 0; i < initiatives.length; i++) {
      final validation = initiatives[i].validate();
      if (validation.isError) {
        errors.add('Initiative ${i + 1}: ${validation.error}');
      }
    }

    for (int i = 0; i < teamMembers.length; i++) {
      final validation = teamMembers[i].validate();
      if (validation.isError) {
        errors.add('Team member ${i + 1}: ${validation.error}');
      }
    }

    for (int i = 0; i < allocations.length; i++) {
      final validation = allocations[i].validate();
      if (validation.isError) {
        errors.add('Allocation ${i + 1}: ${validation.error}');
      }
    }

    // Check for duplicate IDs
    final initiativeIds = initiatives.map((i) => i.id).toList();
    final duplicateInitiativeIds = _findDuplicates(initiativeIds);
    if (duplicateInitiativeIds.isNotEmpty) {
      errors.add('Duplicate initiative IDs: ${duplicateInitiativeIds.join(", ")}');
    }

    final memberIds = teamMembers.map((m) => m.id).toList();
    final duplicateMemberIds = _findDuplicates(memberIds);
    if (duplicateMemberIds.isNotEmpty) {
      errors.add('Duplicate team member IDs: ${duplicateMemberIds.join(", ")}');
    }

    final allocationIds = allocations.map((a) => a.id).toList();
    final duplicateAllocationIds = _findDuplicates(allocationIds);
    if (duplicateAllocationIds.isNotEmpty) {
      errors.add('Duplicate allocation IDs: ${duplicateAllocationIds.join(", ")}');
    }

    // Validate referential integrity
    final validMemberIds = teamMembers.map((m) => m.id).toSet();
    final validInitiativeIds = initiatives.map((i) => i.id).toSet();

    for (final allocation in allocations) {
      if (!validMemberIds.contains(allocation.teamMemberId)) {
        errors.add('Allocation ${allocation.id} references unknown team member: ${allocation.teamMemberId}');
      }
      if (!validInitiativeIds.contains(allocation.initiativeId)) {
        errors.add('Allocation ${allocation.id} references unknown initiative: ${allocation.initiativeId}');
      }
    }

    // Check for extreme over-allocation
    if (capacityUtilization > 200.0) {
      errors.add('Extreme over-allocation detected: ${capacityUtilization.toStringAsFixed(1)}% utilization');
    }

    if (errors.isNotEmpty) {
      return Result.error(
        ValidationException(
          'Quarter plan validation failed',
          ValidationErrorType.businessRuleViolation,
          {'quarterPlan': errors},
        ),
      );
    }

    return const Result.success(null);
  }

  /// Helper method to find duplicate items in a list
  List<T> _findDuplicates<T>(List<T> items) {
    final seen = <T>{};
    final duplicates = <T>{};
    
    for (final item in items) {
      if (seen.contains(item)) {
        duplicates.add(item);
      } else {
        seen.add(item);
      }
    }
    
    return duplicates.toList();
  }

  /// Creates a copy of this quarter plan with updated fields
  QuarterPlan copyWith({
    String? id,
    int? quarter,
    int? year,
    String? name,
    List<Initiative>? initiatives,
    List<TeamMember>? teamMembers,
    List<CapacityAllocation>? allocations,
    String? notes,
    bool? isLocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuarterPlan(
      id: id ?? this.id,
      quarter: quarter ?? this.quarter,
      year: year ?? this.year,
      name: name ?? this.name,
      initiatives: initiatives ?? this.initiatives,
      teamMembers: teamMembers ?? this.teamMembers,
      allocations: allocations ?? this.allocations,
      notes: notes ?? this.notes,
      isLocked: isLocked ?? this.isLocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Creates a QuarterPlan from a Map (for serialization)
  factory QuarterPlan.fromMap(Map<String, dynamic> map) {
    return QuarterPlan(
      id: map['id'] as String,
      quarter: map['quarter'] as int,
      year: map['year'] as int,
      name: map['name'] as String?,
      initiatives: (map['initiatives'] as List<dynamic>)
          .map((initiativeMap) => Initiative.fromMap(initiativeMap as Map<String, dynamic>))
          .toList(),
      teamMembers: (map['teamMembers'] as List<dynamic>)
          .map((memberMap) => TeamMember.fromMap(memberMap as Map<String, dynamic>))
          .toList(),
      allocations: (map['allocations'] as List<dynamic>)
          .map((allocationMap) => CapacityAllocation.fromMap(allocationMap as Map<String, dynamic>))
          .toList(),
      notes: map['notes'] as String? ?? '',
      isLocked: map['isLocked'] as bool? ?? false,
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  /// Converts this QuarterPlan to a Map (for serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quarter': quarter,
      'year': year,
      'name': name,
      'initiatives': initiatives.map((i) => i.toMap()).toList(),
      'teamMembers': teamMembers.map((m) => m.toMap()).toList(),
      'allocations': allocations.map((a) => a.toMap()).toList(),
      'notes': notes,
      'isLocked': isLocked,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        quarter,
        year,
        name,
        initiatives,
        teamMembers,
        allocations,
        notes,
        isLocked,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'QuarterPlan('
        'id: $id, '
        'quarter: Q$quarter $year, '
        'initiatives: ${initiatives.length}, '
        'members: ${teamMembers.length}, '
        'allocations: ${allocations.length}, '
        'utilization: ${capacityUtilization.toStringAsFixed(1)}%'
        ')';
  }
}

/// Represents capacity breakdown for a specific role
class CapacityBreakdown extends Equatable {
  const CapacityBreakdown({
    required this.available,
    required this.allocated,
  });

  /// Total available capacity for this role
  final double available;

  /// Total allocated capacity for this role
  final double allocated;

  /// Factory constructor for empty breakdown
  factory CapacityBreakdown.empty() => const CapacityBreakdown(
        available: 0.0,
        allocated: 0.0,
      );

  /// Remaining unallocated capacity
  double get remaining => available - allocated;

  /// Utilization percentage
  double get utilization => available > 0 ? (allocated / available) * 100 : 0.0;

  /// Whether this role is over-allocated
  bool get isOverAllocated => allocated > available;

  /// Creates a copy with updated values
  CapacityBreakdown copyWith({
    double? available,
    double? allocated,
  }) {
    return CapacityBreakdown(
      available: available ?? this.available,
      allocated: allocated ?? this.allocated,
    );
  }

  @override
  List<Object?> get props => [available, allocated];

  @override
  String toString() {
    return 'CapacityBreakdown('
        'available: ${available.toStringAsFixed(1)}, '
        'allocated: ${allocated.toStringAsFixed(1)}, '
        'utilization: ${utilization.toStringAsFixed(1)}%'
        ')';
  }
}

/// Summary statistics for a quarter plan
class QuarterPlanSummary extends Equatable {
  const QuarterPlanSummary({
    required this.totalInitiatives,
    required this.completedInitiatives,
    required this.totalTeamMembers,
    required this.totalAllocations,
    required this.capacityUtilization,
    required this.isOverAllocated,
    required this.underAllocatedInitiatives,
    required this.overAllocatedMembers,
  });

  final int totalInitiatives;
  final int completedInitiatives;
  final int totalTeamMembers;
  final int totalAllocations;
  final double capacityUtilization;
  final bool isOverAllocated;
  final int underAllocatedInitiatives;
  final int overAllocatedMembers;

  /// Gets completion percentage
  double get completionPercentage => totalInitiatives > 0 
      ? (completedInitiatives / totalInitiatives) * 100 
      : 0.0;

  /// Checks if the plan has any issues
  bool get hasIssues => isOverAllocated || 
                       underAllocatedInitiatives > 0 || 
                       overAllocatedMembers > 0;

  @override
  List<Object?> get props => [
        totalInitiatives,
        completedInitiatives,
        totalTeamMembers,
        totalAllocations,
        capacityUtilization,
        isOverAllocated,
        underAllocatedInitiatives,
        overAllocatedMembers,
      ];

  @override
  String toString() {
    return 'QuarterPlanSummary('
        'initiatives: $totalInitiatives, '
        'completion: ${completionPercentage.toStringAsFixed(1)}%, '
        'utilization: ${capacityUtilization.toStringAsFixed(1)}%, '
        'issues: $hasIssues'
        ')';
  }
}
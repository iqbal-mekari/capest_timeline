import 'package:equatable/equatable.dart';
import 'platform_variant.dart';
import 'platform_type.dart';

/// Represents a high-level initiative that can span multiple platforms
class Initiative extends Equatable {
  const Initiative({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.platformVariants,
    this.requiredPlatforms = const [],
    this.updatedAt,
    this.dueDate,
    this.status = 'active',
    this.priority = 'medium',
    this.tags = const [],
    this.stakeholders = const [],
    this.businessValue,
    this.estimatedCost,
  });

  /// Unique identifier for the initiative
  final String id;

  /// Title of the initiative
  final String title;

  /// Detailed description
  final String description;

  /// When the initiative was created
  final DateTime createdAt;

  /// When the initiative was last updated
  final DateTime? updatedAt;

  /// Optional due date
  final DateTime? dueDate;

  /// Current status (active, completed, on-hold, cancelled)
  final String status;

  /// Priority level (low, medium, high, critical)
  final String priority;

  /// List of platform variants for this initiative
  final List<PlatformVariant> platformVariants;

  /// Required platform types for this initiative
  final List<PlatformType> requiredPlatforms;

  /// Optional tags for categorization
  final List<String> tags;

  /// List of stakeholder names or IDs
  final List<String> stakeholders;

  /// Optional business value description
  final String? businessValue;

  /// Optional estimated cost
  final double? estimatedCost;

  /// Get total effort required across all variants in hours
  double get totalEffortWeeks {
    return platformVariants.fold(0.0, (sum, variant) => sum + variant.estimatedWeeks);
  }

  /// Get estimated weeks (alias for totalEffortWeeks for test compatibility)
  double get estimatedWeeks => totalEffortWeeks;

  /// Get total effort in hours (assuming 40 hours per week)
  double get totalEffortHours {
    return totalEffortWeeks * 40.0;
  }

  /// Alias for platformVariants to match service expectations
  List<PlatformVariant> get variants => platformVariants;

  /// Check if initiative is active
  bool get isActive {
    return status == 'active';
  }

  /// Check if initiative is completed
  bool get isCompleted {
    return status == 'completed';
  }

  /// Check if initiative is in progress
  bool get isInProgress {
    return platformVariants.any((variant) => variant.isAssigned) && !isCompleted;
  }

  /// Get total completed weeks across all variants
  int get totalCompletedWeeks {
    return platformVariants.fold(0, (sum, variant) => sum + variant.completedWeeks);
  }

  /// Get overall completion percentage
  double get completionPercentage {
    if (totalEffortWeeks == 0) return 0.0;
    return (totalCompletedWeeks / totalEffortWeeks * 100).clamp(0.0, 100.0);
  }

  /// Check if initiative is overdue
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && !isCompleted;
  }

  /// Get variants by platform type
  List<PlatformVariant> getVariantsByPlatform(PlatformType platformType) {
    return platformVariants.where((v) => v.platformType == platformType).toList();
  }

  /// Get assigned variants
  List<PlatformVariant> get assignedVariants {
    return platformVariants.where((v) => v.isAssigned).toList();
  }

  /// Get unassigned variants
  List<PlatformVariant> get unassignedVariants {
    return platformVariants.where((v) => !v.isAssigned).toList();
  }

  /// Get unique assigned team member IDs
  List<String> get assignedTeamMemberIds {
    return platformVariants
        .where((v) => v.assignedMemberId != null)
        .map((v) => v.assignedMemberId!)
        .toSet()
        .toList();
  }

  /// Get earliest start date from variants
  DateTime? get earliestStartDate {
    if (platformVariants.isEmpty) return null;
    return platformVariants
        .map((v) => v.currentWeek)
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Get latest end date from variants
  DateTime? get latestEndDate {
    if (platformVariants.isEmpty) return null;
    return platformVariants
        .map((v) => v.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  /// Check if initiative has conflicts (variants with same team member overlapping)
  bool get hasConflicts {
    for (int i = 0; i < platformVariants.length; i++) {
      for (int j = i + 1; j < platformVariants.length; j++) {
        if (platformVariants[i].conflictsWith(platformVariants[j])) {
          return true;
        }
      }
    }
    return false;
  }

  /// Create a copy with modified fields
  Initiative copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? dueDate,
    String? status,
    String? priority,
    List<PlatformVariant>? platformVariants,
    List<PlatformType>? requiredPlatforms,
    List<String>? tags,
    List<String>? stakeholders,
    String? businessValue,
    double? estimatedCost,
  }) {
    return Initiative(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      platformVariants: platformVariants ?? this.platformVariants,
      requiredPlatforms: requiredPlatforms ?? this.requiredPlatforms,
      tags: tags ?? this.tags,
      stakeholders: stakeholders ?? this.stakeholders,
      businessValue: businessValue ?? this.businessValue,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'priority': priority,
      'platformVariants': platformVariants.map((v) => v.toJson()).toList(),
      'requiredPlatforms': requiredPlatforms.map((p) => p.name).toList(),
      'tags': tags,
      'stakeholders': stakeholders,
      'businessValue': businessValue,
      'estimatedCost': estimatedCost,
    };
  }

  /// Create from JSON map
  factory Initiative.fromJson(Map<String, dynamic> json) {
    return Initiative(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String) 
          : null,
      status: json['status'] as String? ?? 'active',
      priority: json['priority'] as String? ?? 'medium',
      platformVariants: (json['platformVariants'] as List<dynamic>?)
          ?.map((v) => PlatformVariant.fromJson(v as Map<String, dynamic>))
          .toList() ?? [],
      requiredPlatforms: (json['requiredPlatforms'] as List<dynamic>?)
          ?.map((p) => PlatformType.values.firstWhere((pt) => pt.name == p))
          .toList() ?? [],
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      stakeholders: (json['stakeholders'] as List<dynamic>?)?.cast<String>() ?? [],
      businessValue: json['businessValue'] as String?,
      estimatedCost: json['estimatedCost'] as double?,
    );
  }

  /// Validate initiative data
  String? validate() {
    if (id.isEmpty) return 'ID cannot be empty';
    if (title.trim().isEmpty) return 'Title cannot be empty';
    if (description.trim().isEmpty) return 'Description cannot be empty';
    if (!['active', 'completed', 'on-hold', 'cancelled'].contains(status)) {
      return 'Status must be active, completed, on-hold, or cancelled';
    }
    if (!['low', 'medium', 'high', 'critical'].contains(priority)) {
      return 'Priority must be low, medium, high, or critical';
    }
    if (estimatedCost != null && estimatedCost! < 0) {
      return 'Estimated cost cannot be negative';
    }
    if (dueDate != null && dueDate!.isBefore(createdAt)) {
      return 'Due date cannot be before creation date';
    }

    // Validate platform variants
    for (final variant in platformVariants) {
      final variantError = variant.validate();
      if (variantError != null) {
        return 'Platform variant error: $variantError';
      }
    }

    return null;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        createdAt,
        updatedAt,
        dueDate,
        status,
        priority,
        platformVariants,
        requiredPlatforms,
        tags,
        stakeholders,
        businessValue,
        estimatedCost,
      ];

  @override
  String toString() {
    return 'Initiative(id: $id, title: $title, status: $status, '
        'variants: ${platformVariants.length}, completion: ${completionPercentage.toStringAsFixed(1)}%)';
  }
}
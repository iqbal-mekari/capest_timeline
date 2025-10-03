import 'package:equatable/equatable.dart';
import 'platform_type.dart';

/// Represents a platform-specific variant of an initiative
class PlatformVariant extends Equatable {
  const PlatformVariant({
    required this.id,
    required this.initiativeId,
    required this.platformType,
    required this.title,
    required this.estimatedWeeks,
    required this.currentWeek,
    required this.isAssigned,
    this.assignedMemberId,
    this.description,
    this.dependencies = const [],
    this.completedWeeks = 0,
    this.priority = 'medium',
    this.tags = const [],
  });

  /// Unique identifier for this variant
  final String id;

  /// ID of the parent initiative
  final String initiativeId;

  /// Platform type for this variant
  final PlatformType platformType;

  /// Title of the variant (usually includes platform prefix)
  final String title;

  /// Estimated weeks needed for completion
  final int estimatedWeeks;

  /// Current week this variant is assigned to
  final DateTime currentWeek;

  /// Whether this variant is assigned to a team member
  final bool isAssigned;

  /// ID of the assigned team member (if any)
  final String? assignedMemberId;

  /// Optional description specific to this variant
  final String? description;

  /// List of dependency variant IDs
  final List<String> dependencies;

  /// Number of weeks already completed
  final int completedWeeks;

  /// Priority level (low, medium, high, critical)
  final String priority;

  /// Optional tags for categorization
  final List<String> tags;

  /// Get remaining weeks
  int get remainingWeeks => (estimatedWeeks - completedWeeks).clamp(0, estimatedWeeks);

  /// Get completion percentage
  double get completionPercentage {
    if (estimatedWeeks == 0) return 0.0;
    return (completedWeeks / estimatedWeeks * 100).clamp(0.0, 100.0);
  }

  /// Check if variant is completed
  bool get isCompleted => completedWeeks >= estimatedWeeks;

  /// Check if variant is overdue (current date past expected completion)
  bool isOverdue(DateTime currentDate) {
    final expectedCompletion = currentWeek.add(Duration(days: estimatedWeeks * 7));
    return currentDate.isAfter(expectedCompletion) && !isCompleted;
  }

  /// Get the end date based on current week and estimated duration
  DateTime get endDate => currentWeek.add(Duration(days: estimatedWeeks * 7 - 1));

  /// Check if this variant conflicts with another in the same time period
  bool conflictsWith(PlatformVariant other) {
    if (assignedMemberId == null || 
        other.assignedMemberId == null || 
        assignedMemberId != other.assignedMemberId) {
      return false;
    }
    
    final thisEnd = endDate;
    final otherEnd = other.endDate;
    
    return currentWeek.isBefore(otherEnd.add(const Duration(days: 1))) &&
           thisEnd.isAfter(other.currentWeek.subtract(const Duration(days: 1)));
  }

  /// Create a copy with modified fields
  PlatformVariant copyWith({
    String? id,
    String? initiativeId,
    PlatformType? platformType,
    String? title,
    int? estimatedWeeks,
    DateTime? currentWeek,
    bool? isAssigned,
    String? assignedMemberId,
    String? description,
    List<String>? dependencies,
    int? completedWeeks,
    String? priority,
    List<String>? tags,
  }) {
    return PlatformVariant(
      id: id ?? this.id,
      initiativeId: initiativeId ?? this.initiativeId,
      platformType: platformType ?? this.platformType,
      title: title ?? this.title,
      estimatedWeeks: estimatedWeeks ?? this.estimatedWeeks,
      currentWeek: currentWeek ?? this.currentWeek,
      isAssigned: isAssigned ?? this.isAssigned,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
      description: description ?? this.description,
      dependencies: dependencies ?? this.dependencies,
      completedWeeks: completedWeeks ?? this.completedWeeks,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'initiativeId': initiativeId,
      'platformType': platformType.toJson(),
      'title': title,
      'estimatedWeeks': estimatedWeeks,
      'currentWeek': currentWeek.toIso8601String(),
      'isAssigned': isAssigned,
      'assignedMemberId': assignedMemberId,
      'description': description,
      'dependencies': dependencies,
      'completedWeeks': completedWeeks,
      'priority': priority,
      'tags': tags,
    };
  }

  /// Create from JSON map
  factory PlatformVariant.fromJson(Map<String, dynamic> json) {
    return PlatformVariant(
      id: json['id'] as String,
      initiativeId: json['initiativeId'] as String,
      platformType: PlatformType.fromJson(json['platformType'] as String),
      title: json['title'] as String,
      estimatedWeeks: json['estimatedWeeks'] as int,
      currentWeek: DateTime.parse(json['currentWeek'] as String),
      isAssigned: json['isAssigned'] as bool,
      assignedMemberId: json['assignedMemberId'] as String?,
      description: json['description'] as String?,
      dependencies: (json['dependencies'] as List<dynamic>?)?.cast<String>() ?? [],
      completedWeeks: json['completedWeeks'] as int? ?? 0,
      priority: json['priority'] as String? ?? 'medium',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Validate platform variant data
  String? validate() {
    if (id.isEmpty) return 'ID cannot be empty';
    if (initiativeId.isEmpty) return 'Initiative ID cannot be empty';
    if (title.trim().isEmpty) return 'Title cannot be empty';
    if (estimatedWeeks < 0) return 'Estimated weeks cannot be negative';
    if (estimatedWeeks > 104) return 'Estimated weeks cannot exceed 2 years';
    if (completedWeeks < 0) return 'Completed weeks cannot be negative';
    if (completedWeeks > estimatedWeeks) return 'Completed weeks cannot exceed estimated weeks';
    if (isAssigned && (assignedMemberId?.isEmpty ?? true)) {
      return 'Assigned variants must have a team member ID';
    }
    if (!['low', 'medium', 'high', 'critical'].contains(priority)) {
      return 'Priority must be low, medium, high, or critical';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        initiativeId,
        platformType,
        title,
        estimatedWeeks,
        currentWeek,
        isAssigned,
        assignedMemberId,
        description,
        dependencies,
        completedWeeks,
        priority,
        tags,
      ];

  @override
  String toString() {
    return 'PlatformVariant(id: $id, platformType: $platformType, title: $title, '
        'estimatedWeeks: $estimatedWeeks, isAssigned: $isAssigned)';
  }
}
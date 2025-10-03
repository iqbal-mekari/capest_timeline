import 'package:equatable/equatable.dart';

/// Represents a team member who can be assigned to initiative variants
class TeamMember extends Equatable {
  const TeamMember({
    required this.id,
    required this.name,
    required this.weeklyCapacity,
    this.avatarUrl,
    this.email,
    this.role,
    this.skills = const [],
    this.platformSpecializations = const [],
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.skillLevel,
  });

  /// Unique identifier for the team member
  final String id;

  /// Display name of the team member
  final String name;

  /// Weekly capacity in hours (typically 40 for full-time)
  final double weeklyCapacity;

  /// Optional avatar image URL
  final String? avatarUrl;

  /// Optional email address
  final String? email;

  /// Optional role/title
  final String? role;

  /// List of skills/technologies
  final List<String> skills;

  /// Platform specializations/platforms this member can work on
  final List<String> platformSpecializations;

  /// Whether the team member is currently active
  final bool isActive;

  /// Employment start date (optional)
  final DateTime? startDate;

  /// Employment end date (optional)
  final DateTime? endDate;

  /// Skill level proficiency (0.0 to 1.0, optional)
  final double? skillLevel;

  /// Get initials from name for avatar fallback
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  /// Check if team member is available (active and has capacity)
  bool get isAvailable => isActive && weeklyCapacity > 0;

  /// Create a copy with modified fields
  TeamMember copyWith({
    String? id,
    String? name,
    double? weeklyCapacity,
    String? avatarUrl,
    String? email,
    String? role,
    List<String>? skills,
    List<String>? platformSpecializations,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    double? skillLevel,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      weeklyCapacity: weeklyCapacity ?? this.weeklyCapacity,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      platformSpecializations: platformSpecializations ?? this.platformSpecializations,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      skillLevel: skillLevel ?? this.skillLevel,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weeklyCapacity': weeklyCapacity,
      'avatarUrl': avatarUrl,
      'email': email,
      'role': role,
      'skills': skills,
      'platformSpecializations': platformSpecializations,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'skillLevel': skillLevel,
    };
  }

  /// Create from JSON map
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      name: json['name'] as String,
      weeklyCapacity: (json['weeklyCapacity'] as num).toDouble(),
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      skills: (json['skills'] as List<dynamic>?)?.cast<String>() ?? const [],
      platformSpecializations: (json['platformSpecializations'] as List<dynamic>?)?.cast<String>() ?? const [],
      isActive: json['isActive'] as bool? ?? true,
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String) 
          : null,
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      skillLevel: json['skillLevel'] as double?,
    );
  }

  /// Validate team member data
  String? validate() {
    if (id.isEmpty) return 'ID cannot be empty';
    if (name.trim().isEmpty) return 'Name cannot be empty';
    if (weeklyCapacity < 0) return 'Weekly capacity cannot be negative';
    if (weeklyCapacity > 168) return 'Weekly capacity cannot exceed 168 hours';
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        weeklyCapacity,
        avatarUrl,
        email,
        role,
        skills,
        platformSpecializations,
        isActive,
        startDate,
        endDate,
        skillLevel,
      ];

  @override
  String toString() {
    return 'TeamMember(id: $id, name: $name, weeklyCapacity: $weeklyCapacity, '
        'isActive: $isActive)';
  }
}
import '../models/models.dart';
import 'storage_service.dart';
import 'capacity_service.dart';

/// Result object for Kanban data operations
class KanbanDataResult {
  const KanbanDataResult({
    required this.initiatives,
    required this.teamMembers,
    required this.capacityPeriods,
    required this.timelineWeeks,
  });

  final List<Initiative> initiatives;
  final List<TeamMember> teamMembers;
  final List<CapacityPeriod> capacityPeriods;
  final List<DateTime> timelineWeeks;
}

/// Service for handling Kanban board operations and data management
class KanbanService {
  const KanbanService({
    required this.storageService,
    required this.capacityService,
  });

  final StorageService storageService;
  final CapacityService capacityService;

  /// Get complete Kanban board data
  Future<KanbanDataResult> getKanbanData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final effectiveStartDate = startDate ?? _getWeekStart(now);
    final effectiveEndDate = endDate ?? effectiveStartDate.add(const Duration(days: 84)); // 12 weeks

    // Load all data in parallel
    final futures = await Future.wait([
      storageService.loadInitiatives(),
      storageService.loadTeamMembers(),
      capacityService.getCapacityPeriods(effectiveStartDate, effectiveEndDate),
    ]);

    final initiatives = futures[0] as List<Initiative>;
    final teamMembers = futures[1] as List<TeamMember>;
    final capacityPeriods = futures[2] as List<CapacityPeriod>;

    // Generate timeline weeks
    final timelineWeeks = _generateTimelineWeeks(effectiveStartDate, effectiveEndDate);

    return KanbanDataResult(
      initiatives: initiatives,
      teamMembers: teamMembers,
      capacityPeriods: capacityPeriods,
      timelineWeeks: timelineWeeks,
    );
  }

  /// Create a new initiative
  Future<Initiative> createInitiative(Map<String, dynamic> initiativeData) async {
    // Extract and validate inputs from map
    final title = initiativeData['title'] as String?;
    final description = initiativeData['description'] as String?;
    final requiredPlatformsData = initiativeData['requiredPlatforms'] as List<dynamic>?;
    final estimatedWeeks = (initiativeData['estimatedWeeks'] as num?)?.toDouble();
    final priority = initiativeData['priority'] as int?;

    if (title == null || title.trim().isEmpty) {
      throw ArgumentError('Initiative title cannot be empty');
    }
    if (description == null || description.trim().isEmpty) {
      throw ArgumentError('Initiative description cannot be empty');
    }
    if (requiredPlatformsData == null || requiredPlatformsData.isEmpty) {
      throw ArgumentError('At least one required platform must be specified');
    }
    if (estimatedWeeks == null || estimatedWeeks <= 0) {
      throw ArgumentError('Estimated weeks must be positive');
    }
    
    // Parse platform types
    final requiredPlatforms = <PlatformType>[];
    for (final platformName in requiredPlatformsData) {
      final platformType = PlatformType.values.firstWhere(
        (p) => p.name == platformName,
        orElse: () => throw ArgumentError('Invalid platform type: $platformName'),
      );
      requiredPlatforms.add(platformType);
    }
    
    // Check for duplicate names
    final existingInitiatives = await storageService.loadInitiatives();
    if (existingInitiatives.any((i) => i.title.toLowerCase() == title.toLowerCase())) {
      throw ArgumentError('Initiative with this title already exists');
    }

    // Generate unique ID
    final initiativeId = 'init_${DateTime.now().millisecondsSinceEpoch}';

    // Create platform variants - distribute effort evenly across platforms
    final effortPerPlatform = estimatedWeeks / requiredPlatforms.length;
    final variants = <PlatformVariant>[];
    
    for (final platformType in requiredPlatforms) {
      final variantId = 'variant_${platformType.name}_${DateTime.now().millisecondsSinceEpoch}';
      final variant = PlatformVariant(
        id: variantId,
        initiativeId: initiativeId,
        platformType: platformType,
        title: '${platformType.displayName} $title',
        estimatedWeeks: effortPerPlatform.round(),
        currentWeek: DateTime.now(),
        isAssigned: false,
      );
      variants.add(variant);
    }

    // Create the initiative
    final initiative = Initiative(
      id: initiativeId,
      title: title,
      description: description,
      platformVariants: variants,
      requiredPlatforms: requiredPlatforms,
      createdAt: DateTime.now(),
      status: 'active',
      priority: priority?.toString() ?? 'medium',
    );

    // Save to storage
    await storageService.saveInitiative(initiative);
    
    // Also save the variants
    for (final variant in variants) {
      await storageService.savePlatformVariant(variant);
    }

    return initiative;
  }

  /// Move initiative to a different week
  Future<void> moveInitiative({
    required String initiativeId,
    required DateTime targetWeek,
    String? platformType,
  }) async {
    final initiative = await _getInitiative(initiativeId);
    if (initiative == null) {
      throw ArgumentError('Initiative not found: $initiativeId');
    }

    // If platformType is specified, only move that variant
    if (platformType != null) {
      final variant = initiative.variants.firstWhere(
        (v) => v.platformType == platformType,
        orElse: () => throw ArgumentError('Platform variant not found: $platformType'),
      );

      final updatedVariant = variant.copyWith(currentWeek: targetWeek);
      await storageService.savePlatformVariant(updatedVariant);
    } else {
      // Move all variants
      for (final variant in initiative.variants) {
        final updatedVariant = variant.copyWith(currentWeek: targetWeek);
        await storageService.savePlatformVariant(updatedVariant);
      }
    }

    // Update related assignments if any
    await _updateRelatedAssignments(initiativeId, targetWeek);
  }

  /// Move a specific variant to a target week
  Future<void> moveVariantToWeek(PlatformVariant variant, DateTime targetWeek) async {
    // Validate the target week (should be start of week - Monday)
    final weekStart = _getWeekStart(targetWeek);
    
    // Update the variant's current week
    final updatedVariant = variant.copyWith(currentWeek: weekStart);
    await storageService.savePlatformVariant(updatedVariant);
    
    // Update any related assignments
    final assignments = await storageService.loadAssignments();
    final variantAssignments = assignments.where((a) => a.variantId == variant.id).toList();
    
    for (final assignment in variantAssignments) {
      final updatedAssignment = assignment.copyWith(startWeek: weekStart);
      await storageService.saveAssignment(updatedAssignment);
    }
  }

  /// Update initiative details
  Future<void> updateInitiative({
    required String initiativeId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
    List<String>? tags,
  }) async {
    final initiative = await _getInitiative(initiativeId);
    if (initiative == null) {
      throw ArgumentError('Initiative not found: $initiativeId');
    }

    final updatedInitiative = initiative.copyWith(
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority?.toString(),
      tags: tags,
      updatedAt: DateTime.now(),
    );

    await storageService.saveInitiative(updatedInitiative);
  }

  /// Delete initiative
  Future<void> deleteInitiative(String initiativeId) async {
    final initiative = await _getInitiative(initiativeId);
    if (initiative == null) {
      throw ArgumentError('Initiative not found: $initiativeId');
    }

    await storageService.deleteInitiative(initiativeId);
  }

  /// Assign team member to initiative variant
  Future<String> assignMember({
    required String initiativeId,
    required String memberId,
    required String platformType,
    required double capacityPercentage,
    required DateTime startWeek,
    double? durationWeeks,
  }) async {
    // Validate inputs
    if (capacityPercentage <= 0 || capacityPercentage > 1) {
      throw ArgumentError('Capacity percentage must be between 0 and 1');
    }

    final initiative = await _getInitiative(initiativeId);
    if (initiative == null) {
      throw ArgumentError('Initiative not found: $initiativeId');
    }

    final member = await _getTeamMember(memberId);
    if (member == null) {
      throw ArgumentError('Team member not found: $memberId');
    }

    final variant = initiative.variants.firstWhere(
      (v) => v.platformType == platformType,
      orElse: () => throw ArgumentError('Platform variant not found: $platformType'),
    );

    // Check if member has required skills
    if (!member.skills.contains(platformType)) {
      throw ArgumentError('Team member does not have required skills for $platformType');
    }

    // Check for capacity conflicts
    final memberAvailability = await capacityService.getMemberAvailability(
      memberId: memberId,
      startDate: startWeek,
      endDate: startWeek.add(Duration(days: ((durationWeeks ?? variant.estimatedWeeks) * 7).round())),
    );

    if (!memberAvailability['available']) {
      throw ArgumentError('Team member is not available during the requested period');
    }

    // Check if assignment would cause over-allocation
    final availableCapacity = memberAvailability['availableHours'] as double;
    final requestedHours = (durationWeeks ?? variant.estimatedWeeks) * capacityPercentage * 40;
    
    if (requestedHours > availableCapacity) {
      throw ArgumentError('Assignment would cause over-allocation');
    }

    // Create assignment
    final assignmentId = 'assign_${DateTime.now().millisecondsSinceEpoch}';
    final assignment = Assignment(
      id: assignmentId,
      memberId: memberId,
      platformType: PlatformType.values.firstWhere((p) => p.name == platformType),
      allocatedWeeks: (durationWeeks ?? variant.estimatedWeeks).toDouble(),
      capacityPercentage: capacityPercentage,
      startWeek: startWeek,
      initiativeId: initiativeId,
      variantId: variant.id,
    );

    await storageService.saveAssignment(assignment);

    // Mark variant as assigned
    final updatedVariant = variant.copyWith(isAssigned: true);
    await storageService.savePlatformVariant(updatedVariant);

    return assignmentId;
  }

  /// Unassign team member from initiative
  Future<void> unassignMember({
    required String assignmentId,
  }) async {
    final assignments = await storageService.loadAssignments();
    final assignment = assignments.firstWhere(
      (a) => a.id == assignmentId,
      orElse: () => throw ArgumentError('Assignment not found: $assignmentId'),
    );

    await storageService.deleteAssignment(assignmentId);

    // Check if variant should be marked as unassigned
    if (assignment.variantId != null) {
      final remainingAssignments = assignments
          .where((a) => a.variantId == assignment.variantId && a.id != assignmentId)
          .toList();

      if (remainingAssignments.isEmpty) {
        final variants = await storageService.loadPlatformVariants();
        final variant = variants.firstWhere((v) => v.id == assignment.variantId);
        final updatedVariant = variant.copyWith(isAssigned: false);
        await storageService.savePlatformVariant(updatedVariant);
      }
    }
  }

  /// Get initiative by ID
  Future<Initiative?> _getInitiative(String initiativeId) async {
    final initiatives = await storageService.loadInitiatives();
    try {
      return initiatives.firstWhere((i) => i.id == initiativeId);
    } catch (e) {
      return null;
    }
  }

  /// Get team member by ID
  Future<TeamMember?> _getTeamMember(String memberId) async {
    final members = await storageService.loadTeamMembers();
    try {
      return members.firstWhere((m) => m.id == memberId);
    } catch (e) {
      return null;
    }
  }

  /// Update assignments related to an initiative when it's moved
  Future<void> _updateRelatedAssignments(String initiativeId, DateTime newStartWeek) async {
    final assignments = await storageService.loadAssignments();
    final relatedAssignments = assignments.where((a) => a.initiativeId == initiativeId).toList();

    for (final assignment in relatedAssignments) {
      final updatedAssignment = assignment.copyWith(startWeek: newStartWeek);
      await storageService.saveAssignment(updatedAssignment);
    }
  }

  /// Generate timeline weeks for the specified date range
  List<DateTime> _generateTimelineWeeks(DateTime startDate, DateTime endDate) {
    final weeks = <DateTime>[];
    DateTime currentWeek = _getWeekStart(startDate);
    
    while (currentWeek.isBefore(endDate) || currentWeek.isAtSameMomentAs(endDate)) {
      weeks.add(currentWeek);
      currentWeek = currentWeek.add(const Duration(days: 7));
    }
    
    return weeks;
  }

  /// Get the start of the week (Monday)
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}
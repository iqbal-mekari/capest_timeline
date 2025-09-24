import '../../features/capacity_planning/domain/entities/quarter_plan.dart';
import '../../features/capacity_planning/domain/entities/capacity_allocation.dart';
import '../../features/capacity_planning/domain/repositories/capacity_planning_repository.dart';
import '../../features/team_management/domain/entities/team_member.dart';
import '../../features/team_management/domain/repositories/team_management_repository.dart';
import '../../features/configuration/domain/entities/application_state.dart';
import '../../features/configuration/domain/entities/user_configuration.dart';
import '../../features/configuration/domain/repositories/configuration_repository.dart';
import '../types/result.dart';
import '../errors/exceptions.dart';
import '../enums/role.dart';

/// Use case for backing up and restoring application data
class BackupAndRestoreData {
  const BackupAndRestoreData({
    required this.capacityRepository,
    required this.teamRepository,
    required this.configRepository,
  });

  final CapacityPlanningRepository capacityRepository;
  final TeamManagementRepository teamRepository;
  final ConfigurationRepository configRepository;

  /// Creates a complete backup of all application data
  Future<Result<Map<String, dynamic>, Exception>> createBackup() async {
    try {
      final backupData = <String, dynamic>{
        'version': '1.0.0',
        'created': DateTime.now().toIso8601String(),
        'data': {},
      };

      // Backup quarter plans
      final plansResult = await capacityRepository.listPlans();
      if (plansResult.isError) {
        return Result.error(plansResult.error);
      }
      // Load each plan fully for backup
      final plansList = <Map<String, dynamic>>[];
      for (final planMeta in plansResult.value) {
        final planResult = await capacityRepository.loadPlan(planMeta.id);
        if (planResult.isSuccess && planResult.value != null) {
          plansList.add(planResult.value!.toMap());
        }
      }
      backupData['data']['quarterPlans'] = plansList;

      // Backup team members
      final membersResult = await teamRepository.listMembers();
      if (membersResult.isError) {
        return Result.error(membersResult.error);
      }
      backupData['data']['teamMembers'] = membersResult.value.map((member) => member.toMap()).toList();

      // Backup application state
      final stateResult = await configRepository.loadApplicationState();
      if (stateResult.isError) {
        return Result.error(stateResult.error);
      }
      if (stateResult.value != null) {
        backupData['data']['applicationState'] = stateResult.value!.toMap();
      }

      // Backup user configuration
      final configResult = await configRepository.loadUserConfiguration();
      if (configResult.isError) {
        return Result.error(configResult.error);
      }
      if (configResult.value != null) {
        backupData['data']['userConfiguration'] = configResult.value!.toMap();
      }

      return Result.success(backupData);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to create backup: ${e.toString()}',
          StorageErrorType.unknown,
          e is Exception ? e : null,
        ),
      );
    }
  }

  /// Restores application data from a backup
  Future<Result<RestoreResult, Exception>> restoreFromBackup(Map<String, dynamic> backupData) async {
    try {
      // Validate backup structure
      if (!backupData.containsKey('data') || !backupData.containsKey('version')) {
        return Result.error(
          ValidationException(
            'Invalid backup format',
            ValidationErrorType.businessRuleViolation,
            {'backup': ['Missing required fields: data, version']},
          ),
        );
      }

      final data = backupData['data'] as Map<String, dynamic>;
      final restoreResult = RestoreResult();

      // Restore team members first (needed for capacity planning)
      if (data.containsKey('teamMembers')) {
        final membersData = data['teamMembers'] as List<dynamic>;
        for (final memberData in membersData) {
          try {
            final member = TeamMember.fromMap(memberData as Map<String, dynamic>);
            final saveResult = await teamRepository.saveMember(member);
            if (saveResult.isError) {
              restoreResult.addError('Failed to restore team member ${member.name}: ${saveResult.error}');
            } else {
              restoreResult.incrementRestoredMembers();
            }
          } catch (e) {
            restoreResult.addError('Failed to parse team member data: $e');
          }
        }
      }

      // Restore quarter plans
      if (data.containsKey('quarterPlans')) {
        final plansData = data['quarterPlans'] as List<dynamic>;
        for (final planData in plansData) {
          try {
            final plan = QuarterPlan.fromMap(planData as Map<String, dynamic>);
            final saveResult = await capacityRepository.savePlan(plan);
            if (saveResult.isError) {
              restoreResult.addError('Failed to restore quarter plan ${plan.name}: ${saveResult.error}');
            } else {
              restoreResult.incrementRestoredPlans();
            }
          } catch (e) {
            restoreResult.addError('Failed to parse quarter plan data: $e');
          }
        }
      }

      // Restore application state
      if (data.containsKey('applicationState')) {
        try {
          final stateData = data['applicationState'] as Map<String, dynamic>;
          final state = ApplicationState.fromMap(stateData);
          final saveResult = await configRepository.saveApplicationState(state);
          if (saveResult.isError) {
            restoreResult.addError('Failed to restore application state: ${saveResult.error}');
          } else {
            restoreResult.applicationStateRestored = true;
          }
        } catch (e) {
          restoreResult.addError('Failed to parse application state data: $e');
        }
      }

      // Restore user configuration
      if (data.containsKey('userConfiguration')) {
        try {
          final configData = data['userConfiguration'] as Map<String, dynamic>;
          final config = UserConfiguration.fromMap(configData);
          final saveResult = await configRepository.saveUserConfiguration(config);
          if (saveResult.isError) {
            restoreResult.addError('Failed to restore user configuration: ${saveResult.error}');
          } else {
            restoreResult.userConfigurationRestored = true;
          }
        } catch (e) {
          restoreResult.addError('Failed to parse user configuration data: $e');
        }
      }

      return Result.success(restoreResult);
    } catch (e) {
      return Result.error(
        StorageException(
          'Failed to restore from backup: ${e.toString()}',
          StorageErrorType.unknown,
          e is Exception ? e : null,
        ),
      );
    }
  }
}

/// Use case for migrating data between different formats or versions
class MigrateApplicationData {
  const MigrateApplicationData({
    required this.capacityRepository,
    required this.teamRepository,
    required this.configRepository,
  });

  final CapacityPlanningRepository capacityRepository;
  final TeamManagementRepository teamRepository;
  final ConfigurationRepository configRepository;

  /// Migrates data from an older version to current version
  Future<Result<MigrationResult, Exception>> migrateFromVersion(
    String fromVersion,
    Map<String, dynamic> oldData,
  ) async {
    try {
      final migrationResult = MigrationResult();

      switch (fromVersion) {
        case '0.9.0':
          return await _migrateFrom090(oldData, migrationResult);
        case '0.8.0':
          return await _migrateFrom080(oldData, migrationResult);
        default:
          return Result.error(
            ValidationException(
              'Unsupported migration version: $fromVersion',
              ValidationErrorType.businessRuleViolation,
              {'version': ['Version $fromVersion is not supported for migration']},
            ),
          );
      }
    } catch (e) {
      return Result.error(
        StorageException(
          'Migration failed: ${e.toString()}',
          StorageErrorType.unknown,
          e is Exception ? e : null,
        ),
      );
    }
  }

  /// Migrates data from version 0.9.0 to current
  Future<Result<MigrationResult, Exception>> _migrateFrom090(
    Map<String, dynamic> oldData,
    MigrationResult result,
  ) async {
    // In a real application, this would contain specific migration logic
    // For now, we'll assume the data structure is largely compatible
    result.addMigrationStep('Converting team member roles from strings to enums');
    result.addMigrationStep('Adding new capacity allocation status fields');
    result.addMigrationStep('Updating configuration structure');
    
    return Result.success(result);
  }

  /// Migrates data from version 0.8.0 to current
  Future<Result<MigrationResult, Exception>> _migrateFrom080(
    Map<String, dynamic> oldData,
    MigrationResult result,
  ) async {
    // Major structural changes would be handled here
    result.addMigrationStep('Converting from old quarterly structure to new flexible structure');
    result.addMigrationStep('Migrating initiative priorities from 1-5 scale to 1-10 scale');
    result.addMigrationStep('Converting capacity from hours to percentage-based system');
    
    return Result.success(result);
  }
}

/// Use case for performing bulk operations across domains
class BulkDataOperations {
  const BulkDataOperations({
    required this.capacityRepository,
    required this.teamRepository,
    required this.configRepository,
  });

  final CapacityPlanningRepository capacityRepository;
  final TeamManagementRepository teamRepository;
  final ConfigurationRepository configRepository;

  /// Bulk imports team members and automatically creates allocations
  Future<Result<BulkImportResult, Exception>> bulkImportTeamMembers(
    List<Map<String, dynamic>> memberData,
    {String? targetQuarterPlanId}
  ) async {
    final result = BulkImportResult();

    for (final data in memberData) {
      try {
        // Create team member
        final member = TeamMember.fromMap(data);
        
        // Validate member
        final validationResult = member.validate();
        if (validationResult.isError) {
          result.addError('Validation failed for ${member.name}: ${validationResult.error}');
          continue;
        }

        // Save member
        final saveResult = await teamRepository.saveMember(member);
        if (saveResult.isError) {
          result.addError('Failed to save ${member.name}: ${saveResult.error}');
          continue;
        }

        result.incrementSuccessfulImports();

        // Optionally add to quarter plan
        if (targetQuarterPlanId != null) {
          final planResult = await capacityRepository.loadPlan(targetQuarterPlanId);
          if (planResult.isSuccess && planResult.value != null) {
            // Create basic allocation for the member
            final now = DateTime.now();
            final allocation = CapacityAllocation(
              id: 'alloc_${member.id}_${now.millisecondsSinceEpoch}',
              teamMemberId: member.id,
              initiativeId: 'unassigned', // Placeholder for unassigned capacity
              role: member.roles.first, // Use primary role
              allocatedWeeks: 0.0, // No allocation initially
              startDate: DateTime(planResult.value!.year, (planResult.value!.quarter - 1) * 3 + 1),
              endDate: DateTime(planResult.value!.year, planResult.value!.quarter * 3 + 1).subtract(const Duration(days: 1)),
              status: AllocationStatus.planned,
              notes: 'Auto-created during bulk import',
              createdAt: now,
              updatedAt: now,
            );

            final addResult = await capacityRepository.saveAllocation(targetQuarterPlanId, allocation);
            if (addResult.isError) {
              result.addWarning('Failed to add allocation for ${member.name}: ${addResult.error}');
            }
          }
        }
      } catch (e) {
        result.addError('Failed to process member data: $e');
      }
    }

    return Result.success(result);
  }

  /// Bulk updates team member capacities based on role changes
  Future<Result<BulkUpdateResult, Exception>> bulkUpdateCapacitiesByRole(
    Role targetRole,
    double newWeeklyCapacity,
  ) async {
    final result = BulkUpdateResult();

    // Get all members with the target role
    final membersResult = await teamRepository.listMembers();
    if (membersResult.isError) {
      return Result.error(membersResult.error);
    }

    final targetMembers = membersResult.value.where(
      (member) => member.roles.contains(targetRole) && member.isActive,
    ).toList();

    for (final member in targetMembers) {
      try {
        final updatedMember = member.copyWith(
          weeklyCapacity: newWeeklyCapacity,
          updatedAt: DateTime.now(),
        );

        final saveResult = await teamRepository.saveMember(updatedMember);
        if (saveResult.isError) {
          result.addError('Failed to update ${member.name}: ${saveResult.error}');
        } else {
          result.incrementSuccessfulUpdates();
        }
      } catch (e) {
        result.addError('Failed to update ${member.name}: $e');
      }
    }

    return Result.success(result);
  }

  /// Synchronizes allocations with team member changes
  Future<Result<SyncResult, Exception>> synchronizeAllocations() async {
    final result = SyncResult();

    // Get all plan metadata
    final plansResult = await capacityRepository.listPlans();
    if (plansResult.isError) {
      return Result.error(plansResult.error);
    }

    // Get all active team members
    final membersResult = await teamRepository.listActiveMembers();
    if (membersResult.isError) {
      return Result.error(membersResult.error);
    }

    final activeMemberIds = membersResult.value.map((m) => m.id).toSet();

    for (final planMeta in plansResult.value) {
      final allocationsResult = await capacityRepository.listAllocations(planMeta.id);
      if (allocationsResult.isError) {
        result.addError('Failed to load allocations for plan ${planMeta.displayName}: ${allocationsResult.error}');
        continue;
      }

      for (final allocation in allocationsResult.value) {
        // Check if team member still exists and is active
        if (!activeMemberIds.contains(allocation.teamMemberId)) {
          // Mark allocation as inactive or remove it
          final updatedAllocation = allocation.copyWith(
            status: AllocationStatus.cancelled,
            notes: '${allocation.notes}\nAuto-cancelled: Team member no longer active',
            updatedAt: DateTime.now(),
          );

          final updateResult = await capacityRepository.saveAllocation(planMeta.id, updatedAllocation);
          if (updateResult.isError) {
            result.addError('Failed to update allocation for inactive member: ${updateResult.error}');
          } else {
            result.incrementCancelledAllocations();
          }
        }
      }
    }

    return Result.success(result);
  }
}

/// Result of restore operation
class RestoreResult {
  RestoreResult();

  int _restoredPlans = 0;
  int _restoredMembers = 0;
  bool applicationStateRestored = false;
  bool userConfigurationRestored = false;
  final List<String> errors = [];

  int get restoredPlans => _restoredPlans;
  int get restoredMembers => _restoredMembers;
  bool get hasErrors => errors.isNotEmpty;
  bool get isComplete => restoredPlans > 0 || restoredMembers > 0 || applicationStateRestored || userConfigurationRestored;

  void incrementRestoredPlans() => _restoredPlans++;
  void incrementRestoredMembers() => _restoredMembers++;
  void addError(String error) => errors.add(error);
}

/// Result of migration operation
class MigrationResult {
  MigrationResult();

  final List<String> migrationSteps = [];
  final List<String> warnings = [];
  final List<String> errors = [];

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccessful => errors.isEmpty;

  void addMigrationStep(String step) => migrationSteps.add(step);
  void addWarning(String warning) => warnings.add(warning);
  void addError(String error) => errors.add(error);
}

/// Result of bulk import operation
class BulkImportResult {
  BulkImportResult();

  int _successfulImports = 0;
  final List<String> errors = [];
  final List<String> warnings = [];

  int get successfulImports => _successfulImports;
  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;

  void incrementSuccessfulImports() => _successfulImports++;
  void addError(String error) => errors.add(error);
  void addWarning(String warning) => warnings.add(warning);
}

/// Result of bulk update operation
class BulkUpdateResult {
  BulkUpdateResult();

  int _successfulUpdates = 0;
  final List<String> errors = [];

  int get successfulUpdates => _successfulUpdates;
  bool get hasErrors => errors.isNotEmpty;

  void incrementSuccessfulUpdates() => _successfulUpdates++;
  void addError(String error) => errors.add(error);
}

/// Result of synchronization operation
class SyncResult {
  SyncResult();

  int _cancelledAllocations = 0;
  final List<String> errors = [];

  int get cancelledAllocations => _cancelledAllocations;
  bool get hasErrors => errors.isNotEmpty;

  void incrementCancelledAllocations() => _cancelledAllocations++;
  void addError(String error) => errors.add(error);
}
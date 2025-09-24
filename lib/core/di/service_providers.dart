/// Service providers for dependency injection using Provider package.
/// 
/// This file contains all the Provider configurations needed to inject
/// repositories, use cases, and other services throughout the application.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Repository interfaces
import '../../features/capacity_planning/domain/repositories/capacity_planning_repository.dart';
import '../../features/team_management/domain/repositories/team_management_repository.dart';
import '../../features/configuration/domain/repositories/configuration_repository.dart';

// Repository implementations
import '../../features/capacity_planning/data/repositories/capacity_planning_repository_impl.dart';
import '../../features/team_management/data/repositories/team_management_repository_impl.dart';
import '../../features/configuration/data/repositories/configuration_repository_impl.dart';

// Individual use cases - Capacity Planning
import '../../features/capacity_planning/domain/usecases/capacity_planning_usecases.dart';

// Individual use cases - Team Management  
import '../../features/team_management/domain/usecases/team_management_usecases.dart';

// Individual use cases - Configuration
import '../../features/configuration/domain/usecases/configuration_usecases.dart';

// Integration use cases
import '../usecases/integration_usecases.dart';

/// Service locator for managing application dependencies
class ServiceProviders {
  ServiceProviders._();

  /// Creates all provider configurations for the application
  /// 
  /// This method returns a list of providers that should be used with
  /// MultiProvider to inject all required dependencies.
  static List<Provider> createProviders() {
    return [
      // Core services
      Provider<SharedPreferences>.value(
        value: _sharedPreferences!,
      ),
      
      // Repositories
      Provider<CapacityPlanningRepository>(
        create: (context) => CapacityPlanningRepositoryImpl(
          context.read<SharedPreferences>(),
        ),
      ),
      
      Provider<TeamManagementRepository>(
        create: (context) => TeamManagementRepositoryImpl(
          context.read<SharedPreferences>(),
        ),
      ),
      
      Provider<ConfigurationRepository>(
        create: (context) => ConfigurationRepositoryImpl(
          context.read<SharedPreferences>(),
        ),
      ),
      
      // Individual use cases - Capacity Planning
      Provider<CreateQuarterPlan>(
        create: (context) => CreateQuarterPlan(
          capacityRepository: context.read<CapacityPlanningRepository>(),
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      Provider<LoadQuarterPlan>(
        create: (context) => LoadQuarterPlan(
          capacityRepository: context.read<CapacityPlanningRepository>(),
        ),
      ),
      
      Provider<AddInitiativeToPlan>(
        create: (context) => AddInitiativeToPlan(
          capacityRepository: context.read<CapacityPlanningRepository>(),
        ),
      ),
      
      Provider<AllocateCapacity>(
        create: (context) => AllocateCapacity(
          capacityRepository: context.read<CapacityPlanningRepository>(),
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      Provider<GetCapacityAnalytics>(
        create: (context) => GetCapacityAnalytics(
          capacityRepository: context.read<CapacityPlanningRepository>(),
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      // Individual use cases - Team Management
      Provider<AddTeamMember>(
        create: (context) => AddTeamMember(
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      Provider<UpdateTeamMember>(
        create: (context) => UpdateTeamMember(
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      Provider<ManageTeamMemberAvailability>(
        create: (context) => ManageTeamMemberAvailability(
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      Provider<AnalyzeTeamCapacity>(
        create: (context) => AnalyzeTeamCapacity(
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      Provider<SearchTeamMembers>(
        create: (context) => SearchTeamMembers(
          teamRepository: context.read<TeamManagementRepository>(),
        ),
      ),
      
      // Individual use cases - Configuration
      Provider<ManageApplicationState>(
        create: (context) => ManageApplicationState(
          configRepository: context.read<ConfigurationRepository>(),
        ),
      ),
      
      Provider<ManageUserConfiguration>(
        create: (context) => ManageUserConfiguration(
          configRepository: context.read<ConfigurationRepository>(),
        ),
      ),
      
      Provider<InitializeApplication>(
        create: (context) => InitializeApplication(
          configRepository: context.read<ConfigurationRepository>(),
        ),
      ),
      
      // Integration use cases
      Provider<BackupAndRestoreData>(
        create: (context) => BackupAndRestoreData(
          capacityRepository: context.read<CapacityPlanningRepository>(),
          teamRepository: context.read<TeamManagementRepository>(),
          configRepository: context.read<ConfigurationRepository>(),
        ),
      ),
      
      Provider<MigrateApplicationData>(
        create: (context) => MigrateApplicationData(
          capacityRepository: context.read<CapacityPlanningRepository>(),
          teamRepository: context.read<TeamManagementRepository>(),
          configRepository: context.read<ConfigurationRepository>(),
        ),
      ),
      
      Provider<BulkDataOperations>(
        create: (context) => BulkDataOperations(
          capacityRepository: context.read<CapacityPlanningRepository>(),
          teamRepository: context.read<TeamManagementRepository>(),
          configRepository: context.read<ConfigurationRepository>(),
        ),
      ),
    ];
  }

  /// Creates ProxyProvider configurations for complex dependencies
  /// 
  /// Some services might need multiple dependencies or complex initialization.
  /// This method provides ProxyProvider configurations for such cases.
  static List<ProxyProvider> createProxyProviders() {
    return [
      // Example: If we need a service that depends on multiple repositories
      // ProxyProvider3<CapacityPlanningRepository, TeamManagementRepository, ConfigurationRepository, SomeComplexService>(
      //   update: (context, capacityRepo, teamRepo, configRepo, previous) =>
      //       SomeComplexService(capacityRepo, teamRepo, configRepo),
      // ),
    ];
  }

  // Static instance to hold SharedPreferences
  static SharedPreferences? _sharedPreferences;

  /// Initialize the service providers
  /// 
  /// This must be called before creating providers, typically in main().
  static Future<void> initialize() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  /// 
  /// Throws if not initialized.
  static SharedPreferences get sharedPreferences {
    if (_sharedPreferences == null) {
      throw StateError('ServiceProviders not initialized. Call initialize() first.');
    }
    return _sharedPreferences!;
  }

  /// Dispose resources
  /// 
  /// Call this when the app is shutting down to clean up resources.
  static void dispose() {
    // Currently no resources need explicit disposal
    // But this method is here for future use
  }
}

/// Extension methods for easier access to services from BuildContext
extension ServiceProvidersContext on BuildContext {
  // Repositories
  CapacityPlanningRepository get capacityPlanningRepository => 
      read<CapacityPlanningRepository>();

  TeamManagementRepository get teamManagementRepository => 
      read<TeamManagementRepository>();

  ConfigurationRepository get configurationRepository => 
      read<ConfigurationRepository>();

  SharedPreferences get sharedPreferences => 
      read<SharedPreferences>();

  // Capacity Planning Use Cases
  CreateQuarterPlan get createQuarterPlan => read<CreateQuarterPlan>();
  LoadQuarterPlan get loadQuarterPlan => read<LoadQuarterPlan>();
  AddInitiativeToPlan get addInitiativeToPlan => read<AddInitiativeToPlan>();
  AllocateCapacity get allocateCapacity => read<AllocateCapacity>();
  GetCapacityAnalytics get getCapacityAnalytics => read<GetCapacityAnalytics>();

  // Team Management Use Cases
  AddTeamMember get addTeamMember => read<AddTeamMember>();
  UpdateTeamMember get updateTeamMember => read<UpdateTeamMember>();
  ManageTeamMemberAvailability get manageTeamMemberAvailability => read<ManageTeamMemberAvailability>();
  AnalyzeTeamCapacity get analyzeTeamCapacity => read<AnalyzeTeamCapacity>();
  SearchTeamMembers get searchTeamMembers => read<SearchTeamMembers>();

  // Configuration Use Cases
  ManageApplicationState get manageApplicationState => read<ManageApplicationState>();
  ManageUserConfiguration get manageUserConfiguration => read<ManageUserConfiguration>();
  InitializeApplication get initializeApplication => read<InitializeApplication>();

  // Integration Use Cases
  BackupAndRestoreData get backupAndRestoreData => read<BackupAndRestoreData>();
  MigrateApplicationData get migrateApplicationData => read<MigrateApplicationData>();
  BulkDataOperations get bulkDataOperations => read<BulkDataOperations>();
}

/// Helper for testing - provides mock implementations
class TestServiceProviders {
  /// Creates providers with mock implementations for testing
  static List<Provider> createMockProviders({
    CapacityPlanningRepository? capacityPlanningRepository,
    TeamManagementRepository? teamManagementRepository,
    ConfigurationRepository? configurationRepository,
    SharedPreferences? sharedPreferences,
  }) {
    // This would typically use mock implementations
    // For now, we'll use the real implementations with test data
    throw UnimplementedError('Mock providers not yet implemented');
  }
}
/// Main entry point for the Capacity Estimation Timeline application.
/// 
/// This file sets up the application with proper dependency injection,
/// state management, and routing using Provider and MultiProvider.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import 'core/di/service_providers.dart';
import 'shared/themes/app_theme.dart';

// Feature providers
import 'features/capacity_planning/presentation/providers/capacity_planning_providers.dart';
import 'features/team_management/presentation/providers/team_management_providers.dart';
import 'features/configuration/presentation/providers/configuration_providers.dart';

// Navigation
import 'core/navigation/app_router.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize service providers
  await ServiceProviders.initialize();
  
  runApp(const CapacityTimelineApp());
}

class CapacityTimelineApp extends StatelessWidget {
  const CapacityTimelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Service providers (repositories and use cases)
        ...ServiceProviders.createProviders(),
        
        // UI state management providers
        ChangeNotifierProvider<QuarterPlanProvider>(
          create: (context) => QuarterPlanProvider(
            createQuarterPlan: context.read(),
            loadQuarterPlan: context.read(),
            getCapacityAnalytics: context.read(),
          ),
        ),
        
        ChangeNotifierProvider<InitiativeProvider>(
          create: (context) => InitiativeProvider(
            addInitiativeToPlan: context.read(),
          ),
        ),
        
        ChangeNotifierProvider<AllocationProvider>(
          create: (context) => AllocationProvider(
            allocateCapacity: context.read(),
          ),
        ),
        
        ChangeNotifierProvider<TeamMemberProvider>(
          create: (context) => TeamMemberProvider(
            addTeamMember: context.read(),
            updateTeamMember: context.read(),
            searchTeamMembers: context.read(),
          ),
        ),
        
        ChangeNotifierProvider<AvailabilityProvider>(
          create: (context) => AvailabilityProvider(
            manageAvailability: context.read(),
          ),
        ),
        
        ChangeNotifierProvider<TeamCapacityProvider>(
          create: (context) => TeamCapacityProvider(
            analyzeCapacity: context.read(),
          ),
        ),
        
        ChangeNotifierProvider<ApplicationStateProvider>(
          create: (context) => ApplicationStateProvider(
            manageApplicationState: context.read(),
            initializeApplication: context.read(),
          ),
        ),
        
        ChangeNotifierProvider<UserConfigurationProvider>(
          create: (context) => UserConfigurationProvider(
            manageUserConfiguration: context.read(),
          ),
        ),
      ],
      child: Consumer<UserConfigurationProvider>(
        builder: (context, userConfig, child) {
          return MaterialApp(
            title: 'Capacity Timeline',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _getThemeMode(userConfig.currentTheme),
            navigatorKey: AppRouter.navigatorKey,
            onGenerateRoute: AppRouter.generateRoute,
            onUnknownRoute: AppRouter.unknownRoute,
            initialRoute: AppRouter.home,
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}



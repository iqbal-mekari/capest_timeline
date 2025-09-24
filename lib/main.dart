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

// Screens
import 'screens/app_shell.dart';

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
            home: const AppInitializer(),
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

/// Widget that handles application initialization
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final appStateProvider = context.read<ApplicationStateProvider>();
    final userConfigProvider = context.read<UserConfigurationProvider>();
    
    // Initialize application state and user configuration
    await Future.wait([
      appStateProvider.initialize(),
      userConfigProvider.loadUserConfiguration(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ApplicationStateProvider, UserConfigurationProvider>(
      builder: (context, appState, userConfig, child) {
        // Show loading screen while initializing
        if (appState.isLoading || userConfig.isLoading) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Initializing Capacity Timeline...'),
                ],
              ),
            ),
          );
        }

        // Show error screen if initialization failed
        if (appState.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize application',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appState.error ?? 'Unknown error occurred',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeApp,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // Show main application
        return const AppShell();
      },
    );
  }
}

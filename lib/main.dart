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
import 'features/configuration/presentation/providers/configuration_provider.dart';

// Screens
import 'screens/main_screen.dart';

// Shared widgets
import 'shared/widgets/error_boundary.dart';

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
    return ErrorBoundary(
      errorTitle: 'Application Error',
      errorMessage: 'The Capacity Timeline app encountered an unexpected error.',
      onError: (error, stackTrace) {
        // TODO: Log error to analytics/crash reporting service
        debugPrint('App-level error: $error');
      },
      child: MultiProvider(
        providers: ServiceProviders.createProviders(),
        child: Consumer<ConfigurationProvider>(
          builder: (context, configProvider, child) {
            return MaterialApp(
              title: 'Capacity Timeline',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: _getThemeMode(configProvider.theme),
              home: const MainScreen(),
            );
          },
        ),
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



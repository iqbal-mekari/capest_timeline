/// Main entry point for the Capacity Estimation Timeline application.
/// 
/// Simplified version for manual testing without complex Provider setup.
library;

import 'package:flutter/material.dart';

// Core imports
import 'shared/themes/app_theme.dart';

// Screens
import 'screens/main_screen_simple.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const CapacityTimelineApp());
}

class CapacityTimelineApp extends StatelessWidget {
  const CapacityTimelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capacity Timeline',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const MainScreen(),
    );
  }
}



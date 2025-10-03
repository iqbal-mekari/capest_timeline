/// Main entry point for the complete Kanban Timeline application.
/// 
/// This version uses the full KanbanBoardWidget with Provider setup for
/// complete drag-and-drop timeline functionality.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core imports
import 'shared/themes/app_theme.dart';

// Services
import 'services/kanban_service.dart';
import 'services/capacity_service.dart';
import 'services/storage_service.dart';

// Providers
import 'providers/kanban_provider.dart';

// Widgets
import 'widgets/kanban_board_widget.dart';
import 'widgets/create_initiative_widget.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(KanbanTimelineApp(preferences: prefs));
}

class KanbanTimelineApp extends StatelessWidget {
  final SharedPreferences preferences;

  const KanbanTimelineApp({
    super.key,
    required this.preferences,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Service providers
        Provider<StorageService>(
          create: (_) => StorageService(sharedPreferences: preferences),
        ),
        Provider<CapacityService>(
          create: (_) => CapacityService(),
        ),
        Provider<KanbanService>(
          create: (context) => KanbanService(
            storageService: context.read<StorageService>(),
            capacityService: context.read<CapacityService>(),
          ),
        ),
        
        // State providers
        ChangeNotifierProvider<KanbanProvider>(
          create: (context) => KanbanProvider(
            kanbanService: context.read<KanbanService>(),
            capacityService: context.read<CapacityService>(),
            storageService: context.read<StorageService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Capacity Timeline',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const KanbanTimelineScreen(),
      ),
    );
  }
}

class KanbanTimelineScreen extends StatefulWidget {
  const KanbanTimelineScreen({super.key});

  @override
  State<KanbanTimelineScreen> createState() => _KanbanTimelineScreenState();
}

class _KanbanTimelineScreenState extends State<KanbanTimelineScreen> {
  bool _showCreateInitiative = false;

  @override
  void initState() {
    super.initState();
    // Initialize the kanban provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KanbanProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Capacity Timeline'),
      actions: [
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
        ),
        IconButton(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_showCreateInitiative) {
      return _buildCreateInitiativeView();
    }
    
    return const KanbanBoardWidget();
  }

  Widget _buildCreateInitiativeView() {
    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _showCreateInitiative = false),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to Timeline',
              ),
              const SizedBox(width: 8),
              Text(
                'Create Initiative',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        
        // Create initiative form
        Expanded(
          child: CreateInitiativeWidget(
            onInitiativeCreated: (initiative) {
              // Initiative created successfully
              setState(() => _showCreateInitiative = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Initiative "${initiative.title}" created successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onCancel: () {
              setState(() => _showCreateInitiative = false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    if (_showCreateInitiative) {
      return null; // Hide FAB when creating initiative
    }

    return FloatingActionButton.extended(
      onPressed: () => setState(() => _showCreateInitiative = true),
      icon: const Icon(Icons.add),
      label: const Text('Create Initiative'),
      tooltip: 'Create New Initiative',
    );
  }

  void _refreshData() {
    context.read<KanbanProvider>().refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data refreshed successfully')),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kanban Timeline Help'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity Planning Timeline'),
            SizedBox(height: 16),
            Text('• Drag initiatives between weeks to reschedule'),
            Text('• View capacity utilization with color indicators'),
            Text('• Create new initiatives with the + button'),
            Text('• Green: Normal capacity, Yellow: High, Orange: Near limit, Red: Over-allocated'),
            SizedBox(height: 16),
            Text('This is the complete Kanban board implementation with full functionality.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
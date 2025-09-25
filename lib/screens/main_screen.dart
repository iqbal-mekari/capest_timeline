import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/team_management/presentation/providers/team_management_provider.dart';
import '../features/configuration/presentation/providers/configuration_provider.dart';
import '../features/capacity_planning/presentation/providers/capacity_planning_provider.dart';
import '../features/team_management/presentation/widgets/team_member_card.dart';
import '../features/capacity_planning/presentation/widgets/initiative_card.dart';
import '../shared/widgets/loading_states.dart';

/// Main application screen that provides navigation and layout for capacity planning features.
///
/// This screen serves as the primary interface for:
/// - Team member management and allocation
/// - Initiative tracking and capacity planning
/// - Application configuration and settings
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize providers after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeProviders() {
    // Load team management data
    context.read<TeamManagementProvider>().loadTeamMembers();
    
    // Load user configuration
    context.read<ConfigurationProvider>().loadConfiguration();
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
      title: const Text('Capacity Planning Timeline'),
      actions: [
        // Refresh data
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
        ),
        
        // Settings
        IconButton(
          onPressed: _openSettings,
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
        
        // Help
        IconButton(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            icon: Icon(Icons.group),
            text: 'Team',
          ),
          Tab(
            icon: Icon(Icons.assignment),
            text: 'Initiatives',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: 'Analytics',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTeamView(),
        _buildInitiativesView(),
        _buildAnalyticsView(),
      ],
    );
  }

  Widget _buildTeamView() {
    return Consumer<TeamManagementProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const CTASkeletonLoader(
            itemCount: 5,
            itemHeight: 100.0,
          );
        }

        if (provider.teamMembers.isEmpty) {
          return CTAEmptyState(
            icon: Icons.group_outlined,
            title: 'No team members found',
            message: 'Add team members to start capacity planning',
            actionLabel: 'Add Team Member',
            onAction: _addTeamMember,
          );
        }

        return Column(
          children: [
            // Search and filter bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search team members...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        provider.updateSearchQuery(value);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filter team members',
                    onSelected: (value) {
                      // TODO: Implement role filtering
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('All Roles'),
                      ),
                      const PopupMenuItem(
                        value: 'backend',
                        child: Text('Backend'),
                      ),
                      const PopupMenuItem(
                        value: 'frontend',
                        child: Text('Frontend'),
                      ),
                      const PopupMenuItem(
                        value: 'mobile',
                        child: Text('Mobile'),
                      ),
                      const PopupMenuItem(
                        value: 'qa',
                        child: Text('QA'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Team members list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: provider.teamMembers.length,
                itemBuilder: (context, index) {
                  final teamMember = provider.teamMembers[index];
                  return TeamMemberCard(
                    teamMember: teamMember,
                    onTap: () => _selectTeamMember(teamMember),
                    onEdit: () => _editTeamMember(teamMember.id),
                    onAssign: () => _assignTeamMember(teamMember.id),
                    onViewDetails: () => _viewTeamMemberDetails(teamMember.id),
                    isSelected: provider.selectedMember?.id == teamMember.id,
                    currentUtilization: _getTeamMemberUtilization(teamMember.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInitiativesView() {
    return Consumer<CapacityPlanningProvider>(
      builder: (context, provider, child) {
        final initiatives = provider.currentPlan?.initiatives ?? [];
        
        if (initiatives.isEmpty) {
          return CTAEmptyState(
            icon: Icons.assignment_outlined,
            title: 'No initiatives found',
            message: 'Create your first initiative to start capacity planning',
            actionLabel: 'Create Initiative',
            onAction: _createInitiative,
          );
        }

        return Column(
          children: [
            // Search and filter bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search initiatives...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        // TODO: Implement initiative search
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Filter initiatives',
                    onSelected: (value) {
                      // TODO: Implement filtering
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('All Initiatives'),
                      ),
                      const PopupMenuItem(
                        value: 'high_priority',
                        child: Text('High Priority'),
                      ),
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Text('In Progress'),
                      ),
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Completed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Initiatives list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: initiatives.length,
                itemBuilder: (context, index) {
                  final initiative = initiatives[index];
                  return InitiativeCard(
                    initiative: initiative,
                    onTap: () => _selectInitiative(initiative.id),
                    onEdit: () => _editInitiative(initiative.id),
                    onAssignTeam: () => _assignTeamToInitiative(initiative.id),
                    onViewDetails: () => _viewInitiativeDetails(initiative.id),
                    isSelected: false, // TODO: Add selection state to capacity provider
                    completionPercentage: _getInitiativeProgress(initiative.id),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsView() {
    return Consumer2<CapacityPlanningProvider, TeamManagementProvider>(
      builder: (context, capacityProvider, teamProvider, child) {
        final initiatives = capacityProvider.currentPlan?.initiatives ?? [];
        final teamMembers = teamProvider.teamMembers;
        final allocations = capacityProvider.currentPlan?.allocations ?? [];
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capacity Analytics',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Key metrics cards
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildMetricCard(
                      'Total Initiatives',
                      '${initiatives.length}',
                      Icons.assignment,
                      Theme.of(context).colorScheme.primary,
                    ),
                    _buildMetricCard(
                      'Team Members',
                      '${teamMembers.length}',
                      Icons.group,
                      Theme.of(context).colorScheme.secondary,
                    ),
                    _buildMetricCard(
                      'Active Allocations',
                      '${allocations.length}',
                      Icons.timeline,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      'Avg Utilization',
                      '${_calculateAverageUtilization().toStringAsFixed(1)}%',
                      Icons.analytics,
                      Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final tabIndex = _tabController.index;
    
    switch (tabIndex) {
      case 0: // Team
        return FloatingActionButton(
          onPressed: _addTeamMember,
          tooltip: 'Add Team Member',
          child: const Icon(Icons.person_add),
        );
      case 1: // Initiatives
        return FloatingActionButton(
          onPressed: _createInitiative,
          tooltip: 'Create Initiative',
          child: const Icon(Icons.assignment_add),
        );
      default:
        return null;
    }
  }

  // Action methods
  void _refreshData() async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            CTAInlineLoader(size: 16),
            SizedBox(width: 12),
            Text('Refreshing data...'),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
    
    // Refresh data
    await context.read<TeamManagementProvider>().loadTeamMembers();
    await context.read<ConfigurationProvider>().loadConfiguration();
    
    // Hide loading and show success
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data refreshed successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSettings() {
    // TODO: Navigate to settings screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings screen coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    // TODO: Show help dialog or navigate to help screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Capacity Planning Timeline Help'),
            SizedBox(height: 16),
            Text('• Manage team members in the Team tab'),
            Text('• Create and track initiatives in the Initiatives tab'),
            Text('• View analytics and metrics in the Analytics tab'),
            SizedBox(height: 16),
            Text('For more help, visit the documentation.'),
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

  // Initiative actions
  void _createInitiative() {
    // TODO: Show create initiative dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create initiative feature coming soon!')),
    );
  }

  void _selectInitiative(String initiativeId) {
    // TODO: Add selection state to capacity provider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected initiative $initiativeId')),
    );
  }

  void _editInitiative(String initiativeId) {
    // TODO: Show edit initiative dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit initiative $initiativeId feature coming soon!')),
    );
  }

  void _assignTeamToInitiative(String initiativeId) {
    // TODO: Show team assignment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assign team to initiative $initiativeId feature coming soon!')),
    );
  }

  void _viewInitiativeDetails(String initiativeId) {
    // TODO: Navigate to initiative details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View initiative $initiativeId details feature coming soon!')),
    );
  }

  // Team member actions
  void _addTeamMember() {
    // TODO: Show add team member dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add team member feature coming soon!')),
    );
  }

  void _selectTeamMember(dynamic teamMember) {
    context.read<TeamManagementProvider>().selectTeamMember(teamMember);
  }

  void _editTeamMember(String teamMemberId) {
    // TODO: Show edit team member dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit team member $teamMemberId feature coming soon!')),
    );
  }

  void _assignTeamMember(String teamMemberId) {
    // TODO: Show assignment dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assign team member $teamMemberId feature coming soon!')),
    );
  }

  void _viewTeamMemberDetails(String teamMemberId) {
    // TODO: Navigate to team member details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View team member $teamMemberId details feature coming soon!')),
    );
  }

  // Helper methods
  double _getInitiativeProgress(String initiativeId) {
    // TODO: Calculate actual progress from allocations
    return 0.0;
  }

  double _getTeamMemberUtilization(String teamMemberId) {
    // TODO: Calculate actual utilization from allocations
    return 0.0;
  }

  double _calculateAverageUtilization() {
    // TODO: Calculate actual average utilization
    return 0.0;
  }
}
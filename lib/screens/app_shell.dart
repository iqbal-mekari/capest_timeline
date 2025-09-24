/// Main application shell providing navigation and layout structure.
/// 
/// The AppShell serves as the primary navigation container for the 
/// Capacity Timeline application, managing the overall layout and
/// routing between major feature sections.
library;

import 'package:flutter/material.dart';
import '../shared/widgets/common_widgets.dart';
import '../features/capacity_planning/presentation/screens/capacity_planning_screen.dart';
import '../features/team_management/presentation/screens/team_management_screen.dart';

/// Main application shell widget
class AppShell extends StatefulWidget {
  final String title;
  
  const AppShell({
    super.key,
    this.title = 'Capacity Timeline',
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  /// Handle navigation item tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Show the about dialog
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Capacity Planning Timeline',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.timeline, size: 64),
      children: [
        const Text('A comprehensive tool for team capacity planning and timeline management.'),
      ],
    );
  }

  /// Show the help dialog
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Getting Started:', style: TextStyle(fontWeight: FontWeight.w600)),
            Text('• Use the Planning tab to create and manage initiatives'),
            Text('• Add team members in the Team tab'),
            Text('• View progress and metrics in Analytics'),
            SizedBox(height: 16),
            Text('For more help, visit our documentation or contact support.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildPlanningView(),
          _buildTeamView(),
          _buildAnalyticsView(),
          _buildSettingsView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Planning',
            tooltip: 'Capacity Planning',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Team',
            tooltip: 'Team Management',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
            tooltip: 'Capacity Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'Configuration',
          ),
        ],
      ),
    );
  }

  /// Build the capacity planning view
  Widget _buildPlanningView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick stats cards
          Row(
            children: [
              Expanded(
                child: CTAInfoCard(
                  title: 'Active Initiatives',
                  value: '0',
                  icon: Icons.assignment,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: CTAInfoCard(
                  title: 'Total Capacity',
                  value: '0.0w',
                  subtitle: 'This quarter',
                  icon: Icons.schedule,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Empty state for initiatives
          Expanded(
            child: CTAEmptyState(
              icon: Icons.timeline,
              title: 'No Quarter Plans Yet',
              message: 'Create your first quarter plan to start managing team capacity and initiatives.',
              actionLabel: 'Open Capacity Planning',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CapacityPlanningScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the team management view
  Widget _buildTeamView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Team stats
          Row(
            children: [
              Expanded(
                child: CTAInfoCard(
                  title: 'Team Members',
                  value: '0',
                  icon: Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: CTAInfoCard(
                  title: 'Available Capacity',
                  value: '0%',
                  subtitle: 'This week',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Empty state for team members
          Expanded(
            child: CTAEmptyState(
              icon: Icons.people_outline,
              title: 'No Team Members Yet',
              message: 'Add team members to start tracking their capacity and availability.',
              actionLabel: 'Open Team Management',
              onAction: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TeamManagementScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the analytics view
  Widget _buildAnalyticsView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Analytics cards
          Row(
            children: [
              Expanded(
                child: CTAInfoCard(
                  title: 'Utilization',
                  value: '0%',
                  subtitle: 'Team average',
                  icon: Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: CTAInfoCard(
                  title: 'Efficiency',
                  value: '0%',
                  subtitle: 'vs. planned',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Empty state for analytics
          Expanded(
            child: CTAEmptyState(
              icon: Icons.bar_chart,
              title: 'No Analytics Data',
              message: 'Analytics will be available once you have team members and active initiatives.',
              actionLabel: 'View Sample Dashboard',
              onAction: () {
                // TODO: Show sample analytics
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sample analytics coming soon!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the settings view
  Widget _buildSettingsView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Application Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Settings cards
          CTACard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: const Text('Theme'),
                  subtitle: const Text('Light, Dark, or System'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme settings coming soon!')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage notification preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon!')),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Default Values'),
                  subtitle: const Text('Quarter weeks, capacity, etc.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Default settings coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          CTACard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About'),
                  subtitle: const Text('App version and information'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help & Support'),
                  subtitle: const Text('Get help using the app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showHelpDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
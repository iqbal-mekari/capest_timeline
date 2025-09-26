/// Capacity planning screen for managing quarter plans and initiatives.
/// 
/// This screen provides the main interface for creating and managing
/// quarterly capacity plans, including initiative tracking, team
/// assignment, and capacity allocation management.
library;

import 'package:flutter/material.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// Main capacity planning screen
class CapacityPlanningScreen extends StatefulWidget {
  const CapacityPlanningScreen({super.key});

  @override
  State<CapacityPlanningScreen> createState() => _CapacityPlanningScreenState();
}

class _CapacityPlanningScreenState extends State<CapacityPlanningScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _hasData = true; // Simulated data state - set to true to show sample data

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capacity Planning'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_view_week), text: 'Quarters'),
            Tab(icon: Icon(Icons.assignment), text: 'Initiatives'),
            Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateQuarterDialog(context),
            tooltip: 'Create Quarter Plan',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuartersTab(),
          _buildInitiativesTab(),
          _buildTimelineTab(),
        ],
      ),
    );
  }

  /// Build the quarters management tab
  Widget _buildQuartersTab() {
    if (!_hasData) {
      return CTAEmptyState(
        icon: Icons.calendar_view_week,
        title: 'No Quarter Plans',
        message: 'Create your first quarter plan to start managing capacity and initiatives.',
        actionLabel: 'Create Quarter Plan',
        onAction: () => _showCreateQuarterDialog(context),
      );
    }

    // Sample data for demonstration
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2, // Sample count
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CTACard(
              onTap: () => _navigateToQuarterDetails('q${index + 1}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        index == 0 ? 'Q1 2024' : 'Q2 2024',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: index == 0 ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          index == 0 ? 'ACTIVE' : 'PLANNING',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: index == 0 ? Colors.green : Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    index == 0 ? '2024-01-01 - 2024-03-31' : '2024-04-01 - 2024-06-30',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quarter metrics
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuarterMetric(
                          context,
                          'Initiatives',
                          index == 0 ? '5' : '3',
                          Icons.assignment,
                        ),
                      ),
                      Expanded(
                        child: _buildQuarterMetric(
                          context,
                          'Team Capacity',
                          index == 0 ? '48.0w' : '36.0w',
                          Icons.people,
                        ),
                      ),
                      Expanded(
                        child: _buildQuarterMetric(
                          context,
                          'Utilization',
                          index == 0 ? '85%' : '72%',
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            index == 0 ? '68%' : '24%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: index == 0 ? 0.68 : 0.24,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build a quarter metric widget
  Widget _buildQuarterMetric(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Build the initiatives management tab
  Widget _buildInitiativesTab() {
    if (!_hasData) {
      return CTAEmptyState(
        icon: Icons.assignment,
        title: 'No Initiatives',
        message: 'Create a quarter plan first, then add initiatives to track work and capacity.',
        actionLabel: 'Create Quarter Plan',
        onAction: () => _showCreateQuarterDialog(context),
      );
    }

    // Sample data for demonstration
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Sample count
        itemBuilder: (context, index) {
          final sampleData = [
            {
              'title': 'Mobile App Redesign',
              'description': 'Complete redesign of the mobile application with new UX patterns',
              'status': 'In Progress',
              'progress': 0.65,
              'weeks': 8.0,
              'members': 4,
            },
            {
              'title': 'API Migration',
              'description': 'Migrate legacy API endpoints to new GraphQL schema',
              'status': 'Planning',
              'progress': 0.15,
              'weeks': 6.0,
              'members': 3,
            },
            {
              'title': 'Performance Optimization',
              'description': 'Optimize application performance and reduce load times',
              'status': 'Not Started',
              'progress': 0.0,
              'weeks': 4.0,
              'members': 2,
            },
          ];
          
          final data = sampleData[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CTAInitiativeCard(
              title: data['title'] as String,
              description: data['description'] as String,
              status: data['status'] as String,
              estimatedWeeks: data['weeks'] as double,
              priority: index + 1,
              businessValue: (index + 1) * 2,
              onTap: () => _navigateToInitiativeDetails('init_$index'),
              onEdit: () => _showEditInitiativeDialog('init_$index'),
            ),
          );
        },
      ),
    );
  }

  /// Build the timeline view tab
  Widget _buildTimelineTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Timeline View',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Interactive timeline visualization coming soon',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Show create quarter dialog
  void _showCreateQuarterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateQuarterDialog(),
    );
  }

  /// Navigate to quarter details
  void _navigateToQuarterDetails(String quarterId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuarterDetailsScreen(quarterId: quarterId),
      ),
    );
  }

  /// Navigate to initiative details
  void _navigateToInitiativeDetails(String initiativeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InitiativeDetailsScreen(initiativeId: initiativeId),
      ),
    );
  }

  /// Show edit initiative dialog
  void _showEditInitiativeDialog(String initiativeId) {
    showDialog(
      context: context,
      builder: (context) => EditInitiativeDialog(initiativeId: initiativeId),
    );
  }
}

// TODO: Implement these dialogs and screens
class CreateQuarterDialog extends StatelessWidget {
  const CreateQuarterDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Quarter Plan'),
      content: const Text('Quarter plan creation form coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class QuarterDetailsScreen extends StatelessWidget {
  final String quarterId;
  
  const QuarterDetailsScreen({super.key, required this.quarterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quarter Details')),
      body: const Center(child: Text('Quarter details screen coming soon!')),
    );
  }
}

class InitiativeDetailsScreen extends StatelessWidget {
  final String initiativeId;
  
  const InitiativeDetailsScreen({super.key, required this.initiativeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Initiative Details')),
      body: const Center(child: Text('Initiative details screen coming soon!')),
    );
  }
}

class EditInitiativeDialog extends StatelessWidget {
  final String initiativeId;
  
  const EditInitiativeDialog({super.key, required this.initiativeId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Initiative'),
      content: const Text('Initiative editing form coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
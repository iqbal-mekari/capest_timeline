/// Analytics dashboard screen for capacity and performance insights.
/// 
/// This screen provides comprehensive analytics and visualizations for
/// team capacity utilization, project progress, and performance metrics.
library;

import 'package:flutter/material.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// Main analytics dashboard screen
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTimeframe = 'This Quarter';
  final bool _hasData = true; // Simulated data state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Analytics Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Capacity'),
            Tab(icon: Icon(Icons.assignment), text: 'Projects'),
            Tab(icon: Icon(Icons.people), text: 'Team'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedTimeframe = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(value: 'This Quarter', child: Text('This Quarter')),
              const PopupMenuItem(value: 'This Year', child: Text('This Year')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedTimeframe,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildCapacityTab(),
          _buildProjectsTab(),
          _buildTeamTab(),
        ],
      ),
    );
  }

  /// Build the overview dashboard tab
  Widget _buildOverviewTab() {
    if (!_hasData) {
      return CTAEmptyState(
        icon: Icons.analytics,
        title: 'No Analytics Data',
        message: 'Analytics will be available once you have team members and active projects.',
        actionLabel: 'View Sample Data',
        onAction: () {
          setState(() {
            // Toggle to show sample data
          });
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CTAInfoCard(
                  title: 'Team Utilization',
                  value: '87%',
                  subtitle: 'vs 85% target',
                  icon: Icons.people,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CTAInfoCard(
                  title: 'Project Velocity',
                  value: '42',
                  subtitle: 'story points/sprint',
                  icon: Icons.speed,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CTAInfoCard(
                  title: 'On-Time Delivery',
                  value: '94%',
                  subtitle: 'projects delivered',
                  icon: Icons.schedule,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CTAInfoCard(
                  title: 'Quality Score',
                  value: '4.8/5',
                  subtitle: 'code review rating',
                  icon: Icons.star,
                  color: Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Capacity utilization chart
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Capacity Utilization Trend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _tabController.animateTo(1),
                      icon: const Icon(Icons.trending_up),
                      label: const Text('View Details'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 200,
                  child: _buildUtilizationChart(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Project status overview
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Project Status Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _tabController.animateTo(2),
                      icon: const Icon(Icons.assignment),
                      label: const Text('View Projects'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildProjectStatusItem(context, 'In Progress', 5, Colors.blue),
                    ),
                    Expanded(
                      child: _buildProjectStatusItem(context, 'On Track', 3, Colors.green),
                    ),
                    Expanded(
                      child: _buildProjectStatusItem(context, 'At Risk', 1, Colors.orange),
                    ),
                    Expanded(
                      child: _buildProjectStatusItem(context, 'Completed', 8, Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent insights
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildInsightItem(
                  context,
                  'Team utilization increased by 5% this month',
                  'Consider adding capacity for Q4 planning',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildInsightItem(
                  context,
                  'Mobile App Redesign is 15% ahead of schedule',
                  'Excellent progress by the frontend team',
                  Icons.schedule,
                  Colors.blue,
                ),
                _buildInsightItem(
                  context,
                  'Code review scores improved to 4.8/5',
                  'New review guidelines are showing results',
                  Icons.star,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the capacity analytics tab
  Widget _buildCapacityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capacity overview metrics
          Text(
            'Capacity Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildCapacityMetric(
                  context,
                  'Total Capacity',
                  '160h',
                  'this week',
                  Icons.access_time,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildCapacityMetric(
                  context,
                  'Allocated',
                  '139h',
                  '87% utilized',
                  Icons.assignment,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildCapacityMetric(
                  context,
                  'Available',
                  '21h',
                  '13% free',
                  Icons.hourglass_empty,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Utilization by team member
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Utilization by Team Member',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildMemberUtilization(context, 'Sarah Chen', 0.85, 32, 27),
                _buildMemberUtilization(context, 'Marcus Johnson', 0.95, 40, 38),
                _buildMemberUtilization(context, 'Ana Rodriguez', 0.60, 24, 14),
                _buildMemberUtilization(context, 'David Kim', 0.88, 40, 35),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Capacity allocation by project
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capacity Allocation by Project',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 250,
                  child: _buildAllocationChart(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Capacity trends
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capacity Trends (Last 8 Weeks)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 200,
                  child: _buildCapacityTrendChart(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the projects analytics tab
  Widget _buildProjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Project health overview
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Health Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 200,
                  child: _buildProjectHealthChart(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Active projects list
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Projects Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildProjectPerformanceItem(
                  context,
                  'Mobile App Redesign',
                  0.75,
                  'On Track',
                  Colors.green,
                  '8 weeks allocated',
                ),
                _buildProjectPerformanceItem(
                  context,
                  'API Migration',
                  0.45,
                  'On Track',
                  Colors.green,
                  '6 weeks allocated',
                ),
                _buildProjectPerformanceItem(
                  context,
                  'Performance Optimization',
                  0.20,
                  'Just Started',
                  Colors.blue,
                  '4 weeks allocated',
                ),
                _buildProjectPerformanceItem(
                  context,
                  'Security Audit',
                  0.90,
                  'At Risk',
                  Colors.orange,
                  '3 weeks allocated',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Velocity and burn down
          Row(
            children: [
              Expanded(
                child: CTACard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sprint Velocity',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        height: 150,
                        child: _buildVelocityChart(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CTACard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Burndown Trend',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        height: 150,
                        child: _buildBurndownChart(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the team analytics tab
  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Team performance metrics
          Row(
            children: [
              Expanded(
                child: CTAInfoCard(
                  title: 'Team Velocity',
                  value: '42',
                  subtitle: 'avg story points',
                  icon: Icons.speed,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CTAInfoCard(
                  title: 'Code Quality',
                  value: '4.8/5',
                  subtitle: 'review rating',
                  icon: Icons.star,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: CTAInfoCard(
                  title: 'Collaboration',
                  value: '94%',
                  subtitle: 'team satisfaction',
                  icon: Icons.people,
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CTAInfoCard(
                  title: 'Growth Rate',
                  value: '+12%',
                  subtitle: 'skill improvement',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Individual performance
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Individual Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildTeamMemberPerformance(context, 'Sarah Chen', 8.5, 4.9, 92),
                _buildTeamMemberPerformance(context, 'Marcus Johnson', 9.2, 4.7, 96),
                _buildTeamMemberPerformance(context, 'Ana Rodriguez', 7.8, 4.8, 88),
                _buildTeamMemberPerformance(context, 'David Kim', 8.8, 4.6, 94),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Skills development
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skills Development Tracking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 200,
                  child: _buildSkillsChart(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Team growth insights
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Growth Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildGrowthInsight(
                  context,
                  'Frontend skills have improved significantly',
                  'React and TypeScript competency up 15%',
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildGrowthInsight(
                  context,
                  'Code review quality is consistently high',
                  'Average rating maintained above 4.7/5',
                  Icons.star,
                  Colors.blue,
                ),
                _buildGrowthInsight(
                  context,
                  'Team collaboration scores are excellent',
                  '94% satisfaction with peer interactions',
                  Icons.people,
                  Colors.purple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build project status item widget
  Widget _buildProjectStatusItem(BuildContext context, String status, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          status,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build insight item widget
  Widget _buildInsightItem(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build capacity metric widget
  Widget _buildCapacityMetric(BuildContext context, String label, String value, String subtitle, IconData icon, Color color) {
    return CTACard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build member utilization widget
  Widget _buildMemberUtilization(BuildContext context, String name, double utilization, int capacity, int allocated) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${allocated}h / ${capacity}h (${(utilization * 100).toInt()}%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: utilization,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              utilization > 0.9 ? Colors.red : utilization > 0.8 ? Colors.orange : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  /// Build project performance item widget
  Widget _buildProjectPerformanceItem(BuildContext context, String name, double progress, String status, Color statusColor, String allocation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            allocation,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build team member performance widget
  Widget _buildTeamMemberPerformance(BuildContext context, String name, double velocity, double quality, int onTime) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  velocity.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  'Velocity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  quality.toString(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'Quality',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$onTime%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'On-Time',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build growth insight widget
  Widget _buildGrowthInsight(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Chart placeholder widgets - in a real app these would be proper chart implementations
  Widget _buildUtilizationChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Utilization trend chart\n(Line chart showing 87% current)',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Project allocation pie chart\n(Mobile App 40%, API 30%, etc.)',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityTrendChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Capacity trend over 8 weeks\n(Line chart showing growth)',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectHealthChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.donut_small, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Project health donut chart\n(Green: On Track, Orange: At Risk)',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVelocityChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Sprint velocity\nbar chart',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBurndownChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_down, size: 32, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              'Burndown\ntrend chart',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsChart(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.radar, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Skills radar chart\n(Frontend, Backend, DevOps, Design)',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
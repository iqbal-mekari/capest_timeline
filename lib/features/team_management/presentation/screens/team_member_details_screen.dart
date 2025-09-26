/// Detailed team member profile and management screen.
/// 
/// This screen provides comprehensive information about a specific team member
/// including their profile, capacity allocation, skills, and performance metrics.
library;

import 'package:flutter/material.dart';
import '../../../../shared/widgets/common_widgets.dart';

/// Team member details screen
class TeamMemberDetailsScreen extends StatefulWidget {
  final String memberName;
  
  const TeamMemberDetailsScreen({
    super.key,
    required this.memberName,
  });

  @override
  State<TeamMemberDetailsScreen> createState() => _TeamMemberDetailsScreenState();
}

class _TeamMemberDetailsScreenState extends State<TeamMemberDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
        title: Text('${widget.memberName} Profile'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.schedule), text: 'Capacity'),
            Tab(icon: Icon(Icons.star), text: 'Skills'),
            Tab(icon: Icon(Icons.analytics), text: 'Performance'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditMemberDialog(),
            tooltip: 'Edit Member',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildCapacityTab(),
          _buildSkillsTab(),
          _buildPerformanceTab(),
        ],
      ),
    );
  }

  /// Build the profile information tab
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          CTACard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    widget.memberName.split(' ').map((n) => n[0]).take(2).join(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.memberName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Senior Frontend Developer',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.memberName.toLowerCase().replaceAll(' ', '.')}@company.com',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contact information
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildInfoRow(context, Icons.phone, 'Phone', '+1 (555) 123-4567'),
                _buildInfoRow(context, Icons.location_on, 'Location', 'San Francisco, CA'),
                _buildInfoRow(context, Icons.access_time, 'Time Zone', 'PST (UTC-8)'),
                _buildInfoRow(context, Icons.calendar_today, 'Start Date', 'Jan 15, 2023'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Current assignments
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Assignments',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAssignmentsDialog(),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildAssignmentItem(context, 'Mobile App Redesign', '60%', Colors.blue),
                _buildAssignmentItem(context, 'Component Library', '25%', Colors.green),
                _buildAssignmentItem(context, 'Code Reviews', '15%', Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build capacity allocation tab
  Widget _buildCapacityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capacity overview
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Capacity Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildCapacityMetric(
                        context,
                        'Weekly Capacity',
                        '32 hours',
                        Icons.schedule,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildCapacityMetric(
                        context,
                        'Current Allocation',
                        '28 hours',
                        Icons.assignment,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildCapacityMetric(
                        context,
                        'Utilization',
                        '87.5%',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Weekly schedule
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Week\'s Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildScheduleDay(context, 'Monday', 8.0, 7.5),
                _buildScheduleDay(context, 'Tuesday', 8.0, 8.0),
                _buildScheduleDay(context, 'Wednesday', 8.0, 6.0),
                _buildScheduleDay(context, 'Thursday', 8.0, 8.0),
                _buildScheduleDay(context, 'Friday', 8.0, 4.0),
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
                  'Capacity Trends (Last 4 Weeks)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  height: 200,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Capacity trend chart coming soon',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build skills and competencies tab
  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skills overview
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Technical Skills',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showSkillsEditDialog(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildSkillCategory(context, 'Frontend Technologies', [
                  {'name': 'React', 'level': 4},
                  {'name': 'TypeScript', 'level': 4},
                  {'name': 'CSS/SCSS', 'level': 5},
                  {'name': 'Vue.js', 'level': 3},
                ]),
                
                _buildSkillCategory(context, 'Tools & Frameworks', [
                  {'name': 'Git', 'level': 5},
                  {'name': 'Webpack', 'level': 3},
                  {'name': 'Jest', 'level': 4},
                  {'name': 'Storybook', 'level': 4},
                ]),
                
                _buildSkillCategory(context, 'Design Systems', [
                  {'name': 'Component Libraries', 'level': 5},
                  {'name': 'Figma', 'level': 3},
                  {'name': 'Accessibility', 'level': 4},
                ]),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Certifications
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certifications & Training',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildCertificationItem(context, 'AWS Certified Developer', 'Amazon Web Services', '2024'),
                _buildCertificationItem(context, 'React Specialist', 'Facebook', '2023'),
                _buildCertificationItem(context, 'Accessibility Fundamentals', 'IAAP', '2023'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build performance metrics tab
  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance overview
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Performance Metrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildPerformanceMetric(
                        context,
                        'Velocity',
                        '8.5',
                        'story points/sprint',
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildPerformanceMetric(
                        context,
                        'Quality Score',
                        '94%',
                        'code review rating',
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildPerformanceMetric(
                        context,
                        'On-Time Delivery',
                        '91%',
                        'tasks completed on time',
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildPerformanceMetric(
                        context,
                        'Team Collaboration',
                        '4.7/5',
                        'peer feedback score',
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Recent achievements
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Achievements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildAchievementItem(context, 'Component Library Launch', 'Led the development and rollout of the new design system', Icons.library_books),
                _buildAchievementItem(context, 'Performance Optimization', 'Improved app load time by 40% through code splitting', Icons.speed),
                _buildAchievementItem(context, 'Mentorship Excellence', 'Successfully mentored 2 junior developers', Icons.school),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Goals and development
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Development Goals',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildGoalItem(context, 'Backend Development', 'Learn Node.js and GraphQL', 0.3),
                _buildGoalItem(context, 'Leadership Skills', 'Complete tech lead training program', 0.7),
                _buildGoalItem(context, 'Mobile Development', 'Gain React Native experience', 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build info row widget
  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Build assignment item widget
  Widget _buildAssignmentItem(BuildContext context, String name, String allocation, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              allocation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build capacity metric widget
  Widget _buildCapacityMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build schedule day widget
  Widget _buildScheduleDay(BuildContext context, String day, double capacity, double allocated) {
    final utilization = allocated / capacity;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: utilization,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                utilization > 0.9 ? Colors.red : utilization > 0.8 ? Colors.orange : Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${allocated.toStringAsFixed(1)}h / ${capacity.toStringAsFixed(1)}h',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build skill category widget
  Widget _buildSkillCategory(BuildContext context, String category, List<Map<String, dynamic>> skills) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ...skills.map((skill) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    skill['name'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) => Icon(
                    Icons.star,
                    size: 16,
                    color: index < skill['level'] 
                        ? Colors.amber 
                        : Colors.grey.withOpacity(0.3),
                  )),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// Build certification item widget
  Widget _buildCertificationItem(BuildContext context, String name, String issuer, String year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$issuer • $year',
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

  /// Build performance metric widget
  Widget _buildPerformanceMetric(BuildContext context, String label, String value, String subtitle, Color color) {
    return Column(
      children: [
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
    );
  }

  /// Build achievement item widget
  Widget _buildAchievementItem(BuildContext context, String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
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
                  description,
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

  /// Build goal item widget
  Widget _buildGoalItem(BuildContext context, String goal, String description, double progress) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Show edit member dialog
  void _showEditMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${widget.memberName}'),
        content: const Text('Edit member form coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show assignments dialog
  void _showAssignmentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Assignments'),
        content: const Text('Detailed assignments view coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show skills edit dialog
  void _showSkillsEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Skills'),
        content: const Text('Skills editor coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
/// Team management screen for managing team members and their capacity.
/// 
/// This screen provides the main interface for adding, editing, and managing
/// team members, their roles, availability, and capacity allocations.
library;

import 'package:flutter/material.dart';
import '../../../../shared/widgets/common_widgets.dart';
import 'team_member_details_screen.dart';

/// Main team management screen
class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final bool _hasData = true; // Simulated data state - set to true to show sample data

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
        title: const Text('Team Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Team Members'),
            Tab(icon: Icon(Icons.schedule), text: 'Availability'),
            Tab(icon: Icon(Icons.assignment_ind), text: 'Roles & Skills'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddMemberDialog(context),
            tooltip: 'Add Team Member',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamMembersTab(),
          _buildAvailabilityTab(),
          _buildRolesSkillsTab(),
        ],
      ),
    );
  }

  /// Build the team members management tab
  Widget _buildTeamMembersTab() {
    if (!_hasData) {
      return CTAEmptyState(
        icon: Icons.people_outline,
        title: 'No Team Members',
        message: 'Add team members to start tracking their capacity and managing assignments.',
        actionLabel: 'Add Team Member',
        onAction: () => _showAddMemberDialog(context),
      );
    }

    // Sample team member data
    final teamMembers = [
      {
        'name': 'Sarah Chen',
        'role': 'Senior Frontend Developer',
        'email': 'sarah.chen@company.com',
        'avatar': 'SC',
        'weeklyCapacity': 0.8,
        'currentUtilization': 0.75,
        'skills': ['React', 'TypeScript', 'Design Systems'],
        'isActive': true,
      },
      {
        'name': 'Marcus Johnson',
        'role': 'Backend Engineer',
        'email': 'marcus.j@company.com',
        'avatar': 'MJ',
        'weeklyCapacity': 1.0,
        'currentUtilization': 0.9,
        'skills': ['Python', 'GraphQL', 'PostgreSQL'],
        'isActive': true,
      },
      {
        'name': 'Ana Rodriguez',
        'role': 'Product Designer',
        'email': 'ana.rodriguez@company.com',
        'avatar': 'AR',
        'weeklyCapacity': 0.6,
        'currentUtilization': 0.5,
        'skills': ['Figma', 'User Research', 'Prototyping'],
        'isActive': false,
      },
      {
        'name': 'David Kim',
        'role': 'DevOps Engineer',
        'email': 'david.kim@company.com',
        'avatar': 'DK',
        'weeklyCapacity': 1.0,
        'currentUtilization': 0.85,
        'skills': ['AWS', 'Kubernetes', 'CI/CD'],
        'isActive': true,
      },
    ];

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teamMembers.length,
        itemBuilder: (context, index) {
          final member = teamMembers[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CTATeamMemberCard(
              name: member['name'] as String,
              email: member['email'] as String,
              roles: [member['role'] as String],
              weeklyCapacity: member['weeklyCapacity'] as double,
              isActive: member['isActive'] as bool,
              onTap: () => _navigateToMemberDetails(member['name'] as String),
              onEdit: () => _showEditMemberDialog(member['name'] as String),
            ),
          );
        },
      ),
    );
  }

  /// Build the availability management tab
  Widget _buildAvailabilityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week of Sept 24, 2025',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      // TODO: Navigate to previous week
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      // TODO: Navigate to next week
                    },
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Team availability overview
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Availability Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Availability metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildAvailabilityMetric(
                        context,
                        'Total Capacity',
                        '34.0 hours',
                        Icons.access_time,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildAvailabilityMetric(
                        context,
                        'Allocated',
                        '28.5 hours',
                        Icons.assignment,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildAvailabilityMetric(
                        context,
                        'Available',
                        '5.5 hours',
                        Icons.hourglass_empty,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Individual member availability
          Expanded(
            child: ListView.builder(
              itemCount: 4, // Sample count
              itemBuilder: (context, index) {
                final members = ['Sarah Chen', 'Marcus Johnson', 'Ana Rodriguez', 'David Kim'];
                final capacities = [32, 40, 24, 40]; // Hours per week
                final allocations = [24, 36, 12, 34]; // Allocated hours
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CTACard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              members[index],
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${allocations[index]}h / ${capacities[index]}h',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: allocations[index] / capacities[index],
                          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            allocations[index] / capacities[index] > 0.9
                                ? Colors.red
                                : allocations[index] / capacities[index] > 0.8
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: index == 2 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                index == 2 ? 'Out of Office' : 'Available',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: index == 2 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${((1 - allocations[index] / capacities[index]) * 100).toInt()}% free',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
          ),
        ],
      ),
    );
  }

  /// Build availability metric widget
  Widget _buildAvailabilityMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color,
        ),
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

  /// Build the roles and skills management tab
  Widget _buildRolesSkillsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Roles & Skills',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // Roles overview
          CTACard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Role Distribution',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                _buildRoleItem(context, 'Frontend Developers', 1, Colors.blue),
                _buildRoleItem(context, 'Backend Engineers', 1, Colors.green),
                _buildRoleItem(context, 'Product Designers', 1, Colors.purple),
                _buildRoleItem(context, 'DevOps Engineers', 1, Colors.orange),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skills matrix
          Expanded(
            child: CTACard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Skills Matrix',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showSkillsMatrixDialog(),
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildSkillCategory(context, 'Frontend Technologies', [
                            'React', 'TypeScript', 'Vue.js', 'CSS/SCSS', 'Design Systems'
                          ]),
                          _buildSkillCategory(context, 'Backend Technologies', [
                            'Python', 'Node.js', 'GraphQL', 'PostgreSQL', 'Redis'
                          ]),
                          _buildSkillCategory(context, 'Design & UX', [
                            'Figma', 'User Research', 'Prototyping', 'Design Thinking'
                          ]),
                          _buildSkillCategory(context, 'DevOps & Infrastructure', [
                            'AWS', 'Kubernetes', 'Docker', 'CI/CD', 'Monitoring'
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build role item widget
  Widget _buildRoleItem(BuildContext context, String role, int count, Color color) {
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
              role,
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
              count.toString(),
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

  /// Build skill category widget
  Widget _buildSkillCategory(BuildContext context, String category, List<String> skills) {
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                skill,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  /// Show add member dialog
  void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddMemberDialog(),
    );
  }

  /// Show edit member dialog
  void _showEditMemberDialog(String memberName) {
    showDialog(
      context: context,
      builder: (context) => EditMemberDialog(memberName: memberName),
    );
  }

  /// Show skills matrix dialog
  void _showSkillsMatrixDialog() {
    showDialog(
      context: context,
      builder: (context) => const SkillsMatrixDialog(),
    );
  }

  /// Navigate to member details
  void _navigateToMemberDetails(String memberName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberDetailsScreen(memberName: memberName),
      ),
    );
  }
}

// TODO: Implement these dialogs and screens
class AddMemberDialog extends StatelessWidget {
  const AddMemberDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team Member'),
      content: const Text('Add team member form coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class EditMemberDialog extends StatelessWidget {
  final String memberName;
  
  const EditMemberDialog({super.key, required this.memberName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit $memberName'),
      content: const Text('Edit team member form coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class SkillsMatrixDialog extends StatelessWidget {
  const SkillsMatrixDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Skills Matrix'),
      content: const Text('Skills matrix editor coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class MemberDetailsScreen extends StatelessWidget {
  final String memberName;
  
  const MemberDetailsScreen({super.key, required this.memberName});

  @override
  Widget build(BuildContext context) {
    return TeamMemberDetailsScreen(memberName: memberName);
  }
}
import 'package:flutter/material.dart';

/// Simplified main screen for manual testing
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock data for testing
  List<Map<String, dynamic>> _teamMembers = [
    // Original team members
    {'id': '1', 'name': 'Alice Johnson', 'email': 'alice@example.com', 'roles': ['Backend'], 'capacity': 1.0},
    {'id': '2', 'name': 'Bob Smith', 'email': 'bob@example.com', 'roles': ['Backend', 'Frontend'], 'capacity': 0.8},
    {'id': '3', 'name': 'Carol Chen', 'email': 'carol@example.com', 'roles': ['Mobile', 'Frontend'], 'capacity': 1.0},
    // Performance testing team members (20+ total)
    {'id': '4', 'name': 'David Wilson', 'email': 'david@example.com', 'roles': ['QA'], 'capacity': 1.0},
    {'id': '5', 'name': 'Eva Martinez', 'email': 'eva@example.com', 'roles': ['Frontend'], 'capacity': 0.9},
    {'id': '6', 'name': 'Frank Anderson', 'email': 'frank@example.com', 'roles': ['Backend'], 'capacity': 1.0},
    {'id': '7', 'name': 'Grace Lee', 'email': 'grace@example.com', 'roles': ['Mobile'], 'capacity': 0.7},
    {'id': '8', 'name': 'Henry Zhang', 'email': 'henry@example.com', 'roles': ['Backend', 'QA'], 'capacity': 1.0},
    {'id': '9', 'name': 'Iris Thompson', 'email': 'iris@example.com', 'roles': ['Frontend'], 'capacity': 0.8},
    {'id': '10', 'name': 'Jack Robinson', 'email': 'jack@example.com', 'roles': ['Mobile'], 'capacity': 1.0},
    {'id': '11', 'name': 'Kelly Davis', 'email': 'kelly@example.com', 'roles': ['QA'], 'capacity': 0.9},
    {'id': '12', 'name': 'Luis Garcia', 'email': 'luis@example.com', 'roles': ['Backend'], 'capacity': 1.0},
    {'id': '13', 'name': 'Maya Patel', 'email': 'maya@example.com', 'roles': ['Frontend', 'Mobile'], 'capacity': 0.8},
    {'id': '14', 'name': 'Nathan Brown', 'email': 'nathan@example.com', 'roles': ['Backend'], 'capacity': 1.0},
    {'id': '15', 'name': 'Olivia White', 'email': 'olivia@example.com', 'roles': ['QA'], 'capacity': 0.9},
    {'id': '16', 'name': 'Peter Kim', 'email': 'peter@example.com', 'roles': ['Frontend'], 'capacity': 1.0},
    {'id': '17', 'name': 'Quinn Miller', 'email': 'quinn@example.com', 'roles': ['Mobile'], 'capacity': 0.7},
    {'id': '18', 'name': 'Rachel Taylor', 'email': 'rachel@example.com', 'roles': ['Backend', 'QA'], 'capacity': 1.0},
    {'id': '19', 'name': 'Sam Johnson', 'email': 'sam@example.com', 'roles': ['Frontend'], 'capacity': 0.8},
    {'id': '20', 'name': 'Tina Moore', 'email': 'tina@example.com', 'roles': ['Mobile'], 'capacity': 1.0},
    {'id': '21', 'name': 'Uma Wilson', 'email': 'uma@example.com', 'roles': ['QA'], 'capacity': 0.9},
    {'id': '22', 'name': 'Victor Lee', 'email': 'victor@example.com', 'roles': ['Backend'], 'capacity': 1.0},
  ];
  
  List<Map<String, dynamic>> _initiatives = [
    // Original initiatives
    {'id': '1', 'title': 'E-commerce Platform v2', 'description': 'Complete redesign with mobile app', 'requirements': {'Backend': 8, 'Frontend': 6, 'Mobile': 4, 'QA': 3}},
    {'id': '2', 'title': 'User Authentication System', 'description': 'Implement OAuth and SSO', 'requirements': {'Backend': 4, 'Frontend': 2}},
    // Performance testing initiatives (10+ total)
    {'id': '3', 'title': 'Payment Processing Integration', 'description': 'Integrate multiple payment gateways', 'requirements': {'Backend': 6, 'Frontend': 3, 'QA': 2}},
    {'id': '4', 'title': 'Mobile App Redesign', 'description': 'Complete UI/UX overhaul for mobile', 'requirements': {'Mobile': 12, 'Frontend': 4, 'QA': 3}},
    {'id': '5', 'title': 'Analytics Dashboard', 'description': 'Real-time analytics and reporting', 'requirements': {'Backend': 5, 'Frontend': 8, 'QA': 2}},
    {'id': '6', 'title': 'API Performance Optimization', 'description': 'Optimize database queries and caching', 'requirements': {'Backend': 10, 'QA': 4}},
    {'id': '7', 'title': 'Search Engine Integration', 'description': 'Implement Elasticsearch for better search', 'requirements': {'Backend': 7, 'Frontend': 3, 'QA': 2}},
    {'id': '8', 'title': 'Notification System', 'description': 'Push notifications and email alerts', 'requirements': {'Backend': 4, 'Mobile': 3, 'Frontend': 2, 'QA': 1}},
    {'id': '9', 'title': 'Data Migration Tool', 'description': 'Migrate legacy data to new system', 'requirements': {'Backend': 8, 'QA': 6}},
    {'id': '10', 'title': 'Security Audit Implementation', 'description': 'Implement security recommendations', 'requirements': {'Backend': 5, 'Frontend': 2, 'Mobile': 2, 'QA': 4}},
    {'id': '11', 'title': 'Chat System Integration', 'description': 'Real-time messaging for users', 'requirements': {'Backend': 6, 'Frontend': 4, 'Mobile': 3, 'QA': 2}},
    {'id': '12', 'title': 'Automated Testing Suite', 'description': 'Comprehensive test automation', 'requirements': {'QA': 12, 'Backend': 2, 'Frontend': 2}},
  ];
  
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
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Capacity Planning Timeline'),
      actions: [
        IconButton(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh Data',
        ),
        IconButton(
          onPressed: _openSettings,
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
        IconButton(
          onPressed: _showHelp,
          icon: const Icon(Icons.help_outline),
          tooltip: 'Help',
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.group), text: 'Team'),
          Tab(icon: Icon(Icons.assignment), text: 'Initiatives'),
          Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
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
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search team members...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // Team members list
        Expanded(
          child: _teamMembers.isEmpty 
            ? _buildEmptyState(
                'No team members found',
                'Add team members to start capacity planning',
                Icons.group_outlined,
                'Add Team Member',
                _addTeamMember,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _teamMembers.length,
                itemBuilder: (context, index) {
                  final member = _teamMembers[index];
                  return _buildTeamMemberCard(member);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            member['name'][0],
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(member['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member['email']),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: (member['roles'] as List<String>).map((role) => 
                Chip(
                  label: Text(role, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
              ).toList(),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${(member['capacity'] * 100).toInt()}%'),
            const Text('Capacity', style: TextStyle(fontSize: 12)),
          ],
        ),
        onTap: () => _selectTeamMember(member),
      ),
    );
  }

  Widget _buildInitiativesView() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search initiatives...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        
        // Initiatives list
        Expanded(
          child: _initiatives.isEmpty 
            ? _buildEmptyState(
                'No initiatives found',
                'Create your first initiative to start capacity planning',
                Icons.assignment_outlined,
                'Create Initiative',
                _createInitiative,
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _initiatives.length,
                itemBuilder: (context, index) {
                  final initiative = _initiatives[index];
                  return _buildInitiativeCard(initiative);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildInitiativeCard(Map<String, dynamic> initiative) {
    final requirements = initiative['requirements'] as Map<String, int>;
    final totalWeeks = requirements.values.fold(0, (sum, weeks) => sum + weeks);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              initiative['title'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              initiative['description'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Role Requirements:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: requirements.entries.map((entry) => 
                Chip(
                  label: Text('${entry.key}: ${entry.value}w'),
                  backgroundColor: _getRoleColor(entry.key).withOpacity(0.2),
                ),
              ).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${totalWeeks} weeks'),
                ElevatedButton(
                  onPressed: () => _assignTeamToInitiative(initiative['id']),
                  child: const Text('Assign Team'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsView() {
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
                  '${_initiatives.length}',
                  Icons.assignment,
                  Theme.of(context).colorScheme.primary,
                ),
                _buildMetricCard(
                  'Team Members',
                  '${_teamMembers.length}',
                  Icons.group,
                  Theme.of(context).colorScheme.secondary,
                ),
                _buildMetricCard(
                  'Active Allocations',
                  '0',
                  Icons.timeline,
                  Colors.orange,
                ),
                _buildMetricCard(
                  'Avg Utilization',
                  '0.0%',
                  Icons.analytics,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
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

  Widget _buildEmptyState(String title, String message, IconData icon, String actionLabel, VoidCallback onAction) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
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

  // Helper methods
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'backend':
        return const Color(0xFF3F51B5); // Indigo
      case 'frontend':
        return const Color(0xFF009688); // Teal
      case 'mobile':
        return const Color(0xFF9C27B0); // Purple
      case 'qa':
        return const Color(0xFFFF9800); // Orange
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  // Action methods
  void _refreshData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data refreshed successfully')),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings functionality will be implemented here.'),
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
            Text('This is a manual testing version with mock data.'),
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

  void _addTeamMember() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Team Member'),
        content: const Text('Manual Test: Add team member functionality'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add a new mock team member
              setState(() {
                _teamMembers.add({
                  'id': '${_teamMembers.length + 1}',
                  'name': 'New Member ${_teamMembers.length + 1}',
                  'email': 'new${_teamMembers.length + 1}@example.com',
                  'roles': ['Backend'],
                  'capacity': 1.0,
                });
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Team member added successfully!')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _createInitiative() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Initiative'),
        content: const Text('Manual Test: Create initiative functionality'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Add a new mock initiative
              setState(() {
                _initiatives.add({
                  'id': '${_initiatives.length + 1}',
                  'title': 'New Initiative ${_initiatives.length + 1}',
                  'description': 'Test initiative for manual testing',
                  'requirements': {'Backend': 4, 'Frontend': 2},
                });
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Initiative created successfully!')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _selectTeamMember(Map<String, dynamic> member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected team member: ${member['name']}')),
    );
  }

  void _assignTeamToInitiative(String initiativeId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manual Test: Assign team to initiative $initiativeId')),
    );
  }
}
/// Integration test helpers and utilities.
/// 
/// Provides common functionality for integration tests including:
/// - Widget testing utilities
/// - Mock data generators
/// - Test assertion helpers
/// - Performance measurement tools
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

import '../mocks/mock_quarter_plan_repository.dart';
import '../mocks/mock_application_state_repository.dart';
import '../mocks/mock_capacity_planning_service.dart';

/// Helper class for integration test utilities
class IntegrationTestHelpers {
  static final Random _random = Random();

  /// Generates a mock quarter plan with realistic test data
  static MockQuarterPlan generateMockQuarterPlan({
    String? id,
    int? quarter,
    int? year,
    int teamMemberCount = 5,
    int initiativeCount = 3,
  }) {
    final planId = id ?? 'plan_${_random.nextInt(10000)}';
    final planQuarter = quarter ?? (_random.nextInt(4) + 1);
    final planYear = year ?? (2024 + _random.nextInt(2));

    final teamMembers = List.generate(teamMemberCount, (index) {
      return MockTeamMember(
        id: 'member_${planId}_$index',
        name: _generateMemberName(index),
        role: _generateRole(),
        capacity: _generateCapacity(),
      );
    });

    final initiatives = List.generate(initiativeCount, (index) {
      return MockInitiative(
        id: 'initiative_${planId}_$index',
        title: _generateInitiativeTitle(index),
        description: _generateInitiativeDescription(index),
        priority: _random.nextInt(10) + 1,
      );
    });

    return MockQuarterPlan(
      id: planId,
      quarter: planQuarter,
      year: planYear,
      teamMembers: teamMembers,
      initiatives: initiatives,
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      updatedAt: _random.nextBool() ? DateTime.now() : null,
    );
  }

  /// Generates a mock application state with realistic test data
  static MockApplicationState generateMockApplicationState({
    String? currentPlanId,
    int recentPlanCount = 3,
    bool hasUnsavedChanges = false,
  }) {
    final recentPlans = List.generate(recentPlanCount, (index) {
      return 'plan_${_random.nextInt(1000)}';
    });

    return MockApplicationState(
      currentPlanId: currentPlanId ?? (recentPlans.isNotEmpty ? recentPlans.first : null),
      lastAccessedPlanIds: recentPlans,
      viewMode: _generateViewMode(),
      selectedQuarter: _random.nextBool() ? (_random.nextInt(4) + 1) : null,
      selectedYear: _random.nextBool() ? (2024 + _random.nextInt(2)) : null,
      isAutoSaveEnabled: _random.nextBool(),
      hasUnsavedChanges: hasUnsavedChanges,
      lastSaveTime: _random.nextBool() ? DateTime.now().subtract(Duration(minutes: _random.nextInt(60))) : null,
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(90))),
      updatedAt: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
    );
  }

  /// Generates a mock draft with realistic test data
  static MockDraftData generateMockDraft({
    String? id,
    String? name,
  }) {
    final draftId = id ?? 'draft_${_random.nextInt(1000)}';
    final draftName = name ?? 'Draft ${_generateQuarterName()} Plan';

    return MockDraftData(
      id: draftId,
      name: draftName,
      data: {
        'quarter': _random.nextInt(4) + 1,
        'year': 2024 + _random.nextInt(2),
        'memberCount': _random.nextInt(10) + 1,
        'initiativeCount': _random.nextInt(5) + 1,
        'completionPercentage': _random.nextInt(100),
      },
      lastModified: DateTime.now().subtract(Duration(hours: _random.nextInt(48))),
    );
  }

  /// Waits for all animations and async operations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  /// Waits for a specific condition to be met within a timeout
  static Future<void> waitForCondition(
    WidgetTester tester,
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration pollInterval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (!condition() && stopwatch.elapsed < timeout) {
      await tester.pump(pollInterval);
    }
    
    if (!condition()) {
      throw TimeoutException('Condition not met within timeout', timeout);
    }
  }

  /// Simulates slow network conditions
  static Future<void> simulateNetworkDelay({
    int minMs = 500,
    int maxMs = 2000,
  }) async {
    final delay = minMs + _random.nextInt(maxMs - minMs);
    await Future.delayed(Duration(milliseconds: delay));
  }

  /// Measures widget performance
  static Future<Duration> measurePerformance(
    WidgetTester tester,
    Future<void> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    return stopwatch.elapsed;
  }

  /// Verifies widget is present and visible
  static void verifyWidgetVisible(
    WidgetTester tester,
    Key key, {
    String? description,
  }) {
    final widget = find.byKey(key);
    expect(widget, findsOneWidget, reason: description ?? 'Widget with key $key should be visible');
    
    // Verify widget is actually visible on screen
    final renderObject = tester.renderObject(widget);
    expect(renderObject.paintBounds.isEmpty, isFalse, 
        reason: 'Widget should have non-empty paint bounds');
  }

  /// Verifies text is present and visible
  static void verifyTextVisible(
    WidgetTester tester,
    String text, {
    String? description,
  }) {
    final textWidget = find.text(text);
    expect(textWidget, findsOneWidget, reason: description ?? 'Text "$text" should be visible');
  }

  /// Simulates user interaction with delays
  static Future<void> simulateUserInteraction(
    WidgetTester tester,
    Future<void> Function() interaction, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    await interaction();
    await Future.delayed(delay);
    await tester.pump();
  }

  /// Creates a test widget wrapper with common providers
  static Widget createTestWrapper({
    required Widget child,
    MockQuarterPlanRepository? quarterPlanRepository,
    MockApplicationStateRepository? applicationStateRepository,
    MockCapacityPlanningService? capacityPlanningService,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Generates realistic error scenarios for testing
  static List<String> generateErrorScenarios() {
    return [
      'Network connection failed',
      'Storage quota exceeded',
      'Invalid data format',
      'Validation failed: Over-allocation detected',
      'Session expired',
      'Server unavailable',
      'Concurrent modification detected',
      'Insufficient permissions',
    ];
  }

  /// Generates realistic warning scenarios for testing
  static List<String> generateWarningScenarios() {
    return [
      'High capacity utilization detected',
      'Initiative has no allocated resources',
      'Duplicate team member names found',
      'Quarter plan exceeds recommended scope',
      'Auto-save is disabled',
      'Draft has been modified by another user',
      'Performance may be impacted with this many items',
    ];
  }

  // Private helper methods for data generation

  static String _generateMemberName(int index) {
    final names = [
      'Alice Johnson', 'Bob Smith', 'Carol Davis', 'David Wilson',
      'Eva Brown', 'Frank Miller', 'Grace Lee', 'Henry Taylor',
      'Ivy Chen', 'Jack Anderson', 'Kate Martinez', 'Liam Thompson'
    ];
    return names[index % names.length];
  }

  static String _generateRole() {
    final roles = [
      'Backend Developer', 'Frontend Developer', 'Full-Stack Developer',
      'DevOps Engineer', 'QA Engineer', 'Product Manager',
      'UI/UX Designer', 'Data Scientist', 'System Administrator'
    ];
    return roles[_random.nextInt(roles.length)];
  }

  static double _generateCapacity() {
    // Generate realistic capacity values with some over-allocation scenarios
    final capacities = [40.0, 60.0, 80.0, 100.0, 110.0, 120.0];
    return capacities[_random.nextInt(capacities.length)];
  }

  static String _generateInitiativeTitle(int index) {
    final titles = [
      'Mobile App Development', 'API Modernization', 'Database Migration',
      'Security Enhancement', 'Performance Optimization', 'User Portal Redesign',
      'Analytics Dashboard', 'Payment Integration', 'Notification System',
      'Search Functionality', 'Admin Tools', 'Reporting System'
    ];
    return titles[index % titles.length];
  }

  static String _generateInitiativeDescription(int index) {
    final descriptions = [
      'Develop comprehensive mobile application for improved user experience',
      'Modernize legacy APIs to improve performance and maintainability',
      'Migrate database to new platform with zero downtime',
      'Implement security enhancements across all user-facing systems',
      'Optimize application performance to meet SLA requirements',
      'Redesign user portal with modern UI/UX principles'
    ];
    return descriptions[index % descriptions.length];
  }

  static String _generateViewMode() {
    final modes = ['timeline', 'capacity', 'table', 'kanban'];
    return modes[_random.nextInt(modes.length)];
  }

  static String _generateQuarterName() {
    final quarters = ['Q1', 'Q2', 'Q3', 'Q4'];
    return quarters[_random.nextInt(quarters.length)];
  }
}

/// Custom exception for test timeouts
class TimeoutException implements Exception {
  const TimeoutException(this.message, this.timeout);
  
  final String message;
  final Duration timeout;
  
  @override
  String toString() => 'TimeoutException: $message (timeout: $timeout)';
}

/// Test data generator for consistent test scenarios
class TestDataGenerator {
  static const List<String> sampleMemberNames = [
    'Alice Johnson', 'Bob Smith', 'Carol Davis', 'David Wilson',
    'Eva Brown', 'Frank Miller', 'Grace Lee', 'Henry Taylor'
  ];

  static const List<String> sampleInitiativeTitles = [
    'Mobile App Development', 'API Modernization', 'Database Migration',
    'Security Enhancement', 'Performance Optimization', 'User Portal Redesign'
  ];

  static const List<String> sampleRoles = [
    'Backend Developer', 'Frontend Developer', 'Full-Stack Developer',
    'DevOps Engineer', 'QA Engineer', 'Product Manager', 'UI/UX Designer'
  ];

  /// Generates a specific test scenario for consistent testing
  static MockQuarterPlan generateScenario(String scenarioName) {
    switch (scenarioName) {
      case 'simple_plan':
        return MockQuarterPlan(
          id: 'simple_plan_001',
          quarter: 2,
          year: 2024,
          teamMembers: [
            const MockTeamMember(id: 'member_001', name: 'Alice Johnson', role: 'Backend Developer', capacity: 80.0),
            const MockTeamMember(id: 'member_002', name: 'Bob Smith', role: 'Frontend Developer', capacity: 60.0),
          ],
          initiatives: [
            const MockInitiative(id: 'init_001', title: 'Mobile App Development', description: 'Develop mobile app', priority: 8),
          ],
          createdAt: DateTime(2024, 3, 1),
          updatedAt: DateTime(2024, 3, 15),
        );

      case 'over_allocated_plan':
        return MockQuarterPlan(
          id: 'over_allocated_001',
          quarter: 3,
          year: 2024,
          teamMembers: [
            const MockTeamMember(id: 'member_003', name: 'Carol Davis', role: 'Full-Stack Developer', capacity: 120.0),
            const MockTeamMember(id: 'member_004', name: 'David Wilson', role: 'DevOps Engineer', capacity: 110.0),
          ],
          initiatives: [
            const MockInitiative(id: 'init_002', title: 'API Modernization', description: 'Modernize APIs', priority: 9),
            const MockInitiative(id: 'init_003', title: 'Database Migration', description: 'Migrate database', priority: 7),
          ],
          createdAt: DateTime(2024, 6, 1),
        );

      case 'empty_plan':
        return MockQuarterPlan(
          id: 'empty_plan_001',
          quarter: 1,
          year: 2025,
          teamMembers: [],
          initiatives: [],
          createdAt: DateTime(2024, 12, 1),
        );

      default:
        throw ArgumentError('Unknown scenario: $scenarioName');
    }
  }
}
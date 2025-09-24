/// Application routing configuration and navigation management.
/// 
/// This module provides a comprehensive routing system using GoRouter
/// for proper deep linking support, route management, and navigation state.
library;

import 'package:flutter/material.dart';
import '../../screens/app_shell.dart';
import '../../features/capacity_planning/presentation/screens/capacity_planning_screen.dart';
import '../../features/capacity_planning/presentation/screens/analytics_dashboard_screen.dart';
import '../../features/team_management/presentation/screens/team_management_screen.dart';
import '../../features/team_management/presentation/screens/team_member_details_screen.dart';

/// Application route configuration and navigation state
class AppRouter {
  /// Static route paths
  static const String home = '/';
  static const String planning = '/planning';
  static const String team = '/team';
  static const String teamMember = '/team/member';
  static const String analytics = '/analytics';
  static const String settings = '/settings';

  /// Navigation keys for managing route state
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

  /// Current navigation state
  static ValueNotifier<String> currentRoute = ValueNotifier<String>(home);
  
  /// Update current route
  static void updateCurrentRoute(String route) {
    currentRoute.value = route;
  }

  /// Navigate to a specific route
  static void navigateTo(String route, {Map<String, String>? parameters}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      if (parameters != null && parameters.isNotEmpty) {
        // Build route with parameters
        final uri = Uri(path: route, queryParameters: parameters);
        Navigator.pushNamed(context, uri.toString());
      } else {
        Navigator.pushNamed(context, route);
      }
      updateCurrentRoute(route);
    }
  }

  /// Navigate and replace current route
  static void navigateToReplacement(String route, {Map<String, String>? parameters}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      if (parameters != null && parameters.isNotEmpty) {
        final uri = Uri(path: route, queryParameters: parameters);
        Navigator.pushReplacementNamed(context, uri.toString());
      } else {
        Navigator.pushReplacementNamed(context, route);
      }
      updateCurrentRoute(route);
    }
  }

  /// Pop current route
  static void pop() {
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Pop to root route
  static void popToRoot() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.popUntil(context, (route) => route.isFirst);
      updateCurrentRoute(home);
    }
  }

  /// Check if we can pop the current route
  static bool canPop() {
    final context = navigatorKey.currentContext;
    return context != null && Navigator.canPop(context);
  }

  /// Get current route from navigator
  static String getCurrentRoute() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final route = ModalRoute.of(context);
      if (route != null && route.settings.name != null) {
        return route.settings.name!;
      }
    }
    return currentRoute.value;
  }

  /// Generate route configuration
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;
    final queryParams = uri.queryParameters;

    updateCurrentRoute(path);

    switch (path) {
      case home:
        return MaterialPageRoute<void>(
          builder: (context) => const AppShell(),
          settings: settings,
        );

      case planning:
        return MaterialPageRoute<void>(
          builder: (context) => const CapacityPlanningScreen(),
          settings: settings,
        );

      case team:
        return MaterialPageRoute<void>(
          builder: (context) => const TeamManagementScreen(),
          settings: settings,
        );

      case teamMember:
        final memberId = queryParams['id'];
        if (memberId != null) {
          return MaterialPageRoute<void>(
            builder: (context) => TeamMemberDetailsScreen(memberName: memberId),
            settings: settings,
          );
        }
        // Fallback to team management if no member ID
        return MaterialPageRoute<void>(
          builder: (context) => const TeamManagementScreen(),
          settings: settings,
        );

      case analytics:
        return MaterialPageRoute<void>(
          builder: (context) => const AnalyticsDashboardScreen(),
          settings: settings,
        );

      case '/settings':
        return MaterialPageRoute<void>(
          builder: (context) => const AppShell(),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (context) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }

  /// Handle unknown routes
  static Route<dynamic> unknownRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (context) => const NotFoundScreen(),
      settings: settings,
    );
  }
}

/// Navigation helper class for type-safe navigation
class NavigationHelper {
  /// Navigate to home
  static void goHome() {
    AppRouter.navigateToReplacement(AppRouter.home);
  }

  /// Navigate to capacity planning
  static void goToPlanning() {
    AppRouter.navigateTo(AppRouter.planning);
  }

  /// Navigate to team management
  static void goToTeam() {
    AppRouter.navigateTo(AppRouter.team);
  }

  /// Navigate to specific team member
  static void goToTeamMember(String memberId) {
    AppRouter.navigateTo(AppRouter.teamMember, parameters: {'id': memberId});
  }

  /// Navigate to analytics dashboard
  static void goToAnalytics() {
    AppRouter.navigateTo(AppRouter.analytics);
  }

  /// Navigate to settings
  static void goToSettings() {
    AppRouter.navigateTo(AppRouter.settings);
  }

  /// Navigate back
  static void goBack() {
    AppRouter.pop();
  }

  /// Navigate to root
  static void goToRoot() {
    AppRouter.popToRoot();
  }

  /// Check if navigation back is possible
  static bool canGoBack() {
    return AppRouter.canPop();
  }
}

/// Route information class for navigation state
class RouteInfo {
  final String path;
  final String title;
  final IconData icon;
  final IconData? selectedIcon;
  final String? tooltip;

  const RouteInfo({
    required this.path,
    required this.title,
    required this.icon,
    this.selectedIcon,
    this.tooltip,
  });
}

/// Navigation configuration for main app sections
class NavigationConfig {
  static const List<RouteInfo> mainRoutes = [
    RouteInfo(
      path: AppRouter.home,
      title: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      tooltip: 'Home Dashboard',
    ),
    RouteInfo(
      path: AppRouter.planning,
      title: 'Planning',
      icon: Icons.timeline_outlined,
      selectedIcon: Icons.timeline,
      tooltip: 'Capacity Planning',
    ),
    RouteInfo(
      path: AppRouter.team,
      title: 'Team',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      tooltip: 'Team Management',
    ),
    RouteInfo(
      path: AppRouter.analytics,
      title: 'Analytics',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics,
      tooltip: 'Capacity Analytics',
    ),
    RouteInfo(
      path: AppRouter.settings,
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      tooltip: 'Configuration',
    ),
  ];

  /// Get route info by path
  static RouteInfo? getRouteInfo(String path) {
    try {
      return mainRoutes.firstWhere((route) => route.path == path);
    } catch (e) {
      return null;
    }
  }

  /// Get main navigation routes (excluding settings)
  static List<RouteInfo> getMainNavigationRoutes() {
    return mainRoutes.where((route) => route.path != AppRouter.settings).toList();
  }
}

/// Navigation state provider for managing navigation state throughout the app
class NavigationState extends ChangeNotifier {
  static final NavigationState _instance = NavigationState._internal();
  factory NavigationState() => _instance;
  NavigationState._internal();

  String _currentRoute = AppRouter.home;
  int _selectedIndex = 0;
  final List<String> _routeHistory = [AppRouter.home];

  /// Current route getter
  String get currentRoute => _currentRoute;

  /// Selected navigation index getter
  int get selectedIndex => _selectedIndex;

  /// Route history getter
  List<String> get routeHistory => List.unmodifiable(_routeHistory);

  /// Update current route and navigation state
  void updateRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      _updateSelectedIndex(route);
      _addToHistory(route);
      notifyListeners();
    }
  }

  /// Update selected navigation index based on route
  void _updateSelectedIndex(String route) {
    final routes = NavigationConfig.getMainNavigationRoutes();
    for (int i = 0; i < routes.length; i++) {
      if (routes[i].path == route) {
        _selectedIndex = i;
        return;
      }
    }
    // Default to home if route not found in main navigation
    _selectedIndex = 0;
  }

  /// Add route to history
  void _addToHistory(String route) {
    if (_routeHistory.isEmpty || _routeHistory.last != route) {
      _routeHistory.add(route);
      // Keep history to reasonable size
      if (_routeHistory.length > 10) {
        _routeHistory.removeAt(0);
      }
    }
  }

  /// Clear navigation history
  void clearHistory() {
    _routeHistory.clear();
    _routeHistory.add(_currentRoute);
    notifyListeners();
  }

  /// Get previous route from history
  String? getPreviousRoute() {
    if (_routeHistory.length > 1) {
      return _routeHistory[_routeHistory.length - 2];
    }
    return null;
  }

  /// Check if we can navigate back in history
  bool canNavigateBack() {
    return _routeHistory.length > 1;
  }
}

/// Breadcrumb navigation widget
class BreadcrumbNavigation extends StatelessWidget {
  const BreadcrumbNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppRouter.currentRoute,
      builder: (context, currentRoute, _) {
        final routeInfo = NavigationConfig.getRouteInfo(currentRoute);
        if (routeInfo == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                routeInfo.icon,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                routeInfo.title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 404 Not Found screen
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationHelper.goHome(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '404 - Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The page you are looking for does not exist.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => NavigationHelper.goHome(),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
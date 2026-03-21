import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'navigation_wrapper.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/journal_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/recently_deleted_screen.dart';

/// Configuration class for application routing using GoRouter.
/// This centralizes all navigation logic, making the app easier to maintain and test.
class AppRouter {
  // Global key for the root navigator to allow navigation without context if needed.
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  // Global key for the shell navigator used in the bottom navigation structure.
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    routes: [
      // Structured using ShellRoute to persist the NavigationWrapper (bottom bar)
      // across different sub-pages like Dashboard, Journal, etc.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'deleted',
                builder: (context, state) => const RecentlyDeletedScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

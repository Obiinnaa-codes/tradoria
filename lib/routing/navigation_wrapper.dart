import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';

/// Wraps the main screen content with a GoRouter-integrated Bottom Navigation Bar.
/// Uses ShellRoute's child to display the current sub-page dynamically.
class NavigationWrapper extends StatelessWidget {
  final Widget child;
  const NavigationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The child provided by ShellRoute is rendered here
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceHighlight, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          // Logic based on state.matchedLocation to indicate the active index
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context),
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_rounded),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  /// Selects the correct route based on index interaction from the Nav Bar.
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/journal');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }

  /// Calculates which index in the bar should be active based on URI path segments.
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/journal')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0; // Default index is Dashboard
  }
}

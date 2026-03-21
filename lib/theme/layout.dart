import 'package:flutter/material.dart';

/// Centralized layout constants and responsiveness helpers.
class AppLayout {
  // Breakpoints
  static const double mobileMax = 600;
  static const double tabletMax = 1024;

  /// Returns true if the screen width is greater than mobileMax.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width > mobileMax;

  /// Returns true if the screen width is greater than tabletMax.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > tabletMax;

  /// Returns the appropriate number of columns based on screen width.
  static int getResponsiveColumnCount(BuildContext context, {int base = 2}) {
    double width = MediaQuery.of(context).size.width;
    if (width > tabletMax) return base + 2;
    if (width > mobileMax) return base + 1;
    return base;
  }

  /// Responsive padding for screens
  static EdgeInsets screenPadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > tabletMax)
      return const EdgeInsets.symmetric(horizontal: 100, vertical: 40);
    if (width > mobileMax) return const EdgeInsets.all(32);
    return const EdgeInsets.all(20);
  }

  /// Wraps a widget to constrain its maximum width on larger screens.
  static Widget constrained(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 1200) {
          final double horizontalPadding = (constraints.maxWidth - 1200) / 2;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: child,
          );
        }
        return child;
      },
    );
  }
}

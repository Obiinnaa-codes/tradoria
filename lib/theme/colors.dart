import 'package:flutter/material.dart';

/// Defines the color palette for the entire application,
/// utilizing a dark fintech theme with specific semantic colors.
class AppColors {
  // Base background colors
  static const Color background = Color(0xFF090C10); // Deep Navy/Black
  static const Color surface = Color(
    0xFF161B22,
  ); // Charcoal for cards/containers
  static const Color surfaceHighlight = Color(
    0xFF21262D,
  ); // Lighter border/highlight color

  // Semantic trading colors
  static const Color profit = Color(
    0xFF2EA043,
  ); // Green for winning trades/positive numbers
  static const Color loss = Color(
    0xFFF85149,
  ); // Red for losing trades/negative numbers
  static const Color inactive = Color(
    0xFF30363D,
  ); // Neutral Grey for weekends/inactive periods

  // Text colors
  static const Color textPrimary = Color(0xFFC9D1D9); // High contrast text
  static const Color textSecondary = Color(
    0xFF8B949E,
  ); // Low contrast text/labels

  // Brand/Accent color
  static const Color accent = Color(
    0xFF58A6FF,
  ); // Blue accent for buttons and selection
}

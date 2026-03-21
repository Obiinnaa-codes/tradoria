import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme/colors.dart';
import 'providers/trade_provider.dart';
import 'routing/app_router.dart';

void main() {
  // Ensured Flutter engine components are initialized before storage access in provider.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => TradeProvider())],
      child: const TradoriaApp(),
    ),
  );
}

/// The root widget of the application configured for GoRouter-driven navigation.
class TradoriaApp extends StatelessWidget {
  const TradoriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Tradoria',
      debugShowCheckedModeBanner: false,
      // The routerConfig property hooks Tradoria into GoRouter's declarative navigation system.
      routerConfig: AppRouter.router,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        // Highlighting the selected accent color for modern interactions.
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.surface,
          secondary: AppColors.accent,
          // Replaced deprecated "background" with "surface" for forward compatibility.
          surfaceContainer: AppColors.surface,
        ),
        // Modern typography using Google Fonts (Inter) across all text elements.
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.surfaceHighlight),
          ),
        ),
      ),
    );
  }
}

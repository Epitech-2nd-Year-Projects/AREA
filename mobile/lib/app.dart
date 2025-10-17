import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/design_system/app_colors.dart';
import 'core/design_system/app_typography.dart';
import 'core/navigation/app_navigation.dart';
import 'features/auth/presentation/router/auth_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AREA - Automation Platform',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: _buildRouter(),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        background: AppColors.lightBackground,
        onBackground: AppColors.lightTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightDivider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.lightTextPrimary,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.lightDivider),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        background: AppColors.darkBackground,
        onBackground: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.darkTextPrimary,
        ),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(color: AppColors.darkDivider),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: AppNavigation.navigatorKey,
      initialLocation: '/',
      routes: AuthRouter.routes,
      redirect: (context, state) {
        final uri = state.uri;

        if (uri.scheme == 'area') {
          debugPrint('🔄 Custom scheme detected: ${uri.toString()}');

          final pathSegments = uri.pathSegments;

          debugPrint('🔄 Custom scheme pathSegments SIZE: ${pathSegments.length}');
          debugPrint('🔄 Custom scheme pathSegments 0: ${pathSegments[0]}');
          debugPrint('🔄 Custom scheme pathSegments 1: ${pathSegments[1]}');

          if (pathSegments.length >= 3 &&
              pathSegments[0] == 'services' &&
              pathSegments[2] == 'callback') {
            final provider = pathSegments[1];
            final code = uri.queryParameters['code'];
            final error = uri.queryParameters['error'];

            debugPrint('🔄 Service detected');

            final newUri = Uri(
              path: '/services/$provider/callback',
              queryParameters: {
                if (code != null) 'code': code,
                if (error != null) 'error': error,
                ...uri.queryParameters,
              },
            );

            debugPrint('🔀 Redirecting to: ${newUri.toString()}');
            return newUri.toString();
          }

          if (pathSegments.length >= 3 &&
              pathSegments[0] == 'oauth' &&
              pathSegments[2] == 'callback') {
            final provider = pathSegments[1];
            final code = uri.queryParameters['code'];
            final error = uri.queryParameters['error'];

            debugPrint('🔄 Oauth detected');

            final newUri = Uri(
              path: '/oauth/$provider/callback',
              queryParameters: {
                if (code != null) 'code': code,
                if (error != null) 'error': error,
                ...uri.queryParameters,
              },
            );

            debugPrint('🔀 Redirecting to: ${newUri.toString()}');
            return newUri.toString();
          }
          debugPrint('⚠️ Unhandled custom scheme, redirecting to dashboard');
          return '/';
        }
        return null;
      },
    );
  }
}
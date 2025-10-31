import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/accessibility/accessibility_controller.dart';
import 'core/accessibility/accessibility_route_announcer.dart';
import 'core/design_system/app_colors.dart';
import 'core/design_system/app_typography.dart';
import 'core/di/injector.dart';
import 'core/navigation/app_navigation.dart';
import 'features/auth/presentation/router/auth_router.dart';
import 'l10n/app_localizations.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router = _buildRouter();

  @override
  Widget build(BuildContext context) {
    final accessibility = sl<AccessibilityController>();

    return AnimatedBuilder(
      animation: accessibility,
      builder: (context, _) {
        final isColorBlindMode = accessibility.isColorBlindModeEnabled;

        return MaterialApp.router(
          title: 'AREA - Automation Platform',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: null,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (deviceLocale == null) {
              return const Locale('en');
            }
            for (final locale in supportedLocales) {
              if (locale.languageCode == deviceLocale.languageCode &&
                  locale.countryCode == deviceLocale.countryCode) {
                return locale;
              }
            }
            for (final locale in supportedLocales) {
              if (locale.languageCode == deviceLocale.languageCode) {
                return locale;
              }
            }
            return const Locale('en');
          },
          theme: _buildLightTheme(isColorBlindMode),
          darkTheme: _buildDarkTheme(isColorBlindMode),
          themeMode: ThemeMode.system,
          builder: (context, child) {
            final locale = Localizations.maybeLocaleOf(context);
            if (locale != null) {
              unawaited(accessibility.updateSpeechLocale(locale));
            }

            Widget content = child ?? const SizedBox.shrink();

            final filter = accessibility.colorBlindFilter;
            if (filter != null) {
              content = ColorFiltered(
                colorFilter: filter,
                child: content,
              );
            }

            if (accessibility.isScreenReaderEnabled) {
              content = Semantics(
                container: true,
                explicitChildNodes: true,
                child: content,
              );
            }

            return content;
          },
          routerConfig: _router,
        );
      },
    );
  }

  ThemeData _buildLightTheme(bool colorBlindAware) {
    final seed = colorBlindAware ? const Color(0xFF1B7F79) : AppColors.primary;
    final accent =
        colorBlindAware ? const Color(0xFFE29578) : AppColors.primaryLight;

    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
      ).copyWith(
        primary: seed,
        secondary: accent,
        tertiary: colorBlindAware ? const Color(0xFF006D77) : AppColors.primary,
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
          borderSide: BorderSide(color: seed, width: 2),
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
          backgroundColor: seed,
          foregroundColor: AppColors.white,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme(bool colorBlindAware) {
    final seed =
        colorBlindAware ? const Color(0xFF7AD1CC) : AppColors.primaryLight;
    final accent =
        colorBlindAware ? const Color(0xFFE29578) : AppColors.primaryDark;

    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
      ).copyWith(
        primary: seed,
        secondary: accent,
        tertiary: colorBlindAware ? const Color(0xFF006D77) : AppColors.primary,
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
          borderSide: BorderSide(color: seed, width: 2),
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
          backgroundColor: seed,
          foregroundColor: AppColors.darkTextPrimary,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: AppNavigation.navigatorKey,
      initialLocation: '/',
      observers: [AccessibilityRouteAnnouncer(sl<AccessibilityController>())],
      routes: AuthRouter.routes,
      redirect: (context, state) {
        final uri = state.uri;

        if (uri.scheme == 'area') {
          debugPrint('🔄 Custom scheme detected: ${uri.toString()}');
          debugPrint('🔄 Host: ${uri.host}');
          debugPrint('🔄 PathSegments: ${uri.pathSegments}');

          final pathSegments = uri.pathSegments;

          if (uri.host == 'services' &&
              pathSegments.length >= 2 &&
              pathSegments[1] == 'callback') {
            final provider = pathSegments[0];
            final code = uri.queryParameters['code'];
            final error = uri.queryParameters['error'];
            final state = uri.queryParameters['state'];

            debugPrint('✅ Service callback detected for: $provider');

            final newUri = Uri(
              path: '/services/$provider/callback',
              queryParameters: {
                if (code != null) 'code': code,
                if (error != null) 'error': error,
                if (state != null) 'state': state,
              },
            );

            debugPrint('🔀 Redirecting to: ${newUri.toString()}');
            return newUri.toString();
          }

          if (uri.host == 'oauth' &&
              pathSegments.length >= 2 &&
              pathSegments[1] == 'callback') {
            final provider = pathSegments[0];
            final code = uri.queryParameters['code'];
            final error = uri.queryParameters['error'];
            final state = uri.queryParameters['state'];
            final returnTo = uri.queryParameters['returnTo'];

            debugPrint('✅ OAuth callback detected for: $provider');

            final newUri = Uri(
              path: '/oauth/$provider/callback',
              queryParameters: {
                if (code != null) 'code': code,
                if (error != null) 'error': error,
                if (state != null) 'state': state,
                if (returnTo != null) 'returnTo': returnTo,
              },
            );

            debugPrint('🔀 Redirecting to: ${newUri.toString()}');
            return newUri.toString();
          }

          debugPrint('⚠️ Unhandled custom scheme, redirecting to home');
          return '/';
        }

        return null;
      },
    );
  }
}

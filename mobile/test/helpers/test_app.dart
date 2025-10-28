import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:area/l10n/app_localizations.dart';

/// Pumps a [MaterialApp] with localization and theme support around [child].
Future<void> pumpLocalizedWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  bool withScaffold = true,
  AssetBundle? assetBundle,
  List<NavigatorObserver>? navigatorObservers,
}) async {
  final Widget app = MaterialApp(
    locale: locale,
    themeMode: themeMode,
    theme: ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    navigatorObservers: navigatorObservers ?? const [],
    home: withScaffold ? Scaffold(body: child) : child,
  );

  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: assetBundle ?? _InMemoryAssetBundle(),
      child: app,
    ),
  );

  await tester.pump();
}

/// Simple asset bundle used in tests to avoid asset resolution failures.
class _InMemoryAssetBundle extends CachingAssetBundle {
  _InMemoryAssetBundle({Map<String, ByteData>? assets})
      : _assets = assets ?? const {};

  final Map<String, ByteData> _assets;

  @override
  Future<ByteData> load(String key) async {
    return _assets[key] ?? ByteData(0);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return '';
  }
}

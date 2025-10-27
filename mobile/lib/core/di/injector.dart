import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import 'di_modules.dart';
import 'modules/core_module.dart';
import 'modules/network_module.dart';
import 'modules/auth_module.dart';
import 'modules/services_module.dart';
import 'modules/areas_module.dart';
import 'modules/dashboard_module.dart';
import 'modules/settings_module.dart';

final sl = GetIt.instance;

class Injector {
  static final List<DIModule> _modules = [
    CoreModule(),
    NetworkModule(),
    AuthModule(),
    ServicesModule(),
    DashboardModule(),
    AreasModule(),
    SettingsModule(),
  ];

  static Future<void> setup() async {
    for (final module in _modules) {
      await module.register(sl);
    }
  }
  @visibleForTesting
  static void setTestModules(List<DIModule> testModules) {
    _modules
      ..clear()
      ..addAll(testModules);
  }
}

  /// Reset dependency injection for testing
  @visibleForTesting
  static Future<void> reset() async {
    await sl.reset();
  }
}

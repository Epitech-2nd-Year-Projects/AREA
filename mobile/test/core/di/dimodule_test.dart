import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:area/core/di/di_modules.dart';

class FakeDIModule implements DIModule {
  bool called = false;

  @override
  Future<void> register(GetIt sl) async {
    called = true;
    sl.registerSingleton<String>('registered');
  }
}

void main() {
  late GetIt sl;

  setUp(() {
    sl = GetIt.asNewInstance();
  });

  test('DIModule.register should be called', () async {
    final module = FakeDIModule();
    await module.register(sl);

    expect(module.called, isTrue);
    expect(sl<String>(), equals('registered'));
  });
}
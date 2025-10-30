import 'package:get_it/get_it.dart';

abstract class DIModule {
  Future<void> register(GetIt sl);
}

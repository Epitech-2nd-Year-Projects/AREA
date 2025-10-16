import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injector.dart';
import 'core/services/deep_link_service.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Injector.setup();

  runApp(
    BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: const MyApp(),
    ),
  );
}

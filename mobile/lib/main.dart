import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initCoreDependencies();

  runApp(
    BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: const MyApp(),
    ),
  );
}

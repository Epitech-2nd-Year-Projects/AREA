import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/injector.dart';
import 'core/network/api_config.dart';
import 'features/auth/presentation/blocs/auth_bloc.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  ApiConfig.initialize();
  await Injector.setup();
  runApp(
    BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>(),
      child: const MyApp(),
    ),
  );
}

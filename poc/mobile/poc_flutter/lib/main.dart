import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/api_client.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final client = await ApiClient.create("http://10.0.2.2:8080");
  final api = AuthApi(client.dio);
  final repo = AuthRepository(api);
  final cubit = AuthCubit(repo);

  await cubit.checkSessionOnStartup(client);
  runApp(
    BlocProvider(
      create: (_) => cubit,
      child: const MyApp(),
    ),
  );
}

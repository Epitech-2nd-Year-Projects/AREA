import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../auth_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await context.read<AuthCubit>().logout();
      final client = await ApiClient.create("http://10.0.2.2:8080");

      await client.cookieJar.deleteAll();
      Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
    } catch (e) {
      print("logout Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Logout impossible: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.watch<AuthCubit>().state is AuthAuthenticated)
        ? (context.watch<AuthCubit>().state as AuthAuthenticated).user.email
        : "unknown";

    return Scaffold(
      appBar: AppBar(title: Text("Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Welcome, your email is : $user 👋"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
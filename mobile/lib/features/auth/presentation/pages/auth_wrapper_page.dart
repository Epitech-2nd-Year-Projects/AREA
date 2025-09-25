import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/app_colors.dart';
import '../blocs/auth_bloc.dart';
import '../blocs/auth_event.dart';
import '../blocs/auth_state.dart';
import 'login_page.dart';

class AuthWrapperPage extends StatelessWidget {
  final Widget authenticatedChild;

  const AuthWrapperPage({
    super.key,
    required this.authenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is AuthInitial) {
          context.read<AuthBloc>().add(AppStarted());
          return _buildLoadingScreen(theme);
        }

        if (state is AuthLoading) {
          return _buildLoadingScreen(theme);
        }

        if (state is Authenticated) {
          return authenticatedChild;
        }

        return const LoginPage();
      },
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_spacing.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../blocs/login/login_cubit.dart';
import '../../blocs/login/login_state.dart';
import '../common/auth_text_field.dart';
import '../buttons/auth_button.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<LoginCubit, LoginState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                label: l10n.email,
                hintText: l10n.enterEmail,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterEmail;
                  }
                  return null;
                },
                enabled: state is! LoginLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: l10n.password,
                hintText: l10n.enterPassword,
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterPassword;
                  }
                  return null;
                },
                enabled: state is! LoginLoading,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthButton(
                text: l10n.login,
                onPressed: _handleLogin,
                isLoading: state is LoginLoading,
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginCubit>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }
}
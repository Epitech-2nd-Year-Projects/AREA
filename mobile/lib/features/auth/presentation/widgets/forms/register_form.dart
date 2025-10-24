import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_spacing.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../blocs/register/register_cubit.dart';
import '../../blocs/register/register_state.dart';
import '../common/auth_text_field.dart';
import '../buttons/auth_button.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RegisterCubit, RegisterState>(
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
                  if (!_isValidEmail(value)) {
                    return l10n.pleaseEnterValidEmail;
                  }
                  return null;
                },
                enabled: state is! RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: l10n.password,
                hintText: l10n.createStrongPassword,
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseEnterPassword;
                  }
                  if (value.length < 12) {
                    return l10n.passwordMinLength;
                  }
                  return null;
                },
                enabled: state is! RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: l10n.confirmPassword,
                hintText: l10n.confirmYourPassword,
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.pleaseConfirmPassword;
                  }
                  if (value != _passwordController.text) {
                    return l10n.passwordsDoNotMatch;
                  }
                  return null;
                },
                enabled: state is! RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthButton(
                text: l10n.createAccountButton,
                onPressed: _handleRegister,
                isLoading: state is RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTermsAndConditions(context, l10n),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermsAndConditions(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        l10n.agreeTermsAndPrivacy,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.getTextTertiaryColor(context),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[\w.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$").hasMatch(email);
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<RegisterCubit>().register(
        _emailController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
      );
    }
  }
}
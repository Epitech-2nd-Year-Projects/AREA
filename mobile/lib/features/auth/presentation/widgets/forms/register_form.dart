import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_spacing.dart';
import '../../../../../core/design_system/app_typography.dart';
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
    return BlocBuilder<RegisterCubit, RegisterState>(
      builder: (context, state) {
        return Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                label: 'Email',
                hintText: 'Enter your email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!_isValidEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                enabled: state is! RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Password',
                hintText: 'Create a strong password',
                controller: _passwordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
                enabled: state is! RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthTextField(
                label: 'Confirm Password',
                hintText: 'Confirm your password',
                controller: _confirmPasswordController,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                enabled: state is! RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.xl),
              AuthButton(
                text: 'Create Account',
                onPressed: _handleRegister,
                isLoading: state is RegisterLoading,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTermsAndConditions(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTermsAndConditions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        'By creating an account, you agree to our Terms of Service and Privacy Policy',
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
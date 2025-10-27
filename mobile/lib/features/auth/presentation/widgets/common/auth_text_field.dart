import 'package:flutter/material.dart';
import '../../../../../core/design_system/app_colors.dart';
import '../../../../../core/design_system/app_typography.dart';
import '../../../../../core/design_system/app_spacing.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _isObscured;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Focus(
          onFocusChange: (focused) {
            setState(() {
              _isFocused = focused;
            });
          },
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            onChanged: widget.onChanged,
            enabled: widget.enabled,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.getTextPrimaryColor(context),
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.getTextTertiaryColor(context),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? IconTheme(
                data: IconThemeData(
                  color: AppColors.getTextSecondaryColor(context),
                ),
                child: widget.prefixIcon!,
              )
                  : null,
              suffixIcon: _buildSuffixIcon(context),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: _buildBorder(context, AppColors.getBorderColor(context)),
              enabledBorder: _buildBorder(context, AppColors.getBorderColor(context)),
              focusedBorder: _buildBorder(context, theme.colorScheme.primary),
              errorBorder: _buildBorder(context, AppColors.error),
              focusedErrorBorder: _buildBorder(context, AppColors.error),
              disabledBorder: _buildBorder(context, AppColors.getBorderColor(context).withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(BuildContext context) {
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _isObscured ? Icons.visibility : Icons.visibility_off,
          color: AppColors.getTextSecondaryColor(context),
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _isObscured = !_isObscured;
          });
        },
      );
    }
    return widget.suffixIcon != null
        ? IconTheme(
      data: IconThemeData(
        color: AppColors.getTextSecondaryColor(context),
      ),
      child: widget.suffixIcon!,
    )
        : null;
  }

  OutlineInputBorder _buildBorder(BuildContext context, Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: color,
        width: _isFocused ? 2 : 1,
      ),
    );
  }
}
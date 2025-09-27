import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';

class ServicesSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String initialValue;

  const ServicesSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue = '',
  });

  @override
  State<ServicesSearchBar> createState() => _ServicesSearchBarState();
}

class _ServicesSearchBarState extends State<ServicesSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.getTextPrimaryColor(context),
        ),
        decoration: InputDecoration(
          hintText: 'Search services by name...',
          hintStyle: AppTypography.bodyLarge.copyWith(
            color: AppColors.getTextTertiaryColor(context),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.getTextSecondaryColor(context),
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
            onPressed: () {
              _controller.clear();
              widget.onSearch('');
              setState(() {});
            },
            icon: Icon(
              Icons.clear,
              color: AppColors.getTextSecondaryColor(context),
              size: 20,
            ),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
        onChanged: (value) {
          setState(() {});
          widget.onSearch(value);
        },
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
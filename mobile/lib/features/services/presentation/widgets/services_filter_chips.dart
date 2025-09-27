import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../domain/value_objects/service_category.dart';

class ServicesFilterChips extends StatelessWidget {
  final ServiceCategory? selectedCategory;
  final Function(ServiceCategory?) onCategorySelected;

  const ServicesFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [null, ...ServiceCategory.values];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = (category == null && selectedCategory == null) ||
              (category != null && selectedCategory == category);

          return FilterChip(
            label: Text(
              category == null ? 'All' : category.displayName,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppColors.getTextSecondaryColor(context),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onCategorySelected(category),
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.getSurfaceColor(context),
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.getBorderColor(context),
              ),
            ),
          );
        },
      ),
    );
  }
}
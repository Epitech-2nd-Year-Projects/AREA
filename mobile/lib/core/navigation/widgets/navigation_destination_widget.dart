import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_typography.dart';
import '../navigation_items.dart';

class NavigationDestinationWidget extends StatelessWidget {
  final NavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const NavigationDestinationWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? item.selectedIcon : item.icon,
            size: 26,
            color: isSelected
                ? theme.colorScheme.primary
                : AppColors.getTextSecondaryColor(context),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : AppColors.getTextSecondaryColor(context),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
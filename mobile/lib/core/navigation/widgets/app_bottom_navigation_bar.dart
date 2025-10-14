import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../../design_system/app_spacing.dart';
import '../navigation_items.dart';
import 'navigation_destination_widget.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AppBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        border: Border(
          top: BorderSide(
            color: AppColors.getBorderColor(context),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              AppNavigationItems.destinations.length,
                  (index) {
                final item = AppNavigationItems.destinations[index];
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: NavigationDestinationWidget(
                    item: item,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
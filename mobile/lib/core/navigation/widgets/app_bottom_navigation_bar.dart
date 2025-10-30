import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.lg,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(36),
                color: isDark
                    ? AppColors.darkSurface.withValues(alpha: 0.7)
                    : AppColors.lightSurface.withValues(alpha: 0.95),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.08),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(
                      alpha: isDark ? 0.3 : 0.25,
                    ),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.05)
                        : AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
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
        ),
      ),
    );
  }
}

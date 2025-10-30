import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/app_spacing.dart';

class ParallaxSliverAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final Widget? actionWidget;
  final List<Widget>? actions;
  final double expandedHeight;

  const ParallaxSliverAppBar({
    super.key,
    required this.title,
    required this.onBackPressed,
    this.actionWidget,
    this.actions,
    this.expandedHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      floating: false,
      backgroundColor: AppColors.getSurfaceColor(context),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onBackPressed,
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimaryColor(context),
          ),
          tooltip: 'Go back',
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        centerTitle: false,
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.05),
                AppColors.primary.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.03),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions:
          actions ??
          (actionWidget != null
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: actionWidget,
                  ),
                ]
              : null),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';

class ServicesLoadingShimmer extends StatelessWidget {
  const ServicesLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          const aspectRatio = 0.8;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildShimmerCard(context),
          );
        },
      ),
    );
  }

  Widget _buildShimmerCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.getSurfaceColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppColors.getBorderColor(context),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildShimmerBox(56, 56, borderRadius: 14),
            const SizedBox(height: AppSpacing.md),
            _buildShimmerBox(double.infinity, 20),
            const SizedBox(height: AppSpacing.xs),
            _buildShimmerBox(100, 16),
            const SizedBox(height: AppSpacing.sm),
            _buildShimmerBox(80, 24, borderRadius: 12),
            const Spacer(),
            _buildShimmerBox(60, 20, borderRadius: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox(
      double width,
      double height, {
        double borderRadius = 8,
      }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.gray200.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';

class ServiceDetailsLoadingView extends StatelessWidget {
  const ServiceDetailsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurfaceColor(context),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.getTextPrimaryColor(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildServiceInfoShimmer(context),
            const SizedBox(height: AppSpacing.lg),
            _buildComponentsShimmer(context),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceInfoShimmer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildShimmerBox(64, 64, borderRadius: 16),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmerBox(150, 24),
                    const SizedBox(height: AppSpacing.xs),
                    _buildShimmerBox(80, 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildShimmerBox(double.infinity, 16),
          const SizedBox(height: AppSpacing.md),
          _buildShimmerBox(double.infinity, 16),
        ],
      ),
    );
  }

  Widget _buildComponentsShimmer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.getBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmerBox(200, 24),
          const SizedBox(height: AppSpacing.lg),
          _buildShimmerBox(double.infinity, 40),
          const SizedBox(height: AppSpacing.lg),
          _buildShimmerBox(double.infinity, 48),
          const SizedBox(height: AppSpacing.lg),
          ...List.generate(
            3,
                (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildShimmerBox(double.infinity, 80),
            ),
          ),
        ],
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
        color: AppColors.gray200.withOpacity(0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
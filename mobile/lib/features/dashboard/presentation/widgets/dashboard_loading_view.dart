import 'package:flutter/material.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../services/presentation/widgets/animated_loading.dart';

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      shrinkWrap: true,
      itemBuilder: (_, index) {
        return const _LoadingCard();
      },
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
      itemCount: 5,
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return ProfessionalShimmer(
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
            width: 0.6,
          ),
        ),
      ),
    );
  }
}

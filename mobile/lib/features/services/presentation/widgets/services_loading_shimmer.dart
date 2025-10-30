import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import 'animated_loading.dart';

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
            itemBuilder: (context, index) => const ServiceCardSkeleton(),
          );
        },
      ),
    );
  }
}

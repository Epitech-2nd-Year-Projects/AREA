import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import 'animated_loading.dart';

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
            ServiceDetailsSkeletonSection(title: 'Service'),
            const SizedBox(height: AppSpacing.lg),
            ServiceDetailsSkeletonSection(title: 'Components', isCompact: true),
          ],
        ),
      ),
    );
  }
}
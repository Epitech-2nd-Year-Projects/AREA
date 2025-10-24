import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';

class ProfessionalShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const ProfessionalShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ProfessionalShimmer> createState() => _ProfessionalShimmerState();
}

class _ProfessionalShimmerState extends State<ProfessionalShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final position = _controller.value * 2 - 1;
        
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - position, 0),
              end: Alignment(1.0 - position, 0),
              colors: [
                Colors.transparent,
                isDark 
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.4),
                Colors.transparent,
              ],
              stops: const [0.2, 0.5, 0.8],
            ).createShader(bounds);
          },
          blendMode: BlendMode.overlay,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark 
                ? AppColors.slate700.withValues(alpha: 0.6)
                : AppColors.gray200.withValues(alpha: 0.7),
            isDark 
                ? AppColors.slate600.withValues(alpha: 0.4)
                : AppColors.gray100.withValues(alpha: 0.5),
            isDark 
                ? AppColors.slate700.withValues(alpha: 0.6)
                : AppColors.gray200.withValues(alpha: 0.7),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ServiceCardSkeleton extends StatelessWidget {
  const ServiceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ProfessionalShimmer(
      child: Card(
        elevation: 0,
        color: AppColors.getSurfaceColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.getBorderColor(context).withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon skeleton with gradient
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.3),
                      AppColors.primary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              
              // Title skeleton
              SkeletonCard(height: 20),
              const SizedBox(height: AppSpacing.sm),
              
              // Category skeleton - smaller width
              SkeletonCard(
                width: 100,
                height: 24,
                borderRadius: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceDetailsSkeletonSection extends StatelessWidget {
  final String? title;
  final bool isCompact;

  const ServiceDetailsSkeletonSection({
    super.key,
    this.title,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ProfessionalShimmer(
      child: Container(
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
            if (title != null) ...[
              SkeletonCard(width: 150, height: 24),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (!isCompact) ...[
              // Icon + text layout
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.3),
                          AppColors.primary.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonCard(height: 24),
                        const SizedBox(height: AppSpacing.xs),
                        SkeletonCard(width: 120, height: 20),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SkeletonCard(height: 16),
              const SizedBox(height: AppSpacing.md),
              SkeletonCard(height: 16),
            ] else ...[
              // Compact layout - multiple items
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SkeletonCard(height: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/services/logo_service.dart';

class ServiceLogo extends StatefulWidget {
  final String serviceName;
  final double size;
  final bool enableAnimation;

  const ServiceLogo({
    super.key,
    required this.serviceName,
    required this.size,
    this.enableAnimation = true,
  });

  @override
  State<ServiceLogo> createState() => _ServiceLogoState();
}

class _ServiceLogoState extends State<ServiceLogo> {
  late String logoUrl;
  bool _logoFailed = false;

  @override
  void initState() {
    super.initState();
    logoUrl = LogoService.getLogoUrl(widget.serviceName);
  }

  @override
  void didUpdateWidget(ServiceLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceName != widget.serviceName) {
      logoUrl = LogoService.getLogoUrl(widget.serviceName);
      _logoFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_logoFailed) {
      return _buildFallbackIcon(context);
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            setState(() {
              _logoFailed = true;
            });
            return _buildFallbackIcon(context);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            // Show gradient fallback while loading
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.3),
                  ),
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(widget.size * 0.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Text(
          widget.serviceName[0].toUpperCase(),
          style: AppTypography.displayMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: widget.size * 0.35,
          ),
        ),
      ),
    );
  }
}
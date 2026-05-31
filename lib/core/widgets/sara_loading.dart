import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Indicadores de loading reutilizáveis do SARA APP.
class SaraLoading extends StatelessWidget {
  final double size;
  final Color? color;
  final String? message;

  const SaraLoading({
    super.key,
    this.size = 40,
    this.color,
    this.message,
  });

  /// Loading centralizado em tela cheia.
  const SaraLoading.fullScreen({
    super.key,
    this.message,
  })  : size = 48,
       color = null;

  /// Loading inline pequeno.
  const SaraLoading.inline({
    super.key,
    this.color,
  })  : size = 24,
       message = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loadingColor = color ?? AppColors.primary;

    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: size > 30 ? 3.5 : 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
      ),
    );

    if (message == null && size <= 30) {
      return indicator;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer loading placeholder.
class SaraShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SaraShimmer({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.7),
      duration: const Duration(milliseconds: 1200),
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: isDark
                ? AppColors.darkSurfaceVariant.withValues(alpha: value)
                : AppColors.surfaceVariant.withValues(alpha: value),
          ),
        );
      },
    );
  }
}

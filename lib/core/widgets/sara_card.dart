import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Card com efeito glassmorphism reutilizável do SARA APP.
/// Suporta gradientes, sombras suaves e conteúdo customizado.
class SaraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Gradient? gradient;
  final double? elevation;
  final double borderRadius;
  final bool glassmorphism;
  final VoidCallback? onTap;
  final Border? border;

  const SaraCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.gradient,
    this.elevation,
    this.borderRadius = AppTheme.radiusLg,
    this.glassmorphism = false,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMd),
      margin: margin,
      decoration: BoxDecoration(
        color: glassmorphism
            ? (isDark
                ? AppColors.darkSurface.withValues(alpha: 0.6)
                : AppColors.surface.withValues(alpha: 0.7))
            : gradient != null
                ? null
                : color ?? Theme.of(context).cardTheme.color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ??
            (glassmorphism
                ? Border.all(
                    color: (isDark ? AppColors.darkBorder : AppColors.border)
                        .withValues(alpha: 0.3),
                    width: 1,
                  )
                : null),
        boxShadow: [
          if (!glassmorphism)
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.textPrimary)
                  .withValues(alpha: 0.06),
              blurRadius: (elevation ?? AppTheme.elevationSm) * 4,
              offset: Offset(0, (elevation ?? AppTheme.elevationSm) * 1.5),
            ),
        ],
      ),
      child: child,
    );

    if (glassmorphism) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}

/// Card de estatística com valor grande e label.
class SaraStatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const SaraStatCard({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGradient = gradient != null;

    return SaraCard(
      gradient: gradient,
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isGradient
                    ? Colors.white.withValues(alpha: 0.2)
                    : (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isGradient
                    ? Colors.white
                    : iconColor ?? AppColors.primary,
              ),
            ),
          if (icon != null) const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isGradient
                    ? Colors.white
                    : valueColor ??
                        (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isGradient
                  ? Colors.white.withValues(alpha: 0.85)
                  : isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

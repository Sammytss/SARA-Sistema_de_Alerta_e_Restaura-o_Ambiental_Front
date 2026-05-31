import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Botão primário do SARA APP com suporte a loading, ícone e gradiente.
class SaraButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  const SaraButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  /// Cria um botão preenchido (elevated).
  const SaraButton.filled({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  }) : isOutlined = false;

  /// Cria um botão com apenas borda (outlined).
  const SaraButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  })  : isOutlined = true,
       gradient = null;

  @override
  Widget build(BuildContext context) {
    final buttonPadding = padding ??
        const EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    if (gradient != null && !isOutlined) {
      return _buildGradientButton(context, buttonPadding);
    }

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              padding: buttonPadding,
              side: backgroundColor != null
                  ? BorderSide(color: backgroundColor!, width: 1.5)
                  : null,
            ),
            child: _buildChild(context),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              padding: buttonPadding,
            ),
            child: _buildChild(context),
          );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }

  Widget _buildGradientButton(BuildContext context, EdgeInsetsGeometry padding) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Padding(
            padding: padding,
            child: Center(child: _buildChild(context, isOnGradient: true)),
          ),
        ),
      ),
    );
  }

  Widget _buildChild(BuildContext context, {bool isOnGradient = false}) {
    final color = isOnGradient
        ? Colors.white
        : null;

    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: color != null ? TextStyle(color: color) : null),
        ],
      );
    }

    return Text(label, style: color != null ? TextStyle(color: color) : null);
  }
}

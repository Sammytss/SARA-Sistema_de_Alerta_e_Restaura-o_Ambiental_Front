import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

/// AppBar customizada reutilizável do SARA APP.
/// Suporta modo transparente com glassmorphism, ações e título customizado.
class SaraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final bool transparent;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final double elevation;

  const SaraAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBack = true,
    this.transparent = false,
    this.onBackPressed,
    this.leading,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (transparent) {
      return ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: (isDark
                    ? AppColors.darkSurface
                    : AppColors.surface)
                .withValues(alpha: 0.8),
            elevation: 0,
            leading: _buildLeading(context),
            title: _buildTitle(context),
            actions: actions,
            centerTitle: false,
          ),
        ),
      );
    }

    return AppBar(
      elevation: elevation,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      actions: actions,
      centerTitle: false,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!showBack) return null;
    if (!Navigator.of(context).canPop()) return null;

    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
      onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      tooltip: 'Voltar',
    );
  }

  Widget? _buildTitle(BuildContext context) {
    if (titleWidget != null) return titleWidget;
    if (title == null) return null;
    return Text(title!);
  }
}

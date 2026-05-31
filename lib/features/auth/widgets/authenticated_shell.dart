import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../access_control/user_role.dart';
import '../../alerts/alerts_provider.dart';
import '../auth_provider.dart';

/// Shell para telas autenticadas com navegação lateral e perfil.
class AuthenticatedShell extends ConsumerWidget {
  final Widget child;

  const AuthenticatedShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.usuario;

    // Dispara notificação local para alertas de alta/crítica severidade
    // na primeira vez que são carregados em cada sessão.
    ref.listen(todosAlertasProvider, (_, next) {
      next.whenData(NotificationService().notificarPendentes);
    });

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, ref, user),
      body: child,
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.eco_rounded, size: 20),
          const SizedBox(width: 8),
          const Text('SARA'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _getRoleColor(user.perfil).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              user.perfil.displayName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _getRoleColor(user.perfil),
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Botão de logout
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) {
              context.go('/');
            }
          },
          tooltip: 'Sair',
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.gestor:
        return AppColors.roleGestor;
      case UserRole.tecnico:
        return AppColors.roleTecnico;
      case UserRole.produtor:
        return AppColors.roleProdutor;
      case UserRole.analista:
        return AppColors.roleAnalista;
      case UserRole.auditor:
        return AppColors.roleAuditor;
      case UserRole.operario:
        return AppColors.roleOperario;
      default:
        return AppColors.rolePublic;
    }
  }
}

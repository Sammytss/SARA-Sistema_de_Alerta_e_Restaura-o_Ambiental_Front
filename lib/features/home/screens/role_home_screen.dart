import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../auth/auth_provider.dart';
import '../../areas/widgets/areas_list_body.dart';

/// Tela home genérica para perfis que ainda terão telas detalhadas nas próximas partes.
/// Usada temporariamente por Produtor, Analista, Auditor e Operário.
class RoleHomeScreen extends ConsumerWidget {
  final String roleName;
  final IconData roleIcon;
  final Color roleColor;
  final List<MenuItem> menuItems;

  const RoleHomeScreen({
    super.key,
    required this.roleName,
    required this.roleIcon,
    required this.roleColor,
    required this.menuItems,
  });

  /// Tela do Produtor — lista das próprias áreas.
  /// Retorna AreasListBody pois é usada dentro do ShellRoute.
  static Widget produtor() => const AreasListBody();

  /// Tela do Analista.
  factory RoleHomeScreen.analista() => RoleHomeScreen(
    roleName: 'Analista',
    roleIcon: Icons.analytics_rounded,
    roleColor: AppColors.roleAnalista,
    menuItems: [
      MenuItem(Icons.inbox_rounded, 'Áreas para Análise', 'Fila de análise pendente'),
      MenuItem(Icons.fact_check_rounded, 'Vistorias Recebidas', 'Avaliar vistorias'),
      MenuItem(Icons.verified_rounded, 'Validar Evidências', 'Aprovar ou rejeitar'),
      MenuItem(Icons.warning_amber_rounded, 'Classificar Risco', 'Categorizar áreas'),
      MenuItem(Icons.reply_rounded, 'Solicitar Complementação', 'Pedir mais informações'),
      MenuItem(Icons.history_rounded, 'Histórico Técnico', 'Histórico completo'),
    ],
  );

  /// Tela do Auditor.
  factory RoleHomeScreen.auditor() => RoleHomeScreen(
    roleName: 'Auditor',
    roleIcon: Icons.shield_rounded,
    roleColor: AppColors.roleAuditor,
    menuItems: [
      MenuItem(Icons.search_rounded, 'Consultar Áreas', 'Visualização completa'),
      MenuItem(Icons.history_rounded, 'Histórico de Alterações', 'Log de modificações'),
      MenuItem(Icons.terminal_rounded, 'Logs do Sistema', 'Logs detalhados'),
      MenuItem(Icons.photo_library_rounded, 'Evidências', 'Fotos e documentos'),
      MenuItem(Icons.description_rounded, 'Relatórios', 'Relatórios de conformidade'),
      MenuItem(Icons.account_tree_rounded, 'Trilha de Auditoria', 'Rastreabilidade'),
    ],
  );

  /// Tela do Operário.
  factory RoleHomeScreen.operario() => RoleHomeScreen(
    roleName: 'Operário',
    roleIcon: Icons.construction_rounded,
    roleColor: AppColors.roleOperario,
    menuItems: [
      MenuItem(Icons.task_alt_rounded, 'Minhas Tarefas', 'Tarefas atribuídas'),
      MenuItem(Icons.checklist_rounded, 'Registrar Execução', 'Registrar atividade'),
      MenuItem(Icons.camera_alt_rounded, 'Foto da Atividade', 'Comprovação fotográfica'),
      MenuItem(Icons.sync_rounded, 'Sincronizar', 'Pendências de envio'),
    ],
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).usuario;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ──────────────────────────────────
          Text(
            'Olá, ${user?.nome ?? roleName}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(roleIcon, size: 16, color: roleColor),
              const SizedBox(width: 6),
              Text(
                'Perfil: $roleName',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: roleColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // ── Auditor Read-only badge ───────────────────
          if (roleName == 'Auditor') ...[
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_rounded, size: 14, color: AppColors.info),
                  const SizedBox(width: 6),
                  Text(
                    'Modo somente leitura',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.info,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppTheme.spacingLg),

          // ── Menu Grid ─────────────────────────────────
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacingSm,
              crossAxisSpacing: AppTheme.spacingSm,
              childAspectRatio: 1.2,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return SaraCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${item.title} — Em desenvolvimento')),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, color: roleColor, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        item.subtitle,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextTertiary
                              : AppColors.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const MenuItem(this.icon, this.title, this.subtitle);
}

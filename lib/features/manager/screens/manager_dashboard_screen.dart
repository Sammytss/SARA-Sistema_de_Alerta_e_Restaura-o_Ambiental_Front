import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../core/widgets/sara_loading.dart';
import '../../../data/models/area_monitorada.dart';
import '../../../features/alerts/alerts_provider.dart';
import '../../../features/areas/areas_provider.dart';
import '../dashboard_provider.dart';

/// Dashboard do Gestor — visão consolidada com dados reais do banco local.
class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumoAsync = ref.watch(dashboardResumoProvider);
    final areasAsync = ref.watch(areasDoUsuarioProvider);
    final pendenciasAsync = ref.watch(pendenciasCountProvider);
    final alertasNaoLidos = ref.watch(alertasNaoLidosProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardResumoProvider);
        ref.invalidate(areasDoUsuarioProvider);
        ref.invalidate(todosAlertasProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: resumoAsync.when(
          loading: () => const SaraLoading(message: 'Carregando dashboard...'),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (resumo) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabeçalho com timestamp ─────────────────────
              _buildHeader(context, resumo),
              const SizedBox(height: AppTheme.spacingMd),

              // ── Grid de totais ──────────────────────────────
              _buildSectionTitle(
                  context, 'Visão Geral', Icons.dashboard_rounded),
              const SizedBox(height: AppTheme.spacingSm),
              _buildTotaisGrid(
                  context, resumo, pendenciasAsync, alertasNaoLidos),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Distribuição por status ─────────────────────
              _buildSectionTitle(
                  context, 'Por Status', Icons.pie_chart_rounded),
              const SizedBox(height: AppTheme.spacingSm),
              _buildStatusDistribution(context, resumo),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Média de regeneração ────────────────────────
              _buildSectionTitle(
                  context, 'Regeneração Média', Icons.eco_rounded),
              const SizedBox(height: AppTheme.spacingSm),
              _buildMediaRegeneracao(context, resumo.mediaRegeneracao),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Alertas ─────────────────────────────────────
              if (alertasNaoLidos > 0) ...[
                _buildSectionTitle(
                    context, 'Alertas Ativos', Icons.warning_amber_rounded),
                const SizedBox(height: AppTheme.spacingSm),
                _buildAlertasCard(context, alertasNaoLidos),
                const SizedBox(height: AppTheme.spacingLg),
              ],

              // ── Áreas que precisam de atenção ───────────────
              _buildSectionTitle(context, 'Requer Atenção',
                  Icons.priority_high_rounded),
              const SizedBox(height: AppTheme.spacingSm),
              ...areasAsync.when(
                loading: () => [
                  const Center(child: CircularProgressIndicator()),
                ],
                error: (e, _) => [Text('Erro ao carregar áreas: $e')],
                data: (areas) => _buildAreasDestaque(context, areas),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // ── Ações rápidas ───────────────────────────────
              _buildAcoesRapidas(context, resumo.total),
              const SizedBox(height: AppTheme.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DashboardResumo resumo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SaraCard(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: const Icon(Icons.account_balance_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard NATURATINS',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${resumo.total} áreas • ${resumo.totalEvidencias} evidências',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            'Ao vivo',
            style: TextStyle(
              color: AppColors.statusRecuperacao,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.statusRecuperacao,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildTotaisGrid(
    BuildContext context,
    DashboardResumo resumo,
    AsyncValue<int> pendenciasAsync,
    int alertasNaoLidos,
  ) {
    final pendencias = pendenciasAsync.valueOrNull ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spacingSm,
      crossAxisSpacing: AppTheme.spacingSm,
      childAspectRatio: 1.55,
      children: [
        _buildStatCard(context, '${resumo.total}', 'Total de áreas',
            Icons.landscape_rounded, AppColors.accent),
        _buildStatCard(context, '${resumo.critica}', 'Críticas',
            Icons.error_outline_rounded, AppColors.statusCritica),
        _buildStatCard(context, '${resumo.atencao}', 'Em atenção',
            Icons.warning_amber_rounded, AppColors.statusAtencao),
        _buildStatCard(
          context,
          alertasNaoLidos > 0 ? '$alertasNaoLidos' : '$pendencias',
          alertasNaoLidos > 0 ? 'Alertas novos' : 'Envios pendentes',
          alertasNaoLidos > 0
              ? Icons.notifications_active_rounded
              : Icons.cloud_off_rounded,
          alertasNaoLidos > 0 ? AppColors.error : AppColors.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return SaraCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDistribution(
      BuildContext context, DashboardResumo resumo) {
    if (resumo.total == 0) return const SizedBox.shrink();

    final regular = resumo.regular;
    final atencao = resumo.atencao;
    final critica = resumo.critica;
    final total = resumo.total;

    return SaraCard(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  if (regular > 0)
                    Expanded(
                      flex: regular,
                      child: Container(color: AppColors.statusRecuperacao),
                    ),
                  if (atencao > 0)
                    Expanded(
                      flex: atencao,
                      child: Container(color: AppColors.statusAtencao),
                    ),
                  if (critica > 0)
                    Expanded(
                      flex: critica,
                      child: Container(color: AppColors.statusCritica),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDistItem(
                  context, '$regular', 'Regular', AppColors.statusRecuperacao),
              _buildDistItem(
                  context, '$atencao', 'Atenção', AppColors.statusAtencao),
              _buildDistItem(
                  context, '$critica', 'Crítica', AppColors.statusCritica),
              _buildDistItem(context, '$total', 'Total', AppColors.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistItem(
      BuildContext context, String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
        ),
      ],
    );
  }

  Widget _buildMediaRegeneracao(BuildContext context, double media) {
    final color = media >= 60
        ? AppColors.statusRecuperacao
        : media >= 40
            ? AppColors.statusAtencao
            : AppColors.statusCritica;

    return SaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${media.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                'de regeneração média',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: media / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertasCard(BuildContext context, int count) {
    return SaraCard(
      onTap: () => context.push('/alerts'),
      border: Border(
          left: BorderSide(color: AppColors.error, width: 3)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.error, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${count == 1 ? 'alerta não lido' : 'alertas não lidos'}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                ),
                Text(
                  'Toque para ver todos os alertas',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary),
        ],
      ),
    );
  }

  List<Widget> _buildAreasDestaque(
      BuildContext context, List<AreaMonitorada> areas) {
    final destaque = [
      ...areas.where((a) => a.status == AreaStatus.critica),
      ...areas.where((a) => a.status == AreaStatus.atencao),
    ].take(4).toList();

    if (destaque.isEmpty) {
      return [
        SaraCard(
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.statusRecuperacao),
              const SizedBox(width: 10),
              Text(
                'Todas as áreas estão regulares!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.statusRecuperacao,
                    ),
              ),
            ],
          ),
        ),
      ];
    }

    return destaque.map((area) {
      final color = area.status == AreaStatus.critica
          ? AppColors.statusCritica
          : AppColors.statusAtencao;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: SaraCard(
          onTap: () => context.push('/area/${area.id}'),
          border: Border(left: BorderSide(color: color, width: 3)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.nome,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      '${area.municipio} • '
                      '${area.percentualRegeneracao.toStringAsFixed(0)}% regeneração',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildAcoesRapidas(BuildContext context, int totalAreas) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/manager/map'),
            icon: const Icon(Icons.map_rounded),
            label: const Text('Ver mapa consolidado'),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/areas'),
            icon: const Icon(Icons.list_alt_rounded),
            label: Text('Ver todas as áreas ($totalAreas)'),
          ),
        ),
      ],
    );
  }
}

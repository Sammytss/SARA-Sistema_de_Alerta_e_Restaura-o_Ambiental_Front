import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/public_models.dart';

/// Dashboard público do SARA APP.
/// Conforme Seção 2 — Acesso público sem login.
/// Mostra apenas dados agregados, sem informações sensíveis.
class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final resumo = MockData.resumoGeral;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ─────────────────────────────────
          _buildHeroHeader(context, resumo),

          // ── Conteúdo ────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Estatísticas ────────────────────────────
                _buildSectionTitle(context, 'Visão Geral', Icons.dashboard_rounded),
                const SizedBox(height: AppTheme.spacingSm),
                _buildStatsGrid(context, resumo),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Explorar ─────────────────────────────────
                _buildSectionTitle(context, 'Explorar', Icons.explore_rounded),
                const SizedBox(height: AppTheme.spacingSm),
                _buildExploreGrid(context),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Municípios ──────────────────────────────
                _buildSectionTitle(context, 'Por Município', Icons.location_city_rounded),
                const SizedBox(height: AppTheme.spacingSm),
                ...MockData.municipios.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: _buildMunicipioCard(context, m),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Alertas ─────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _buildSectionTitle(context, 'Alertas Ambientais', Icons.warning_amber_rounded)),
                    TextButton(
                      onPressed: () => context.push('/public/alerts'),
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                ...MockData.alertas.take(2).map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                    child: _buildAlertCard(context, a),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // ── Sobre ───────────────────────────────────
                _buildAboutCard(context),
                const SizedBox(height: AppTheme.spacingMd),

                // ── Acesso autenticado ────────────────────────
                _buildLoginCard(context),
                const SizedBox(height: AppTheme.spacingXl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, PublicResumo resumo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      // Título só aparece quando o hero está colapsado (após scroll)
      title: const Text(
        'Painel Público',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => context.go('/'),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
          onPressed: () => context.push('/public/about'),
          tooltip: 'Sobre o SARA',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppColors.darkHeroGradient
                : AppColors.heroGradient,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'SARA',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${resumo.totalAreasMonitoradas} áreas monitoradas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última atualização: ${_formatDate(resumo.ultimaAtualizacao)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExploreGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spacingSm,
      crossAxisSpacing: AppTheme.spacingSm,
      childAspectRatio: 2.2,
      children: [
        _buildExploreButton(
          context,
          icon: Icons.map_rounded,
          label: 'Mapa',
          color: AppColors.accent,
          route: '/public/map',
        ),
        _buildExploreButton(
          context,
          icon: Icons.bar_chart_rounded,
          label: 'Indicadores',
          color: AppColors.primary,
          route: '/public/indicators',
        ),
        _buildExploreButton(
          context,
          icon: Icons.warning_amber_rounded,
          label: 'Alertas',
          color: AppColors.warning,
          route: '/public/alerts',
        ),
        _buildExploreButton(
          context,
          icon: Icons.school_rounded,
          label: 'Educação',
          color: AppColors.secondary,
          route: '/public/education',
        ),
      ],
    );
  }

  Widget _buildExploreButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String route,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SaraCard(
      onTap: () => context.push(route),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return SaraCard(
      gradient: AppColors.accentGradient,
      onTap: () => context.go('/login'),
      child: Row(
        children: [
          const Icon(Icons.lock_open_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acesso profissional',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Entre com sua conta para acessar informações detalhadas',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, PublicResumo resumo) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.spacingSm,
      crossAxisSpacing: AppTheme.spacingSm,
      childAspectRatio: 1.2,
      children: [
        SaraStatCard(
          value: '${resumo.totalAreasMonitoradas}',
          label: 'Total monitoradas',
          icon: Icons.landscape_rounded,
          iconColor: AppColors.accent,
        ),
        SaraStatCard(
          value: '${resumo.areasRegulares}',
          label: 'Regulares',
          icon: Icons.check_circle_outline_rounded,
          iconColor: AppColors.statusRecuperacao,
          valueColor: AppColors.statusRecuperacao,
        ),
        SaraStatCard(
          value: '${resumo.areasAtencao}',
          label: 'Em atenção',
          icon: Icons.warning_amber_rounded,
          iconColor: AppColors.statusAtencao,
          valueColor: AppColors.statusAtencao,
        ),
        SaraStatCard(
          value: '${resumo.areasCriticas}',
          label: 'Críticas',
          icon: Icons.error_outline_rounded,
          iconColor: AppColors.statusCritica,
          valueColor: AppColors.statusCritica,
        ),
      ],
    );
  }

  Widget _buildMunicipioCard(BuildContext context, PublicAreaSummary municipio) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SaraCard(
      onTap: () => context.push('/public/map'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      municipio.municipio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Região ${municipio.regiao} • ${municipio.quantidadeAreas} áreas',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de evolução
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getEvolucaoColor(municipio.percentualEvolucaoMedio)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      municipio.percentualEvolucaoMedio >= 60
                          ? Icons.trending_up_rounded
                          : municipio.percentualEvolucaoMedio >= 40
                              ? Icons.trending_flat_rounded
                              : Icons.trending_down_rounded,
                      size: 14,
                      color: _getEvolucaoColor(municipio.percentualEvolucaoMedio),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${municipio.percentualEvolucaoMedio.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _getEvolucaoColor(municipio.percentualEvolucaoMedio),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barra de progresso segmentada
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: municipio.areasRegulares,
                    child: Container(color: AppColors.statusRegular),
                  ),
                  Expanded(
                    flex: municipio.areasEmRecuperacao,
                    child: Container(color: AppColors.statusRecuperacao),
                  ),
                  Expanded(
                    flex: municipio.areasEmAtencao,
                    child: Container(color: AppColors.statusAtencao),
                  ),
                  Expanded(
                    flex: municipio.areasCriticas,
                    child: Container(color: AppColors.statusCritica),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Legenda
          Row(
            children: [
              _buildLegendItem(context, 'Regular', AppColors.statusRegular,
                  '${municipio.areasRegulares}'),
              const SizedBox(width: 12),
              _buildLegendItem(context, 'Recup.', AppColors.statusRecuperacao,
                  '${municipio.areasEmRecuperacao}'),
              const SizedBox(width: 12),
              _buildLegendItem(context, 'Atenção', AppColors.statusAtencao,
                  '${municipio.areasEmAtencao}'),
              const SizedBox(width: 12),
              _buildLegendItem(context, 'Crítica', AppColors.statusCritica,
                  '${municipio.areasCriticas}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      BuildContext context, String label, Color color, String count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextTertiary
                : AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(BuildContext context, PublicAlert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor(alert.severidade);

    return SaraCard(
      border: Border(
        left: BorderSide(color: severityColor, width: 4),
      ),
      borderRadius: AppTheme.radiusMd,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              _getAlertIcon(alert.tipo),
              size: 20,
              color: severityColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.titulo,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.descricao,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${alert.regiao} • ${_formatDate(alert.dataPublicacao)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return SaraCard(
      gradient: AppColors.primaryGradient,
      onTap: () => context.push('/public/about'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Sobre o SARA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'O Sistema de Acompanhamento da Restauração Ambiental (SARA) é uma ferramenta '
            'desenvolvida para monitorar e promover a recuperação de áreas degradadas no Estado do Tocantins.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'O PRAD (Plano de Recuperação de Área Degradada) é o instrumento técnico '
            'que orienta as ações de restauração ambiental.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Color _getEvolucaoColor(double percentual) {
    if (percentual >= 60) return AppColors.statusRecuperacao;
    if (percentual >= 40) return AppColors.statusAtencao;
    return AppColors.statusCritica;
  }

  Color _getSeverityColor(String severidade) {
    switch (severidade) {
      case 'alto':
        return AppColors.error;
      case 'medio':
        return AppColors.warning;
      case 'baixo':
        return AppColors.info;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _getAlertIcon(String tipo) {
    switch (tipo) {
      case 'queimada':
        return Icons.local_fire_department_rounded;
      case 'seca':
        return Icons.water_drop_outlined;
      case 'desmatamento':
        return Icons.forest_rounded;
      case 'atualizacao':
        return Icons.update_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

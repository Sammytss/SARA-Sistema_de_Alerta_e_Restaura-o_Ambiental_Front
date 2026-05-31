import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../core/widgets/sara_loading.dart';
import '../../../features/manager/dashboard_provider.dart';

/// Tela de indicadores públicos de evolução do SARA APP.
/// Exibe apenas dados agregados do banco local — sem informações sensíveis.
class PublicIndicatorsScreen extends ConsumerWidget {
  const PublicIndicatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumoAsync = ref.watch(dashboardResumoProvider);
    final municipiosAsync = ref.watch(dashboardMunicipiosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores de Restauração'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: resumoAsync.when(
        loading: () =>
            const SaraLoading(message: 'Carregando indicadores...'),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (resumo) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Totais rápidos ───────────────────────────────
              _buildSectionTitle(
                  context, 'Panorama Geral', Icons.bar_chart_rounded),
              const SizedBox(height: AppTheme.spacingSm),
              _buildTotaisRow(context, resumo),
              const SizedBox(height: AppTheme.spacingLg),

              // ── Distribuição geral ───────────────────────────
              if (resumo.total > 0) ...[
                _buildSectionTitle(
                    context, 'Distribuição por Status', Icons.pie_chart_rounded),
                const SizedBox(height: AppTheme.spacingSm),
                SaraCard(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 50,
                            startDegreeOffset: -90,
                            sections: _buildPieSections(resumo),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildLegendItem(context, 'Regulares',
                              AppColors.statusRegular, '${resumo.regular}'),
                          _buildLegendItem(context, 'Em atenção',
                              AppColors.statusAtencao, '${resumo.atencao}'),
                          _buildLegendItem(context, 'Críticas',
                              AppColors.statusCritica, '${resumo.critica}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],

              // ── Por município ─────────────────────────────────
              _buildSectionTitle(
                  context, 'Por Município', Icons.map_outlined),
              const SizedBox(height: AppTheme.spacingSm),
              municipiosAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Erro: $e'),
                data: (municipios) => municipios.isEmpty
                    ? SaraCard(
                        child: Text(
                          'Nenhum dado por município disponível.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    : Column(
                        children: [
                          SaraCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Áreas monitoradas por município',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                SizedBox(
                                  height: 200,
                                  child: BarChart(
                                    BarChartData(
                                      alignment:
                                          BarChartAlignment.spaceAround,
                                      maxY: (municipios
                                                  .map((m) => m.total)
                                                  .reduce((a, b) =>
                                                      a > b ? a : b) *
                                              1.3)
                                          .toDouble(),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData:
                                            BarTouchTooltipData(
                                          getTooltipItem: (group,
                                              groupIndex, rod, rodIndex) {
                                            final m =
                                                municipios[group.x];
                                            return BarTooltipItem(
                                              '${m.municipio}\n${m.total} áreas',
                                              const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11),
                                            );
                                          },
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 36,
                                            getTitlesWidget: (v, meta) {
                                              final idx = v.toInt();
                                              if (idx < 0 ||
                                                  idx >= municipios.length) {
                                                return const SizedBox
                                                    .shrink();
                                              }
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        top: 6),
                                                child: Text(
                                                  municipios[idx]
                                                      .municipio
                                                      .split(' ')
                                                      .first,
                                                  style: const TextStyle(
                                                      fontSize: 10),
                                                  textAlign:
                                                      TextAlign.center,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 28,
                                            getTitlesWidget: (v, meta) {
                                              if (v % 1 != 0) {
                                                return const SizedBox
                                                    .shrink();
                                              }
                                              return Text(
                                                '${v.toInt()}',
                                                style: const TextStyle(
                                                    fontSize: 10),
                                              );
                                            },
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false)),
                                        rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(
                                                showTitles: false)),
                                      ),
                                      gridData: const FlGridData(
                                          show: true,
                                          drawVerticalLine: false),
                                      borderData:
                                          FlBorderData(show: false),
                                      barGroups: List.generate(
                                        municipios.length,
                                        (i) {
                                          final m = municipios[i];
                                          double y0 = 0;
                                          final reg = m.regular.toDouble();
                                          final atc = m.atencao.toDouble();
                                          final cri = m.critica.toDouble();
                                          return BarChartGroupData(
                                            x: i,
                                            barRods: [
                                              BarChartRodData(
                                                toY: m.total.toDouble(),
                                                width: 26,
                                                borderRadius:
                                                    const BorderRadius
                                                        .vertical(
                                                  top: Radius.circular(4),
                                                ),
                                                rodStackItems: [
                                                  if (reg > 0)
                                                    BarChartRodStackItem(
                                                        y0,
                                                        y0 += reg,
                                                        AppColors
                                                            .statusRegular),
                                                  if (atc > 0)
                                                    BarChartRodStackItem(
                                                        y0,
                                                        y0 += atc,
                                                        AppColors
                                                            .statusAtencao),
                                                  if (cri > 0)
                                                    BarChartRodStackItem(
                                                        y0,
                                                        y0 + cri,
                                                        AppColors
                                                            .statusCritica),
                                                ],
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingMd),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 6,
                                  children: [
                                    _buildLegendItem(context, 'Regular',
                                        AppColors.statusRegular, null),
                                    _buildLegendItem(context, 'Em atenção',
                                        AppColors.statusAtencao, null),
                                    _buildLegendItem(context, 'Crítica',
                                        AppColors.statusCritica, null),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),

                          // Evolução por município
                          _buildSectionTitle(context, 'Regeneração Média',
                              Icons.trending_up_rounded),
                          const SizedBox(height: AppTheme.spacingSm),
                          ...municipios.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppTheme.spacingSm),
                              child: _buildEvolucaoRow(context, m.municipio,
                                  m.mediaRegeneracao),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingLg),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(DashboardResumo resumo) {
    final total = resumo.total;
    if (total == 0) return [];

    final sections = <PieChartSectionData>[];
    const titleStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );

    void addSection(int count, Color color) {
      if (count <= 0) return;
      final pct = (count / total * 100).toStringAsFixed(0);
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        color: color,
        title: '$pct%',
        radius: 80,
        titleStyle: titleStyle,
      ));
    }

    addSection(resumo.regular, AppColors.statusRegular);
    addSection(resumo.atencao, AppColors.statusAtencao);
    addSection(resumo.critica, AppColors.statusCritica);

    return sections;
  }

  Widget _buildTotaisRow(BuildContext context, DashboardResumo resumo) {
    return Row(
      children: [
        _buildTotalChip(
            context, '${resumo.total}', 'Áreas', AppColors.accent),
        const SizedBox(width: AppTheme.spacingSm),
        _buildTotalChip(context, '${resumo.totalEvidencias}', 'Evidências',
            AppColors.primary),
        const SizedBox(width: AppTheme.spacingSm),
        _buildTotalChip(
            context,
            '${resumo.mediaRegeneracao.toStringAsFixed(0)}%',
            'Regeneração',
            AppColors.statusRecuperacao),
      ],
    );
  }

  Widget _buildTotalChip(
      BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: SaraCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(
      BuildContext context, String label, Color color, String? count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          count != null ? '$label ($count)' : label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkTextSecondary
                    : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }

  Widget _buildEvolucaoRow(
      BuildContext context, String municipio, double percentual) {
    final color = percentual >= 60
        ? AppColors.statusRecuperacao
        : percentual >= 40
            ? AppColors.statusAtencao
            : AppColors.statusCritica;

    return SaraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              municipio,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentual / 100,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${percentual.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

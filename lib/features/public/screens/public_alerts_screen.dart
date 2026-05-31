import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/public_models.dart';

/// Tela completa de alertas ambientais públicos do SARA APP.
class PublicAlertsScreen extends StatefulWidget {
  const PublicAlertsScreen({super.key});

  @override
  State<PublicAlertsScreen> createState() => _PublicAlertsScreenState();
}

class _PublicAlertsScreenState extends State<PublicAlertsScreen> {
  String _filterSeveridade = 'todos';

  List<PublicAlert> get _alertasFiltrados {
    final alertas = MockData.alertas;
    if (_filterSeveridade == 'todos') return alertas;
    return alertas.where((a) => a.severidade == _filterSeveridade).toList();
  }

  @override
  Widget build(BuildContext context) {
    final alertasFiltrados = _alertasFiltrados;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas Ambientais'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────────────
          _buildFilterBar(context),

          // ── Lista ────────────────────────────────────────────
          Expanded(
            child: alertasFiltrados.isEmpty
                ? _buildEmpty(context)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    itemCount: alertasFiltrados.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, index) {
                      return _buildAlertCard(context, alertasFiltrados[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(context, 'Todos', 'todos', Icons.list_rounded),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Alto', 'alto', Icons.error_rounded, AppColors.error),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Médio', 'medio', Icons.warning_rounded, AppColors.warning),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Baixo', 'baixo', Icons.info_rounded, AppColors.info),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    final isSelected = _filterSeveridade == value;
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : chipColor),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterSeveridade = value),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? chipColor : AppColors.border),
      backgroundColor: Colors.transparent,
      showCheckmark: false,
    );
  }

  Widget _buildAlertCard(BuildContext context, PublicAlert alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor(alert.severidade);
    final icon = _getAlertIcon(alert.tipo);

    return SaraCard(
      border: Border(left: BorderSide(color: severityColor, width: 4)),
      borderRadius: AppTheme.radiusMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, size: 22, color: severityColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.titulo,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _buildSeverityBadge(context, alert.severidade, severityColor),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.descricao,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                alert.municipio != null
                    ? '${alert.municipio} • ${alert.regiao}'
                    : alert.regiao,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(alert.dataPublicacao),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(BuildContext context, String severidade, Color color) {
    final label = switch (severidade) {
      'alto' => 'ALTO',
      'medio' => 'MÉDIO',
      'baixo' => 'BAIXO',
      _ => severidade.toUpperCase(),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 64,
            color: AppColors.statusRecuperacao.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum alerta nesta categoria',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severidade) {
    return switch (severidade) {
      'alto' => AppColors.error,
      'medio' => AppColors.warning,
      'baixo' => AppColors.info,
      _ => AppColors.textTertiary,
    };
  }

  IconData _getAlertIcon(String tipo) {
    return switch (tipo) {
      'queimada' => Icons.local_fire_department_rounded,
      'seca' => Icons.water_drop_outlined,
      'desmatamento' => Icons.forest_rounded,
      'atualizacao' => Icons.update_rounded,
      _ => Icons.warning_amber_rounded,
    };
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

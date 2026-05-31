import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../data/models/alerta.dart';
import '../alerts_provider.dart';

/// Tela global de alertas de ameaça do usuário logado.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertasAsync = ref.watch(todosAlertasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Ameaça'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: alertasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (alertas) {
          if (alertas.isEmpty) return _buildEmpty(context);
          return _buildList(context, alertas);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Alerta> alertas) {
    final naoLidos = alertas.where((a) => !a.lido).length;

    return Column(
      children: [
        if (naoLidos > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.error.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$naoLidos alerta(s) não lido(s)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            itemCount: alertas.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTheme.spacingSm),
            itemBuilder: (_, i) => _buildAlertaCard(context, alertas[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertaCard(BuildContext context, Alerta alerta) {
    final cor = _corSeveridade(alerta.severidade);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SaraCard(
      border: Border(left: BorderSide(color: cor, width: 3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(_iconeTipo(alerta.tipo), color: cor, size: 22),
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
                        alerta.tipo.displayName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (!alerta.lido)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${alerta.fonte.displayName} • ${_formatDate(alerta.detectadoEm)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                ),
                if (alerta.distanciaMetros != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Distância: ${_formatDistancia(alerta.distanciaMetros!)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    alerta.severidade.displayName.toUpperCase(),
                    style: TextStyle(
                      color: cor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined,
              size: 64,
              color: AppColors.statusRecuperacao.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Nenhum alerta ativo',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas áreas estão sem ameaças detectadas',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Color _corSeveridade(AlertaSeveridade s) => switch (s) {
        AlertaSeveridade.critica => AppColors.error,
        AlertaSeveridade.alta => AppColors.statusCritica,
        AlertaSeveridade.media => AppColors.warning,
        AlertaSeveridade.baixa => AppColors.statusAtencao,
      };

  IconData _iconeTipo(AlertaTipo t) => switch (t) {
        AlertaTipo.fogo => Icons.local_fire_department_rounded,
        AlertaTipo.desmatamento => Icons.forest_outlined,
        AlertaTipo.seca => Icons.water_drop_outlined,
      };

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatDistancia(double m) =>
      m >= 1000 ? '${(m / 1000).toStringAsFixed(1)} km' : '${m.toStringAsFixed(0)} m';
}

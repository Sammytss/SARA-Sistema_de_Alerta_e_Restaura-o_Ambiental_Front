import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../data/models/alerta.dart';
import '../../areas/areas_provider.dart';
import '../alerts_provider.dart';

/// Tela de alertas de uma área específica: mapa com focos + lista.
class AreaAlertsScreen extends ConsumerWidget {
  final String areaId;

  const AreaAlertsScreen({super.key, required this.areaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areaAsync = ref.watch(areaDetalheProvider(areaId));
    final alertasAsync = ref.watch(alertasParaAreaProvider(areaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas da Área'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: areaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (area) {
          if (area == null) {
            return const Center(child: Text('Área não encontrada'));
          }

          return alertasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (alertas) => Column(
              children: [
                // ── Mapa (40% da tela) ─────────────────────
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.40,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: area.coordenadaReferencia,
                      initialZoom: _zoomParaAlertas(alertas, area.raioMetros),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'br.gov.tocantins.sara_app',
                      ),

                      // Círculo da área (se demarcada)
                      if (area.raioMetros != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: area.coordenadaReferencia,
                              radius: area.raioMetros!,
                              useRadiusInMeter: true,
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderColor: AppColors.primary,
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),

                      // Focos de alerta
                      if (alertas.isNotEmpty)
                        CircleLayer(
                          circles: alertas
                              .map(
                                (a) => CircleMarker(
                                  point: a.posicao,
                                  radius: 200,
                                  useRadiusInMeter: true,
                                  color: _corSeveridade(a.severidade)
                                      .withValues(alpha: 0.25),
                                  borderColor: _corSeveridade(a.severidade),
                                  borderStrokeWidth: 1.5,
                                ),
                              )
                              .toList(),
                        ),

                      // Marcadores: área + focos
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: area.coordenadaReferencia,
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.primary,
                              size: 36,
                            ),
                          ),
                          ...alertas.map(
                            (a) => Marker(
                              point: a.posicao,
                              width: 32,
                              height: 32,
                              child: Icon(
                                _iconeTipo(a.tipo),
                                color: _corSeveridade(a.severidade),
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Lista de alertas ───────────────────────
                Expanded(
                  child: alertas.isEmpty
                      ? _buildEmpty(context)
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          itemCount: alertas.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppTheme.spacingSm),
                          itemBuilder: (_, i) =>
                              _buildCard(context, alertas[i]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, Alerta alerta) {
    final cor = _corSeveridade(alerta.severidade);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SaraCard(
      border: Border(left: BorderSide(color: cor, width: 3)),
      child: Row(
        children: [
          Icon(_iconeTipo(alerta.tipo), color: cor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.tipo.displayName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  '${alerta.fonte.displayName} • ${_formatDate(alerta.detectadoEm)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                ),
                if (alerta.distanciaMetros != null)
                  Text(
                    'A ${_formatDistancia(alerta.distanciaMetros!)} da área',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined,
              size: 56,
              color: AppColors.statusRecuperacao.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(
            'Nenhum alerta nesta área',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  double _zoomParaAlertas(List<Alerta> alertas, double? raioMetros) {
    if (alertas.isEmpty) {
      if (raioMetros == null) return 14.0;
      if (raioMetros < 500) return 15.0;
      if (raioMetros < 1000) return 14.0;
      return 13.0;
    }
    return 12.0;
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

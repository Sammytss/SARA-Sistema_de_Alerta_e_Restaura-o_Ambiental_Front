import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/widgets/sara_loading.dart';
import '../../../data/models/alerta.dart';
import '../../../data/models/area_monitorada.dart';
import '../../../features/alerts/alerts_provider.dart';
import '../../../features/areas/areas_provider.dart';

/// Mapa consolidado para o gestor: todas as áreas + focos de alerta.
///
/// Toque direto no mapa abre o detalhe da área.
/// Áreas com polígono são renderizadas como polígonos; áreas legadas como círculos.
class ManagerMapScreen extends ConsumerWidget {
  const ManagerMapScreen({super.key});

  static const _centroTO = LatLng(-10.17, -48.33);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasDoUsuarioProvider);
    final alertasAsync = ref.watch(todosAlertasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Consolidado'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar',
            onPressed: () {
              ref.invalidate(areasDoUsuarioProvider);
              ref.invalidate(todosAlertasProvider);
            },
          ),
        ],
      ),
      body: areasAsync.when(
        loading: () => const SaraLoading(message: 'Carregando mapa...'),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (areas) {
          final alertas = alertasAsync.valueOrNull ?? [];

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _centroTO,
                  initialZoom: 7.0,
                  maxZoom: 18,
                  minZoom: 5,
                  onTap: (_, latlng) => _onMapTap(context, latlng, areas),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'br.gov.tocantins.sara_app',
                  ),

                  // Polígonos das áreas demarcadas com polígono
                  PolygonLayer(
                    polygons: areas
                        .where((a) => a.temPoligono)
                        .map(
                          (a) => Polygon(
                            points: a.poligono!,
                            color: _corStatus(a.status)
                                .withValues(alpha: 0.15),
                            borderColor: _corStatus(a.status),
                            borderStrokeWidth: 2,
                          ),
                        )
                        .toList(),
                  ),

                  // Círculos legados (áreas com raio mas sem polígono)
                  CircleLayer(
                    circles: areas
                        .where((a) => a.raioMetros != null && !a.temPoligono)
                        .map(
                          (a) => CircleMarker(
                            point: a.coordenadaReferencia,
                            radius: a.raioMetros!,
                            useRadiusInMeter: true,
                            color: _corStatus(a.status)
                                .withValues(alpha: 0.15),
                            borderColor: _corStatus(a.status),
                            borderStrokeWidth: 2,
                          ),
                        )
                        .toList(),
                  ),

                  // Focos de alerta
                  if (alertas.isNotEmpty)
                    CircleLayer(
                      circles: alertas
                          .map(
                            (a) => CircleMarker(
                              point: a.posicao,
                              radius: 300,
                              useRadiusInMeter: true,
                              color: _corSeveridade(a.severidade)
                                  .withValues(alpha: 0.20),
                              borderColor: _corSeveridade(a.severidade),
                              borderStrokeWidth: 1.5,
                            ),
                          )
                          .toList(),
                    ),

                  // Marcadores de área — tap também abre o detalhe
                  MarkerLayer(
                    markers: areas
                        .map(
                          (a) => Marker(
                            point: a.centroide,
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => context.push('/area/${a.id}'),
                              child: _AreaMarker(area: a),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  // Marcadores de alertas
                  if (alertas.isNotEmpty)
                    MarkerLayer(
                      markers: alertas
                          .map(
                            (a) => Marker(
                              point: a.posicao,
                              width: 28,
                              height: 28,
                              child: Icon(
                                _iconeTipo(a.tipo),
                                color: _corSeveridade(a.severidade),
                                size: 24,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),

              // Legenda
              Positioned(
                bottom: AppTheme.spacingMd,
                left: AppTheme.spacingMd,
                child: _buildLegenda(context, areas, alertas),
              ),

              // Dica de interação
              Positioned(
                top: AppTheme.spacingSm,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusFull),
                    ),
                    child: const Text(
                      'Toque em uma área para ver detalhes',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Hit-test no toque: primeiro polígono que contém o ponto, senão círculo.
  void _onMapTap(
      BuildContext context, LatLng point, List<AreaMonitorada> areas) {
    for (final area in areas) {
      if (area.temPoligono &&
          GeoUtils.pointInPolygon(point, area.poligono!)) {
        context.push('/area/${area.id}');
        return;
      }
    }
    for (final area in areas) {
      if (area.raioMetros != null &&
          GeoUtils.pointInCircle(
              point, area.coordenadaReferencia, area.raioMetros!)) {
        context.push('/area/${area.id}');
        return;
      }
    }
  }

  Widget _buildLegenda(
    BuildContext context,
    List<AreaMonitorada> areas,
    List<Alerta> alertas,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : Colors.white)
            .withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legenda',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _legendaItem(context, AppColors.statusRecuperacao, 'Regular'),
          _legendaItem(context, AppColors.statusAtencao, 'Em atenção'),
          _legendaItem(context, AppColors.statusCritica, 'Crítica'),
          if (alertas.isNotEmpty) ...[
            const Divider(height: 10),
            _legendaItem(context, AppColors.error, 'Alerta crítico',
                icon: Icons.local_fire_department_rounded),
          ],
          const SizedBox(height: 4),
          Text(
            '${areas.length} áreas • ${alertas.length} alertas',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _legendaItem(BuildContext context, Color color, String label,
      {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.circle, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _corStatus(AreaStatus s) => switch (s) {
        AreaStatus.regular => AppColors.statusRecuperacao,
        AreaStatus.atencao => AppColors.statusAtencao,
        AreaStatus.critica => AppColors.statusCritica,
      };

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
}

/// Marcador de área no mapa — ícone colorido por status.
class _AreaMarker extends StatelessWidget {
  final AreaMonitorada area;
  const _AreaMarker({required this.area});

  @override
  Widget build(BuildContext context) {
    final color = switch (area.status) {
      AreaStatus.regular => AppColors.statusRecuperacao,
      AreaStatus.atencao => AppColors.statusAtencao,
      AreaStatus.critica => AppColors.statusCritica,
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        area.estaDemarcada
            ? Icons.location_on_rounded
            : Icons.location_on_outlined,
        color: color,
        size: 22,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/widgets/sara_loading.dart';
import '../areas_provider.dart';

/// Demarcação de área por toque no mapa — cada toque adiciona um vértice.
/// Polígono fechado automaticamente com ≥ 3 vértices.
/// Mantém compatibilidade com o círculo legado (raioMetros).
class DemarcateAreaScreen extends ConsumerStatefulWidget {
  final String areaId;

  const DemarcateAreaScreen({super.key, required this.areaId});

  @override
  ConsumerState<DemarcateAreaScreen> createState() =>
      _DemarcateAreaScreenState();
}

class _DemarcateAreaScreenState extends ConsumerState<DemarcateAreaScreen> {
  final _mapController = MapController();

  final List<LatLng> _vertices = [];
  bool _isLocating = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final areaAsync = ref.watch(areaDetalheProvider(widget.areaId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demarcar Área'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_vertices.length >= 2)
            TextButton.icon(
              onPressed: _desfazerUltimo,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Desfazer'),
            ),
          if (_vertices.isNotEmpty)
            TextButton(
              onPressed: _limpar,
              child: const Text('Limpar'),
            ),
        ],
      ),
      body: areaAsync.when(
        loading: () => const SaraLoading(message: 'Carregando área...'),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (area) {
          if (area == null) {
            return const Center(child: Text('Área não encontrada'));
          }
          final center = _vertices.isNotEmpty
              ? GeoUtils.polygonCentroid(_vertices)
              : area.centroide;

          return Column(
            children: [
              // ── Mapa interativo ──────────────────────────
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14.0,
                    onTap: (_, latlng) => _addVertex(latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'br.gov.tocantins.sara_app',
                    ),

                    // Círculo legado (cinza), se área tinha raio e usuário
                    // ainda não iniciou o polígono
                    if (area.raioMetros != null && _vertices.isEmpty)
                      CircleLayer(circles: [
                        CircleMarker(
                          point: area.coordenadaReferencia,
                          radius: area.raioMetros!,
                          useRadiusInMeter: true,
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderColor: Colors.grey,
                          borderStrokeWidth: 1.5,
                        ),
                      ]),

                    // Polígono existente da área (azul claro), se nenhum
                    // vértice novo foi adicionado ainda
                    if (area.temPoligono && _vertices.isEmpty)
                      PolygonLayer(polygons: [
                        Polygon(
                          points: area.poligono!,
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderColor: AppColors.primary,
                          borderStrokeWidth: 2,
                        ),
                      ]),

                    // Preview do novo polígono em construção
                    if (_vertices.length >= 3)
                      PolygonLayer(polygons: [
                        Polygon(
                          points: _vertices,
                          color: AppColors.accent.withValues(alpha: 0.18),
                          borderColor: AppColors.accent,
                          borderStrokeWidth: 2.5,
                        ),
                      ]),

                    // Linhas entre vértices (quando < 3, mostra linha aberta)
                    if (_vertices.length >= 2)
                      PolylineLayer(polylines: [
                        Polyline(
                          points: _vertices.length < 3
                              ? _vertices
                              : [..._vertices, _vertices.first],
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ]),

                    // Marcadores numerados nos vértices
                    MarkerLayer(
                      markers: [
                        for (int i = 0; i < _vertices.length; i++)
                          Marker(
                            point: _vertices[i],
                            width: 32,
                            height: 32,
                            child: GestureDetector(
                              onTap: () => _removeVertex(i),
                              child: _VertexMarker(
                                index: i + 1,
                                isFirst: i == 0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Painel inferior ──────────────────────────
              _buildPanel(context),
            ],
          );
        },
      ),
      floatingActionButton: _vertices.length >= 3
          ? FloatingActionButton.extended(
              onPressed: _isSaving ? null : _salvar,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'Salvando...' : 'Salvar polígono'),
            )
          : null,
    );
  }

  Widget _buildPanel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final areaHa = _vertices.length >= 3
        ? GeoUtils.polygonAreaHectares(_vertices)
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingMd,
        AppTheme.spacingXl,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Instrução / status ─────────────────────────
          Row(
            children: [
              Icon(
                _vertices.length >= 3
                    ? Icons.check_circle_outline_rounded
                    : Icons.touch_app_rounded,
                size: 18,
                color: _vertices.length >= 3
                    ? AppColors.statusRecuperacao
                    : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _vertices.isEmpty
                      ? 'Toque no mapa para adicionar os cantos da área'
                      : _vertices.length == 1
                          ? '1 ponto — adicione mais 2 para fechar o polígono'
                          : _vertices.length == 2
                              ? '2 pontos — adicione mais 1 para fechar'
                              : '${_vertices.length} pontos — polígono fechado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _vertices.length >= 3
                            ? AppColors.statusRecuperacao
                            : AppColors.textSecondary,
                      ),
                ),
              ),
              if (areaHa != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    '${areaHa.toStringAsFixed(2)} ha',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // ── Botão GPS ──────────────────────────────────
          OutlinedButton.icon(
            onPressed: _isLocating ? null : _centralizarGps,
            icon: _isLocating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _isLocating
                  ? 'Obtendo localização...'
                  : 'Centralizar no GPS atual',
            ),
          ),

          if (_vertices.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Toque em um marcador numerado para remover aquele vértice.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _addVertex(LatLng point) {
    setState(() => _vertices.add(point));
  }

  void _removeVertex(int index) {
    setState(() => _vertices.removeAt(index));
  }

  void _desfazerUltimo() {
    if (_vertices.isEmpty) return;
    setState(() => _vertices.removeLast());
  }

  void _limpar() {
    setState(() => _vertices.clear());
  }

  Future<void> _centralizarGps() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    } on LocationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _salvar() async {
    if (_vertices.length < 3) return;
    setState(() => _isSaving = true);

    try {
      final db = ref.read(appDatabaseProvider);
      await db.updateAreaPoligono(widget.areaId, _vertices);

      ref.invalidate(areaDetalheProvider(widget.areaId));
      ref.invalidate(areasDoUsuarioProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Polígono salvo: ${_vertices.length} vértices, '
              '${GeoUtils.polygonAreaHectares(_vertices).toStringAsFixed(2)} ha',
            ),
            backgroundColor: AppColors.statusRecuperacao,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

/// Marcador numerado de vértice do polígono.
class _VertexMarker extends StatelessWidget {
  final int index;
  final bool isFirst;

  const _VertexMarker({required this.index, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isFirst ? AppColors.primary : AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

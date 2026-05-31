import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../core/widgets/sara_loading.dart';
import '../../../data/models/area_monitorada.dart';
import '../../../data/models/satellite_frame.dart';
import '../../../features/areas/areas_provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/access_control/user_role.dart';
import '../satellite_provider.dart';

class SatelliteTimelineScreen extends ConsumerStatefulWidget {
  final String areaId;
  const SatelliteTimelineScreen({super.key, required this.areaId});

  @override
  ConsumerState<SatelliteTimelineScreen> createState() =>
      _SatelliteTimelineScreenState();
}

class _SatelliteTimelineScreenState
    extends ConsumerState<SatelliteTimelineScreen> {
  bool _expandido = true;

  @override
  Widget build(BuildContext context) {
    final areaAsync = ref.watch(areaDetalheProvider(widget.areaId));
    final timelineAsync = ref.watch(satelliteTimelineProvider(widget.areaId));
    final role = ref.watch(authProvider).currentRole;
    final podeRegistrar =
        role == UserRole.tecnico || role == UserRole.produtor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        title: areaAsync.when(
          data: (area) => Text(area?.nome ?? 'Monitoramento'),
          loading: () => const Text('Monitoramento'),
          error: (_, _) => const Text('Monitoramento'),
        ),
        centerTitle: false,
      ),
      body: areaAsync.when(
        loading: () => const SaraLoading(message: 'Carregando área...'),
        error: (e, _) => _buildError(context, e),
        data: (area) => timelineAsync.when(
          loading: () => const SaraLoading(message: 'Buscando imagens de satélite...'),
          error: (e, _) => _buildError(context, e),
          data: (timeline) => _buildBody(context, timeline, area),
        ),
      ),
      bottomNavigationBar: podeRegistrar ? _buildBottomBar(context) : null,
    );
  }

  Widget _buildBody(BuildContext context, SatelliteTimeline timeline, AreaMonitorada? area) {
    final temTilesReais = timeline.frames.any((f) => f.temTiles);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Banner de fonte de dados
              if (temTilesReais) _buildFonteBanner(context, 'Sentinel-2 via Microsoft Planetary Computer')
              else _buildFonteBanner(context, 'MapBiomas — dados simulados'),
              const SizedBox(height: AppTheme.spacingMd),
              _buildMonitoramentoCard(context, timeline, area),
              if (!temTilesReais) ...[
                const SizedBox(height: AppTheme.spacingMd),
                _buildLegendaCard(context),
              ],
              const SizedBox(height: AppTheme.spacingXl),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildFonteBanner(BuildContext context, String fonte) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : AppColors.accentSurface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.satellite_alt_rounded, size: 14, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              fonte,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card expansível "Monitoramento Temporal" ────────────────────

  Widget _buildMonitoramentoCard(
      BuildContext context, SatelliteTimeline timeline, AreaMonitorada? area) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SaraCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header clicável
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusMd),
              bottom: Radius.circular(0),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(Icons.satellite_alt_rounded,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monitoramento Temporal',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          'MapBiomas · ${timeline.frames.length} anos',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expandido
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          // Divider + conteúdo
          if (_expandido) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.darkDivider : AppColors.divider,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMd, AppTheme.spacingMd,
                  AppTheme.spacingMd, AppTheme.spacingMd),
              child: _buildTimeline(context, timeline.frames, area),
            ),
          ],
        ],
      ),
    );
  }

  // ── Linha do tempo ────────────────────────────────────────────

  Widget _buildTimeline(BuildContext context, List<SatelliteFrame> frames, AreaMonitorada? area) {
    return Column(
      children: frames.asMap().entries.map((e) {
        final index = e.key;
        final frame = e.value;
        final isLast = index == frames.length - 1;
        final anoLabel = index + 1;
        return _buildTimelineItem(context, frame, anoLabel, isLast, area);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(BuildContext context, SatelliteFrame frame,
      int anoLabel, bool isLast, AreaMonitorada? area) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha do tempo (esquerda) ─────────────────
          SizedBox(
            width: 28,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.primary.withValues(alpha: 0.2),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Conteúdo do frame (direita) ───────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem / visualização (satélite real ou placeholder)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: SizedBox(
                    height: 180,
                    child: frame.temTiles && area != null
                        ? _buildSatelliteMap(frame, area)
                        : _buildVegetacaoPlaceholder(frame),
                  ),
                ),
                const SizedBox(height: 8),

                // Ano + label de cobertura
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ano $anoLabel — ${_vegetacaoLabel(frame.percentualVegetacao)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${frame.ano}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (frame.classes != null)
                      _buildClassesCompact(context, frame.classes!),
                  ],
                ),

                SizedBox(height: isLast ? 0 : AppTheme.spacingMd),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mapa com tiles reais Sentinel-2 ──────────────────────────

  Widget _buildSatelliteMap(SatelliteFrame frame, AreaMonitorada area) {
    final center = area.centroide;
    final zoom = _zoomParaArea(area);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: frame.tileUrl!,
              userAgentPackageName: 'br.gov.tocantins.sara_app',
              tileProvider: NetworkTileProvider(),
            ),
            if (area.temPoligono)
              PolygonLayer(polygons: [
                Polygon(
                  points: area.poligono!,
                  color: Colors.transparent,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2.5,
                ),
              ])
            else if (area.raioMetros != null)
              CircleLayer(circles: [
                CircleMarker(
                  point: area.coordenadaReferencia,
                  radius: area.raioMetros!,
                  useRadiusInMeter: true,
                  color: Colors.transparent,
                  borderColor: Colors.white,
                  borderStrokeWidth: 2.5,
                ),
              ]),
          ],
        ),
        // Ano badge
        Positioned(
          top: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '${frame.ano}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        // Sentinel-2 badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.satellite_alt_rounded, size: 10, color: Colors.white),
                SizedBox(width: 3),
                Text(
                  'Sentinel-2',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double _zoomParaArea(AreaMonitorada area) {
    final raio = area.raioMetros;
    if (raio == null) return 13.5;
    if (raio < 300) return 15.0;
    if (raio < 800) return 14.0;
    if (raio < 2000) return 13.0;
    return 12.0;
  }

  // ── Placeholder visual (sem tiles reais) ─────────────────────

  Widget _buildVegetacaoPlaceholder(SatelliteFrame frame) {
    return Stack(
      children: [
        CustomPaint(
          size: const Size(double.infinity, 180),
          painter: _VegetacaoPainter(
            percentual: frame.percentualVegetacao ?? 0,
            seed: widget.areaId.hashCode ^ frame.ano,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: _buildVegetacaoBadge(frame.percentualVegetacao),
        ),
      ],
    );
  }

  Widget _buildVegetacaoBadge(double? pct) {
    if (pct == null) return const SizedBox.shrink();
    final color = _vegetacaoColor(pct);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${pct.toStringAsFixed(0)}% vegetal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesCompact(
      BuildContext context, Map<String, double> classes) {
    final top = classes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = top.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: shown.map((e) {
        final color = _classColor(e.key);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              '${e.key} ${e.value.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Legenda MapBiomas ─────────────────────────────────────────

  Widget _buildLegendaCard(BuildContext context) {
    return SaraCard(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                'Fonte: MapBiomas — Uso e Cobertura do Solo',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: const [
              _LegendaItem(cor: Color(0xFF1B6B3A), label: 'Floresta'),
              _LegendaItem(cor: Color(0xFFA8D5A2), label: 'Savana'),
              _LegendaItem(cor: Color(0xFFD4A06A), label: 'Pastagem'),
              _LegendaItem(cor: Color(0xFFE8C56A), label: 'Agricultura'),
              _LegendaItem(cor: Color(0xFFA0A0A0), label: 'Outros'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Botão inferior ────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd, AppTheme.spacingSm,
            AppTheme.spacingMd, AppTheme.spacingMd),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.push('/area/${widget.areaId}/capture'),
            icon: const Icon(Icons.camera_alt_rounded),
            label: const Text(
              'Anexar Foto de Campo',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              elevation: 2,
            ),
          ),
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────

  Widget _buildError(BuildContext context, Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('Erro ao carregar histórico',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('$e',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () =>
                ref.invalidate(satelliteTimelineProvider(widget.areaId)),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _vegetacaoLabel(double? pct) {
    if (pct == null) return '—';
    if (pct < 20) return 'Solo Exposto';
    if (pct < 35) return 'Vegetação Incipiente';
    if (pct < 55) return 'Regeneração em Progresso';
    if (pct < 75) return 'Cobertura Vegetal';
    return 'Cobertura Vegetal Densa';
  }

  Color _vegetacaoColor(double? pct) {
    if (pct == null) return AppColors.textTertiary;
    if (pct < 20) return AppColors.statusCritica;
    if (pct < 35) return AppColors.statusAtencao;
    if (pct < 55) return AppColors.secondary;
    if (pct < 75) return AppColors.statusRecuperacao;
    return AppColors.primaryDark;
  }

  Color _classColor(String classe) => switch (classe.toLowerCase()) {
        'floresta' => const Color(0xFF1B6B3A),
        'savana' || 'cerrado' => const Color(0xFF8BC34A),
        'pastagem' => const Color(0xFFD4A06A),
        'agricultura' || 'lavoura' => const Color(0xFFE8C56A),
        _ => const Color(0xFF9E9E9E),
      };
}

// ── Painter de visualização de vegetação ─────────────────────────────

class _VegetacaoPainter extends CustomPainter {
  final double percentual;
  final int seed;

  const _VegetacaoPainter({required this.percentual, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final pct = (percentual / 100).clamp(0.0, 1.0);

    // Fundo: gradiente solo exposto → tons de terra
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(const Color(0xFFD4B896), const Color(0xFF5A7A5A), pct * 0.5)!,
          Color.lerp(const Color(0xFFC4A070), const Color(0xFF3A5A3A), pct * 0.6)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Texturas de solo (manchas claras)
    final soilCount = ((1 - pct) * 12 + 3).round();
    for (int i = 0; i < soilCount; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final w = 18 + rnd.nextDouble() * 40;
      final h = 12 + rnd.nextDouble() * 24;
      final soilAlpha = 0.15 + rnd.nextDouble() * 0.25;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        Paint()
          ..color =
              Color(0xFFD4A06A).withValues(alpha: soilAlpha * (1 - pct * 0.7)),
      );
    }

    // Manchas de vegetação — quantidade proporcional ao percentual
    final patchCount = (pct * 22 + 4).round();
    for (int i = 0; i < patchCount; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final w = 20 + rnd.nextDouble() * (size.width * 0.22);
      final h = 14 + rnd.nextDouble() * (size.height * 0.18);

      // Varia entre tons de verde — floresta escura a verde mais claro
      final greenShade = Color.lerp(
        const Color(0xFF4CAF50),
        const Color(0xFF1B5E20),
        rnd.nextDouble(),
      )!;
      final alpha = (0.55 + rnd.nextDouble() * 0.45) * (0.5 + pct * 0.5);

      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        Paint()..color = greenShade.withValues(alpha: alpha),
      );
    }

    // Vinheta sutil nas bordas (profundidade)
    final vinhetaPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.22),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vinhetaPaint);
  }

  @override
  bool shouldRepaint(_VegetacaoPainter old) =>
      old.percentual != percentual || old.seed != seed;
}

// ── Widget auxiliar de legenda ────────────────────────────────────────

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final String label;
  const _LegendaItem({required this.cor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

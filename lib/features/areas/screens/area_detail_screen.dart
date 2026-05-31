import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../core/widgets/sara_loading.dart';
import '../../../data/models/alerta.dart';
import '../../../data/models/area_monitorada.dart';
import '../../../data/models/registro_evidencia.dart';
import '../../../features/access_control/user_role.dart';
import '../../../features/alerts/alerts_provider.dart';
import '../../../features/auth/auth_provider.dart';
import '../areas_provider.dart';

/// Tela de detalhe de uma área monitorada.
class AreaDetailScreen extends ConsumerWidget {
  final String areaId;

  const AreaDetailScreen({super.key, required this.areaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areaAsync = ref.watch(areaDetalheProvider(areaId));
    final evidenciasAsync = ref.watch(evidenciasDaAreaProvider(areaId));
    final role = ref.watch(authProvider).currentRole;
    final podeRegistrar = role == UserRole.tecnico || role == UserRole.produtor;
    final podeGerenciar = role == UserRole.tecnico || role == UserRole.gestor;

    return Scaffold(
      body: areaAsync.when(
        loading: () => const SaraLoading(message: 'Carregando área...'),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (area) {
          if (area == null) {
            return const Center(child: Text('Área não encontrada'));
          }
          return _buildContent(
              context, ref, area, evidenciasAsync, podeRegistrar, podeGerenciar);
        },
      ),
      floatingActionButton: podeRegistrar
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/area/$areaId/capture'),
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Registrar evidência'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    AreaMonitorada area,
    AsyncValue<List<RegistroEvidencia>> evidenciasAsync,
    bool podeRegistrar,
    bool podeGerenciar,
  ) {
    final statusColor = _statusColor(area.status);

    return CustomScrollView(
      slivers: [
        // ── AppBar com mini-mapa ──────────────────────────────
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (podeGerenciar)
              IconButton(
                onPressed: () => context.push('/area/$areaId/demarcate'),
                icon: Icon(
                  area.estaDemarcada
                      ? Icons.edit_location_alt_outlined
                      : Icons.add_location_alt_outlined,
                  color: Colors.white,
                ),
                tooltip: area.estaDemarcada
                    ? 'Editar demarcação'
                    : 'Demarcar área',
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildMiniMap(area),
          ),
        ),

        // ── Conteúdo ──────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status e nome
              _buildHeader(context, area, statusColor),
              const SizedBox(height: AppTheme.spacingMd),

              // Demarcação (se existir)
              if (area.estaDemarcada) ...[
                _buildDemarcacaoCard(context, area),
                const SizedBox(height: AppTheme.spacingMd),
              ],

              // Histórico de satélite
              _buildSatelliteCard(context, area.id),
              const SizedBox(height: AppTheme.spacingMd),

              // Progresso de regeneração
              _buildProgressCard(context, area, statusColor),
              const SizedBox(height: AppTheme.spacingMd),

              // Alertas da área
              _buildAlertasCard(context, ref, area),

              // Histórico de evidências
              _buildHistoricoSection(context, ref, evidenciasAsync, area.id),

              // Espaço para o FAB
              if (podeRegistrar) const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMap(AreaMonitorada area) {
    final center = area.centroide;
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: _zoomParaRaio(area.raioMetros),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'br.gov.tocantins.sara_app',
        ),
        // Polígono (preferencial)
        if (area.temPoligono)
          PolygonLayer(polygons: [
            Polygon(
              points: area.poligono!,
              color: AppColors.primary.withValues(alpha: 0.15),
              borderColor: AppColors.primary,
              borderStrokeWidth: 2,
            ),
          ]),
        // Círculo legado
        if (area.raioMetros != null && !area.temPoligono)
          CircleLayer(
            circles: [
              CircleMarker(
                point: area.coordenadaReferencia,
                radius: area.raioMetros!,
                useRadiusInMeter: true,
                color: AppColors.primary.withValues(alpha: 0.15),
                borderColor: AppColors.primary,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: area.coordenadaReferencia,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.location_pin,
                color: AppColors.primary,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDemarcacaoCard(BuildContext context, AreaMonitorada area) {
    final String descricao;
    if (area.temPoligono) {
      final ha = area.areaHectares?.toStringAsFixed(2) ?? '—';
      descricao =
          'Polígono demarcado • ${area.poligono!.length} vértices • $ha ha';
    } else {
      final raio = area.raioMetros!;
      final raioStr = raio >= 1000
          ? '${(raio / 1000).toStringAsFixed(2)} km'
          : '${raio.toStringAsFixed(0)} m';
      descricao = 'Área demarcada (círculo) • Raio: $raioStr';
    }

    return SaraCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(
            area.temPoligono
                ? Icons.pentagon_outlined
                : Icons.radar_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              descricao,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatelliteCard(BuildContext context, String areaId) {
    return SaraCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: () => context.push('/area/$areaId/satellite'),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.satellite_alt_rounded,
                  color: AppColors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Histórico de Satélite',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Evolução da cobertura vegetal nos últimos 5 anos',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertasCard(
      BuildContext context, WidgetRef ref, AreaMonitorada area) {
    final alertasAsync = ref.watch(alertasParaAreaProvider(area.id));
    return alertasAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (alertas) {
        if (alertas.isEmpty) return const SizedBox.shrink();
        final naoLidos = alertas.where((a) => !a.lido).length;
        final maiorSeveridade = alertas.first.severidade;
        final cor = _corSeveridade(maiorSeveridade);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
          child: SaraCard(
            border: Border(left: BorderSide(color: cor, width: 3)),
            child: InkWell(
              onTap: () => context.push('/area/${area.id}/alerts'),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: cor, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${alertas.length} alerta(s) detectado(s)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  fontWeight: FontWeight.w700, color: cor),
                        ),
                        Text(
                          naoLidos > 0
                              ? '$naoLidos não lido(s) • Toque para ver no mapa'
                              : 'Toque para ver no mapa',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, AreaMonitorada area, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                area.nome,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                area.status.displayName,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.location_on_outlined,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              area.municipio,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(width: 12),
            Icon(Icons.photo_camera_outlined,
                size: 14, color: AppColors.textTertiary),
            const SizedBox(width: 4),
            Text(
              '${area.totalEvidencias} evidências',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(
      BuildContext context, AreaMonitorada area, Color statusColor) {
    return SaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regeneração do PRAD',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${area.percentualRegeneracao.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              Text(
                area.ultimaEvidencia != null
                    ? 'Última evidência:\n${_formatDate(area.ultimaEvidencia!)}'
                    : 'Sem evidências\nregistradas',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: area.percentualRegeneracao / 100,
              minHeight: 10,
              backgroundColor: statusColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<RegistroEvidencia>> evidenciasAsync,
    String areaId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Histórico de Evidências',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        evidenciasAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Erro: $e'),
          data: (evidencias) {
            if (evidencias.isEmpty) {
              return SaraCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            size: 40,
                            color:
                                AppColors.textTertiary.withValues(alpha: 0.6)),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhuma evidência registrada',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Registre a primeira evidência desta área',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: evidencias
                  .map((e) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppTheme.spacingSm),
                        child: _buildEvidenciaCard(context, e),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEvidenciaCard(
      BuildContext context, RegistroEvidencia evidencia) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final syncColor = _syncColor(evidencia.statusSync);
    final primeiraFoto =
        evidencia.fotos.isNotEmpty ? evidencia.fotos.first : null;

    return SaraCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: SizedBox(
              width: 64,
              height: 64,
              child: primeiraFoto != null
                  ? Image.file(
                      File(primeiraFoto.pathLocal),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      evidencia.tipo.displayName,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: syncColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        _syncLabel(evidencia.statusSync),
                        style: TextStyle(
                          color: syncColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Por ${evidencia.autorNome}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                ),
                Text(
                  '${_formatDate(evidencia.dataRegistro)} • ${evidencia.fotos.length} foto(s)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.textTertiary,
                      ),
                ),
                if (evidencia.observacoes.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    evidencia.observacoes,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AppColors.textTertiary),
    );
  }

  double _zoomParaRaio(double? raioMetros) {
    if (raioMetros == null) return 14.0;
    if (raioMetros < 300) return 16.0;
    if (raioMetros < 600) return 15.0;
    if (raioMetros < 1200) return 14.0;
    if (raioMetros < 2500) return 13.0;
    return 12.0;
  }

  Color _statusColor(AreaStatus status) => switch (status) {
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

  Color _syncColor(StatusSincronizacao s) => switch (s) {
        StatusSincronizacao.enviado => AppColors.statusRecuperacao,
        StatusSincronizacao.pendente => AppColors.warning,
        StatusSincronizacao.enviando => AppColors.info,
        StatusSincronizacao.erro => AppColors.error,
      };

  String _syncLabel(StatusSincronizacao s) => switch (s) {
        StatusSincronizacao.enviado => 'ENVIADO',
        StatusSincronizacao.pendente => 'PENDENTE',
        StatusSincronizacao.enviando => 'ENVIANDO',
        StatusSincronizacao.erro => 'ERRO',
      };

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

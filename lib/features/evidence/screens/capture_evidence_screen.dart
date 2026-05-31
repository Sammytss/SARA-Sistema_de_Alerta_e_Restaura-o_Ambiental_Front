import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/geo_utils.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/area_monitorada.dart';
import '../../../data/models/registro_evidencia.dart';
import '../../../core/providers/app_providers.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/areas/areas_provider.dart';

/// Tela de captura de evidência — núcleo do MVP SARA.
///
/// Regras invioláveis:
/// - Ao menos 1 foto é obrigatória
/// - GPS é capturado automaticamente (não digitado)
/// - Evidência salva com statusSync = pendente (offline-first)
class CaptureEvidenceScreen extends ConsumerStatefulWidget {
  final String areaId;

  const CaptureEvidenceScreen({super.key, required this.areaId});

  @override
  ConsumerState<CaptureEvidenceScreen> createState() =>
      _CaptureEvidenceScreenState();
}

class _CaptureEvidenceScreenState extends ConsumerState<CaptureEvidenceScreen> {
  // ── Estado ───────────────────────────────────────────────────
  final _uuid = const Uuid();
  TipoEvidencia _tipo = TipoEvidencia.vistoria;
  final List<FotoEvidencia> _fotos = [];
  final _obsController = TextEditingController();
  Position? _gpsPosition;

  bool _obtendoGps = false;
  String? _gpsErro;
  bool _salvando = false;

  /// null = não verificado, true = dentro da área, false = fora dos limites
  bool? _dentroDoArea;

  @override
  void initState() {
    super.initState();
    _capturarGps();
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  // ── GPS ──────────────────────────────────────────────────────

  Future<void> _capturarGps() async {
    setState(() {
      _obtendoGps = true;
      _gpsErro = null;
      _dentroDoArea = null;
    });
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _gpsPosition = pos);
      // Valida localização contra os limites da área
      final area =
          ref.read(areaDetalheProvider(widget.areaId)).valueOrNull;
      if (area != null) _validarLocalizacao(area, pos);
    } on LocationException catch (e) {
      if (mounted) setState(() => _gpsErro = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _gpsErro = 'Erro ao obter localização. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _obtendoGps = false);
    }
  }

  void _validarLocalizacao(AreaMonitorada area, Position pos) {
    final point = LatLng(pos.latitude, pos.longitude);
    bool? dentro;
    if (area.temPoligono) {
      dentro = GeoUtils.pointInPolygon(point, area.poligono!);
    } else if (area.raioMetros != null) {
      dentro = GeoUtils.pointInCircle(
          point, area.coordenadaReferencia, area.raioMetros!);
    }
    if (mounted) setState(() => _dentroDoArea = dentro);
  }

  // ── Câmera ───────────────────────────────────────────────────

  Future<void> _adicionarFoto() async {
    if (_gpsPosition == null) {
      _mostrarAviso('Aguarde a captura do GPS antes de fotografar.');
      return;
    }
    final path = await CameraService.tirarFoto();
    if (path == null) return;
    setState(() {
      _fotos.add(FotoEvidencia(
        pathLocal: path,
        latitude: _gpsPosition!.latitude,
        longitude: _gpsPosition!.longitude,
        capturadaEm: DateTime.now(),
      ));
    });
  }

  void _removerFoto(int index) {
    setState(() => _fotos.removeAt(index));
  }

  // ── Salvar ───────────────────────────────────────────────────

  Future<void> _salvar() async {
    if (_fotos.isEmpty) {
      _mostrarAviso('Adicione ao menos uma foto antes de salvar.');
      return;
    }
    if (_gpsPosition == null) {
      _mostrarAviso('Aguarde a captura do GPS ou tente novamente.');
      return;
    }

    // Se o GPS indica que está fora dos limites, confirma com o usuário
    if (_dentroDoArea == false) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fora dos limites da área'),
          content: const Text(
            'Seu GPS indica que você está fora dos limites demarcados desta área.\n\n'
            'Deseja salvar mesmo assim? (pode ser imprecisão do GPS)',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Salvar mesmo assim'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    setState(() => _salvando = true);

    try {
      final usuario = ref.read(authProvider).usuario!;
      final evidencia = RegistroEvidencia(
        id: _uuid.v4(),
        areaId: widget.areaId,
        autorId: usuario.id,
        autorNome: usuario.nome,
        tipo: _tipo,
        fotos: List.unmodifiable(_fotos),
        latitude: _gpsPosition!.latitude,
        longitude: _gpsPosition!.longitude,
        precisaoGps: _gpsPosition!.accuracy,
        observacoes: _obsController.text.trim(),
        dataRegistro: DateTime.now(),
        statusSync: StatusSincronizacao.pendente,
      );

      final repo = ref.read(evidenciaRepositoryProvider);
      await repo.salvar(evidencia);

      // Invalida os providers para atualizar a UI
      ref.invalidate(evidenciasDaAreaProvider(widget.areaId));
      ref.invalidate(pendenciasCountProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Evidência salva! Será enviada quando houver conexão.'),
              ],
            ),
            backgroundColor: AppColors.statusRecuperacao,
            duration: Duration(seconds: 3),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        _mostrarAviso('Erro ao salvar: $e');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrarAviso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final podeGravar = _fotos.isNotEmpty && _gpsPosition != null && !_salvando;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Evidência'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: podeGravar ? _salvar : null,
            child: _salvando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Salvar',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: podeGravar ? AppColors.primary : AppColors.disabled,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── GPS ────────────────────────────────────────────
            _buildGpsCard(),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Tipo de evidência ──────────────────────────────
            _buildTipoSelector(),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Fotos ──────────────────────────────────────────
            _buildFotosSection(),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Observações ────────────────────────────────────
            _buildObservacoes(),
            const SizedBox(height: AppTheme.spacingMd),

            // ── Botão salvar (mobile) ──────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: podeGravar ? _salvar : null,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Salvar evidência'),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // ── Aviso de bloqueio ──────────────────────────────
            if (_fotos.isEmpty || _gpsPosition == null)
              _buildBloqueioAviso(),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsCard() {
    return SaraCard(
      border: Border.all(
        color: _gpsPosition != null
            ? AppColors.statusRecuperacao
            : _gpsErro != null
                ? AppColors.error
                : AppColors.border,
        width: 1.5,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_gpsPosition != null
                      ? AppColors.statusRecuperacao
                      : _gpsErro != null
                          ? AppColors.error
                          : AppColors.info)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(
              _gpsPosition != null
                  ? Icons.gps_fixed_rounded
                  : _gpsErro != null
                      ? Icons.gps_off_rounded
                      : Icons.gps_not_fixed_rounded,
              color: _gpsPosition != null
                  ? AppColors.statusRecuperacao
                  : _gpsErro != null
                      ? AppColors.error
                      : AppColors.info,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _obtendoGps
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Obtendo localização...',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const LinearProgressIndicator(),
                    ],
                  )
                : _gpsPosition != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'GPS capturado',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.statusRecuperacao,
                                    ),
                              ),
                              if (_dentroDoArea != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (_dentroDoArea!
                                            ? AppColors.statusRecuperacao
                                            : AppColors.warning)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _dentroDoArea!
                                            ? Icons.check_circle_rounded
                                            : Icons.warning_amber_rounded,
                                        size: 12,
                                        color: _dentroDoArea!
                                            ? AppColors.statusRecuperacao
                                            : AppColors.warning,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _dentroDoArea!
                                            ? 'Dentro da área'
                                            : 'Fora dos limites',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _dentroDoArea!
                                              ? AppColors.statusRecuperacao
                                              : AppColors.warning,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${_gpsPosition!.latitude.toStringAsFixed(6)}, '
                            '${_gpsPosition!.longitude.toStringAsFixed(6)}',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            'Precisão: ±${_gpsPosition!.accuracy.toStringAsFixed(0)}m',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Localização não disponível',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          if (_gpsErro != null)
                            Text(
                              _gpsErro!,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
          ),
          if (!_obtendoGps)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _capturarGps,
              tooltip: 'Tentar novamente',
            ),
        ],
      ),
    );
  }

  Widget _buildTipoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de evidência',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TipoEvidencia.values.map((tipo) {
            final selected = _tipo == tipo;
            return ChoiceChip(
              label: Text(tipo.displayName),
              selected: selected,
              onSelected: (_) => setState(() => _tipo = tipo),
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : null,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              backgroundColor: Colors.transparent,
            );
          }).toList(),
        ),
        if (_tipo != TipoEvidencia.vistoria) ...[
          const SizedBox(height: 6),
          Text(
            _tipo.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFotosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Fotos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            // Obrigatório
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _fotos.isEmpty
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.statusRecuperacao.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                _fotos.isEmpty ? 'OBRIGATÓRIO' : '${_fotos.length} foto(s)',
                style: TextStyle(
                  color: _fotos.isEmpty ? AppColors.error : AppColors.statusRecuperacao,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),

        // Grid de fotos + botão adicionar
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._fotos.asMap().entries.map((entry) {
              final idx = entry.key;
              final foto = entry.value;
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Image.file(
                        File(foto.pathLocal),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  // Botão remover
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removerFoto(idx),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }),

            // Botão adicionar foto
            GestureDetector(
              onTap: _adicionarFoto,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.primary.withValues(alpha: 0.7),
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fotografar',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildObservacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observações',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextField(
          controller: _obsController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Descreva o que foi observado em campo (opcional)...',
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSurfaceVariant
                : AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBloqueioAviso() {
    final faltaFoto = _fotos.isEmpty;
    final faltaGps = _gpsPosition == null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
              const SizedBox(width: 6),
              Text(
                'Para salvar, você precisa:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (faltaGps) _buildRequisito('GPS capturado', false),
          if (faltaFoto) _buildRequisito('Ao menos uma foto', false),
          if (!faltaGps) _buildRequisito('GPS capturado', true),
          if (!faltaFoto) _buildRequisito('Ao menos uma foto', true),
        ],
      ),
    );
  }

  Widget _buildRequisito(String label, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 14,
            color: ok ? AppColors.statusRecuperacao : AppColors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: ok ? AppColors.statusRecuperacao : AppColors.textSecondary,
              decoration: ok ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

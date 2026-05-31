import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/sara_card.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/public_models.dart';

/// Mapa público de áreas monitoradas do SARA APP.
/// Exibe localizações aproximadas por município — sem coordenadas exatas.
class PublicMapScreen extends StatefulWidget {
  const PublicMapScreen({super.key});

  @override
  State<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends State<PublicMapScreen> {
  PublicAreaSummary? _selectedMunicipio;

  // Coordenadas aproximadas por município (centroid do município).
  // Não expõe coordenadas exatas de propriedades — apenas localização administrativa.
  static const Map<String, LatLng> _municipioCoords = {
    'Palmas': LatLng(-10.184, -48.334),
    'Gurupi': LatLng(-11.731, -49.072),
    'Araguaína': LatLng(-7.190, -48.204),
    'Porto Nacional': LatLng(-10.704, -48.417),
  };

  @override
  Widget build(BuildContext context) {
    final municipios = MockData.municipios;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Áreas Monitoradas'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // ── Mapa ────────────────────────────────────────────
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-9.8, -48.5),
              initialZoom: 6.4,
              minZoom: 5.0,
              maxZoom: 10.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.gov.tocantins.sara_app',
              ),
              MarkerLayer(
                markers: municipios
                    .where((m) => _municipioCoords.containsKey(m.municipio))
                    .map((m) => _buildMarker(m))
                    .toList(),
              ),
            ],
          ),

          // ── Banner de aviso ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: AppColors.info.withValues(alpha: 0.92),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Localização aproximada por município. Coordenadas exatas são restritas a usuários autorizados.',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Card do município selecionado ────────────────────
          if (_selectedMunicipio != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildSelectedCard(context, _selectedMunicipio!),
            ),

          // ── Legenda ──────────────────────────────────────────
          if (_selectedMunicipio == null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildLegend(context),
            ),
        ],
      ),
    );
  }

  Marker _buildMarker(PublicAreaSummary m) {
    final coord = _municipioCoords[m.municipio]!;
    final hasAlerts = m.areasCriticas > 0;
    final color = hasAlerts ? AppColors.statusCritica : AppColors.statusRecuperacao;

    return Marker(
      point: coord,
      width: 130,
      height: 56,
      child: GestureDetector(
        onTap: () => setState(() => _selectedMunicipio = m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.municipio,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hasAlerts) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.warning_rounded, color: Colors.white, size: 12),
                  ],
                ],
              ),
            ),
            Icon(Icons.location_pin, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCard(BuildContext context, PublicAreaSummary m) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SaraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.municipio,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Região ${m.regiao} • ${m.quantidadeAreas} áreas monitoradas',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _selectedMunicipio = null),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(context, '${m.areasEmRecuperacao}', 'Em rec.', AppColors.statusRecuperacao),
              const SizedBox(width: 8),
              _buildStatChip(context, '${m.areasEmAtencao}', 'Atenção', AppColors.statusAtencao),
              const SizedBox(width: 8),
              _buildStatChip(context, '${m.areasCriticas}', 'Críticas', AppColors.statusCritica),
              const SizedBox(width: 8),
              _buildStatChip(
                context,
                '${m.percentualEvolucaoMedio.toStringAsFixed(0)}%',
                'Evolução',
                AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return SaraCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(context, 'Em recuperação', AppColors.statusRecuperacao),
          const SizedBox(width: 16),
          _buildLegendItem(context, 'Com alertas', AppColors.statusCritica),
          const SizedBox(width: 16),
          Text(
            'Toque em um município',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextSecondary
                : AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

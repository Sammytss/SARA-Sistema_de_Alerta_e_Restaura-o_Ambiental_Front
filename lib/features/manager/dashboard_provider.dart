import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';

// ── Modelos ────────────────────────────────────────────────────

class DashboardResumo {
  final int total;
  final int critica;
  final int atencao;
  final int regular;
  final int totalEvidencias;
  final double mediaRegeneracao;
  final DateTime geradoEm;

  const DashboardResumo({
    this.total = 0,
    this.critica = 0,
    this.atencao = 0,
    this.regular = 0,
    this.totalEvidencias = 0,
    this.mediaRegeneracao = 0,
    required this.geradoEm,
  });
}

class DashboardMunicipioItem {
  final String municipio;
  final int total;
  final int critica;
  final int atencao;
  final int regular;
  final double mediaRegeneracao;

  const DashboardMunicipioItem({
    required this.municipio,
    required this.total,
    required this.critica,
    required this.atencao,
    required this.regular,
    required this.mediaRegeneracao,
  });
}

// ── Providers ──────────────────────────────────────────────────

/// Totais agregados por status — alimenta o dashboard do gestor e os
/// indicadores públicos (apenas contagens, sem dado sensível individual).
final dashboardResumoProvider = FutureProvider<DashboardResumo>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final raw = await db.getDashboardResumo();
  return DashboardResumo(
    total: (raw['total'] as int?) ?? 0,
    critica: (raw['critica'] as int?) ?? 0,
    atencao: (raw['atencao'] as int?) ?? 0,
    regular: (raw['regular'] as int?) ?? 0,
    totalEvidencias: (raw['total_evidencias'] as int?) ?? 0,
    mediaRegeneracao: (raw['media_regeneracao'] as num?)?.toDouble() ?? 0.0,
    geradoEm: DateTime.now(),
  );
});

/// Breakdown por município — para gráfico de barras.
final dashboardMunicipiosProvider =
    FutureProvider<List<DashboardMunicipioItem>>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await db.getResumoByMunicipio();
  return rows
      .map(
        (r) => DashboardMunicipioItem(
          municipio: (r['municipio'] as String?) ?? '',
          total: (r['total'] as int?) ?? 0,
          critica: (r['critica'] as int?) ?? 0,
          atencao: (r['atencao'] as int?) ?? 0,
          regular: (r['regular'] as int?) ?? 0,
          mediaRegeneracao:
              (r['media_regeneracao'] as num?)?.toDouble() ?? 0.0,
        ),
      )
      .toList();
});

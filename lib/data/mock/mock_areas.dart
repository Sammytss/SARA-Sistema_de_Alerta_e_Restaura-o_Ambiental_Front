import 'package:latlong2/latlong.dart';
import '../models/area_monitorada.dart';

/// Áreas monitoradas mock para o MVP.
/// IDs de técnico/produtor alinham com os usuários em MockData.
class MockAreas {
  MockAreas._();

  static final List<AreaMonitorada> todas = [
    // ── Áreas atribuídas ao técnico (u002) ───────────────────
    AreaMonitorada(
      id: 'a001',
      nome: 'Fazenda Santa Helena — Talhão 1',
      municipio: 'Palmas',
      produtorId: 'u003',
      tecnicoAtribuidoId: 'u002',
      status: AreaStatus.atencao,
      percentualRegeneracao: 42.0,
      coordenadaReferencia: const LatLng(-10.310, -48.221),
      ultimaEvidencia: DateTime(2026, 5, 15),
      totalEvidencias: 3,
    ),
    AreaMonitorada(
      id: 'a002',
      nome: 'Fazenda Santa Helena — APP Rio',
      municipio: 'Palmas',
      produtorId: 'u003',
      tecnicoAtribuidoId: 'u002',
      status: AreaStatus.critica,
      percentualRegeneracao: 18.5,
      coordenadaReferencia: const LatLng(-10.318, -48.228),
      ultimaEvidencia: DateTime(2026, 4, 28),
      totalEvidencias: 1,
    ),
    AreaMonitorada(
      id: 'a003',
      nome: 'Propriedade Beira Rio — RL Norte',
      municipio: 'Porto Nacional',
      produtorId: 'u005',
      tecnicoAtribuidoId: 'u002',
      status: AreaStatus.regular,
      percentualRegeneracao: 78.3,
      coordenadaReferencia: const LatLng(-10.701, -48.415),
      raioMetros: 800,
      ultimaEvidencia: DateTime(2026, 5, 20),
      totalEvidencias: 7,
    ),
    AreaMonitorada(
      id: 'a004',
      nome: 'Sítio Cerrado Vivo — Talhão A',
      municipio: 'Gurupi',
      produtorId: 'u006',
      tecnicoAtribuidoId: 'u002',
      status: AreaStatus.atencao,
      percentualRegeneracao: 55.1,
      coordenadaReferencia: const LatLng(-11.729, -49.069),
      totalEvidencias: 0,
    ),

    // ── Áreas do produtor (u003) — suas propriedades ─────────
    // (a001 e a002 acima já pertencem ao produtor u003)

    // ── Área de outro produtor (u005) ────────────────────────
    // (a003 acima pertence ao produtor u005)

    // ── Mais áreas para o gestor ver (não atribuídas ao técnico) ─
    AreaMonitorada(
      id: 'a005',
      nome: 'Fazenda Boa Esperança — RL Sul',
      municipio: 'Araguaína',
      produtorId: 'u007',
      tecnicoAtribuidoId: 'u008',
      status: AreaStatus.regular,
      percentualRegeneracao: 91.0,
      coordenadaReferencia: const LatLng(-7.188, -48.201),
      raioMetros: 1200,
      ultimaEvidencia: DateTime(2026, 5, 25),
      totalEvidencias: 12,
    ),
    AreaMonitorada(
      id: 'a006',
      nome: 'Reflorestamento Municipal — Setor 3',
      municipio: 'Palmas',
      produtorId: null,
      tecnicoAtribuidoId: 'u008',
      status: AreaStatus.atencao,
      percentualRegeneracao: 34.7,
      coordenadaReferencia: const LatLng(-10.245, -48.300),
      ultimaEvidencia: DateTime(2026, 5, 10),
      totalEvidencias: 4,
    ),
  ];

  /// Áreas atribuídas a um técnico específico.
  static List<AreaMonitorada> paraTecnico(String tecnicoId) =>
      todas.where((a) => a.tecnicoAtribuidoId == tecnicoId).toList();

  /// Áreas de um produtor específico.
  static List<AreaMonitorada> paraProdutor(String produtorId) =>
      todas.where((a) => a.produtorId == produtorId).toList();
}

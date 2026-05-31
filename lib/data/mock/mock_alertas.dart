import '../models/alerta.dart';

/// Alertas mock para desenvolvimento (Fase 6).
/// Coordenadas geradas próximas às áreas reais do Tocantins.
class MockAlertas {
  MockAlertas._();

  static final List<Alerta> todos = [
    // ── Focos de fogo perto da área a001 (Palmas -10.310, -48.221) ───
    Alerta(
      id: 'al001',
      fonte: AlertaFonte.inpe,
      tipo: AlertaTipo.fogo,
      severidade: AlertaSeveridade.alta,
      latitude: -10.285,
      longitude: -48.195,
      distanciaMetros: 3200,
      areaId: 'a001',
      detectadoEm: DateTime(2026, 5, 29, 14, 30),
      lido: false,
    ),

    // ── Foco de fogo perto da área a002 (Palmas -10.318, -48.228) ────
    Alerta(
      id: 'al002',
      fonte: AlertaFonte.inpe,
      tipo: AlertaTipo.fogo,
      severidade: AlertaSeveridade.media,
      latitude: -10.352,
      longitude: -48.258,
      distanciaMetros: 4600,
      areaId: 'a002',
      detectadoEm: DateTime(2026, 5, 28, 9, 15),
      lido: false,
    ),

    // ── Foco crítico perto da área a004 (Gurupi -11.729, -49.069) ────
    Alerta(
      id: 'al003',
      fonte: AlertaFonte.cigma,
      tipo: AlertaTipo.fogo,
      severidade: AlertaSeveridade.critica,
      latitude: -11.752,
      longitude: -49.048,
      distanciaMetros: 2300,
      areaId: 'a004',
      detectadoEm: DateTime(2026, 5, 30, 6, 0),
      lido: false,
    ),

    // ── Desmatamento perto da área a005 (Araguaína -7.188, -48.201) ──
    Alerta(
      id: 'al004',
      fonte: AlertaFonte.mapbiomas,
      tipo: AlertaTipo.desmatamento,
      severidade: AlertaSeveridade.alta,
      latitude: -7.212,
      longitude: -48.238,
      distanciaMetros: 5100,
      areaId: 'a005',
      detectadoEm: DateTime(2026, 5, 27, 18, 0),
      lido: true,
    ),

    // ── Seca prolongada perto da área a003 (Porto Nacional -10.701, -48.415) ─
    Alerta(
      id: 'al005',
      fonte: AlertaFonte.inpe,
      tipo: AlertaTipo.seca,
      severidade: AlertaSeveridade.baixa,
      latitude: -10.720,
      longitude: -48.440,
      distanciaMetros: 2800,
      areaId: 'a003',
      detectadoEm: DateTime(2026, 5, 25, 12, 0),
      lido: true,
    ),
  ];
}

import '../../features/access_control/user_role.dart';
import '../models/usuario_local.dart';
import '../models/public_models.dart';

/// Dados mockados para o MVP do SARA APP.
/// Serão substituídos pela integração com o backend real.
class MockData {
  MockData._();

  // ══════════════════════════════════════════════════════════
  // USUÁRIOS MOCK
  // ══════════════════════════════════════════════════════════

  static final Map<String, UsuarioLocal> usuarios = {
    'gestor@sara.gov.br': UsuarioLocal(
      id: 'u001',
      nome: 'Carlos Gestor',
      email: 'gestor@sara.gov.br',
      perfil: UserRole.gestor,
      token: 'mock_jwt_gestor',
      telefone: '(63) 99999-0001',
      documento: '111.222.333-01',
      orgaoInstituicao: 'NATURATINS',
      dataCadastro: DateTime(2025, 1, 15),
      ultimoLogin: DateTime.now(),
    ),
    'tecnico@sara.gov.br': UsuarioLocal(
      id: 'u002',
      nome: 'Maria Técnica',
      email: 'tecnico@sara.gov.br',
      perfil: UserRole.tecnico,
      token: 'mock_jwt_tecnico',
      telefone: '(63) 99999-0002',
      documento: '111.222.333-02',
      orgaoInstituicao: 'NATURATINS',
      dataCadastro: DateTime(2025, 3, 10),
      ultimoLogin: DateTime.now(),
    ),
    'produtor@sara.gov.br': UsuarioLocal(
      id: 'u003',
      nome: 'João Produtor',
      email: 'produtor@sara.gov.br',
      perfil: UserRole.produtor,
      token: 'mock_jwt_produtor',
      telefone: '(63) 99999-0003',
      documento: '111.222.333-03',
      orgaoInstituicao: 'Fazenda Boa Vista',
      dataCadastro: DateTime(2025, 6, 20),
      ultimoLogin: DateTime.now(),
    ),
  };

  /// Senha padrão para todos os usuários mock.
  static const String defaultPassword = '123456';

  // ══════════════════════════════════════════════════════════
  // DADOS PÚBLICOS MOCK
  // ══════════════════════════════════════════════════════════

  static final PublicResumo resumoGeral = PublicResumo(
    totalAreasMonitoradas: 128,
    areasRegulares: 74,
    areasAtencao: 38,
    areasCriticas: 16,
    ultimaAtualizacao: DateTime(2026, 5, 30),
  );

  static final List<PublicAreaSummary> municipios = [
    PublicAreaSummary(
      municipio: 'Palmas',
      regiao: 'Central',
      quantidadeAreas: 42,
      areasEmRecuperacao: 25,
      areasEmAtencao: 12,
      areasCriticas: 5,
      percentualEvolucaoMedio: 67.5,
      ultimaAtualizacao: DateTime(2026, 5, 30),
    ),
    PublicAreaSummary(
      municipio: 'Gurupi',
      regiao: 'Sul',
      quantidadeAreas: 28,
      areasEmRecuperacao: 15,
      areasEmAtencao: 8,
      areasCriticas: 5,
      percentualEvolucaoMedio: 58.2,
      ultimaAtualizacao: DateTime(2026, 5, 28),
    ),
    PublicAreaSummary(
      municipio: 'Araguaína',
      regiao: 'Norte',
      quantidadeAreas: 35,
      areasEmRecuperacao: 20,
      areasEmAtencao: 10,
      areasCriticas: 5,
      percentualEvolucaoMedio: 62.1,
      ultimaAtualizacao: DateTime(2026, 5, 29),
    ),
    PublicAreaSummary(
      municipio: 'Porto Nacional',
      regiao: 'Central',
      quantidadeAreas: 23,
      areasEmRecuperacao: 14,
      areasEmAtencao: 8,
      areasCriticas: 1,
      percentualEvolucaoMedio: 72.8,
      ultimaAtualizacao: DateTime(2026, 5, 27),
    ),
  ];

  static final List<PublicAlert> alertas = [
    PublicAlert(
      id: 'a001',
      titulo: 'Risco de queimada — Região Sul',
      descricao:
          'Condições climáticas indicam alto risco de incêndio florestal na região sul do Tocantins. Umidade relativa abaixo de 20%.',
      tipo: 'queimada',
      regiao: 'Sul',
      municipio: 'Gurupi',
      dataPublicacao: DateTime(2026, 5, 29),
      severidade: 'alto',
    ),
    PublicAlert(
      id: 'a002',
      titulo: 'Seca prolongada — Região Norte',
      descricao:
          'Período de seca prolongada pode afetar áreas em recuperação. Recomenda-se irrigação suplementar onde aplicável.',
      tipo: 'seca',
      regiao: 'Norte',
      dataPublicacao: DateTime(2026, 5, 25),
      severidade: 'medio',
    ),
    PublicAlert(
      id: 'a003',
      titulo: 'Desmatamento detectado — Palmas',
      descricao:
          'Alerta de desmatamento detectado por satélite em área próxima à zona de recuperação no município de Palmas.',
      tipo: 'desmatamento',
      regiao: 'Central',
      municipio: 'Palmas',
      dataPublicacao: DateTime(2026, 5, 20),
      severidade: 'alto',
    ),
    PublicAlert(
      id: 'a004',
      titulo: 'Atualização de monitoramento — Porto Nacional',
      descricao:
          'Nova rodada de monitoramento concluída com sucesso. 14 áreas avaliadas com resultados positivos de regeneração.',
      tipo: 'atualizacao',
      regiao: 'Central',
      municipio: 'Porto Nacional',
      dataPublicacao: DateTime(2026, 5, 18),
      severidade: 'baixo',
    ),
  ];
}

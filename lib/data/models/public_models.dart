/// Modelo de resumo de área pública.
/// Conforme Seção 10 — Dados públicos (PublicAreaSummary).
/// Usado no modo público sem login.
class PublicAreaSummary {
  final String municipio;
  final String regiao;
  final int quantidadeAreas;
  final int areasEmRecuperacao;
  final int areasEmAtencao;
  final int areasCriticas;
  final double percentualEvolucaoMedio;
  final DateTime ultimaAtualizacao;

  const PublicAreaSummary({
    required this.municipio,
    required this.regiao,
    required this.quantidadeAreas,
    required this.areasEmRecuperacao,
    required this.areasEmAtencao,
    required this.areasCriticas,
    required this.percentualEvolucaoMedio,
    required this.ultimaAtualizacao,
  });

  /// Total de áreas regulares (em recuperação adequada).
  int get areasRegulares =>
      quantidadeAreas - areasEmRecuperacao - areasEmAtencao - areasCriticas;

  Map<String, dynamic> toMap() {
    return {
      'municipio': municipio,
      'regiao': regiao,
      'quantidadeAreas': quantidadeAreas,
      'areasEmRecuperacao': areasEmRecuperacao,
      'areasEmAtencao': areasEmAtencao,
      'areasCriticas': areasCriticas,
      'percentualEvolucaoMedio': percentualEvolucaoMedio,
      'ultimaAtualizacao': ultimaAtualizacao.toIso8601String(),
    };
  }

  factory PublicAreaSummary.fromMap(Map<String, dynamic> map) {
    return PublicAreaSummary(
      municipio: map['municipio'] as String,
      regiao: map['regiao'] as String,
      quantidadeAreas: map['quantidadeAreas'] as int,
      areasEmRecuperacao: map['areasEmRecuperacao'] as int,
      areasEmAtencao: map['areasEmAtencao'] as int,
      areasCriticas: map['areasCriticas'] as int,
      percentualEvolucaoMedio:
          (map['percentualEvolucaoMedio'] as num).toDouble(),
      ultimaAtualizacao: DateTime.parse(map['ultimaAtualizacao'] as String),
    );
  }
}

/// Resumo geral do sistema para o dashboard público.
/// Conforme Seção 11 — resposta de GET /public/resumo.
class PublicResumo {
  final int totalAreasMonitoradas;
  final int areasRegulares;
  final int areasAtencao;
  final int areasCriticas;
  final DateTime ultimaAtualizacao;

  const PublicResumo({
    required this.totalAreasMonitoradas,
    required this.areasRegulares,
    required this.areasAtencao,
    required this.areasCriticas,
    required this.ultimaAtualizacao,
  });

  int get areasEmRecuperacao =>
      totalAreasMonitoradas - areasRegulares - areasAtencao - areasCriticas;
}

/// Alerta público ambiental.
class PublicAlert {
  final String id;
  final String titulo;
  final String descricao;
  final String tipo; // queimada, risco_ambiental, seca, etc.
  final String regiao;
  final String? municipio;
  final DateTime dataPublicacao;
  final String severidade; // alto, medio, baixo

  const PublicAlert({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.tipo,
    required this.regiao,
    this.municipio,
    required this.dataPublicacao,
    required this.severidade,
  });
}

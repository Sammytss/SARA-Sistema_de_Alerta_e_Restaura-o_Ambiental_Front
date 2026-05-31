/// Registro de evidência de campo — núcleo do MVP SARA.
/// Capturado obrigatoriamente com foto + GPS no local.
class RegistroEvidencia {
  final String id;
  final String areaId;
  final String autorId;
  final String autorNome;
  final TipoEvidencia tipo;
  final List<FotoEvidencia> fotos; // sempre >= 1
  final double latitude;
  final double longitude;
  final double? precisaoGps; // metros
  final String observacoes;
  final DateTime dataRegistro;
  final StatusSincronizacao statusSync;

  const RegistroEvidencia({
    required this.id,
    required this.areaId,
    required this.autorId,
    required this.autorNome,
    required this.tipo,
    required this.fotos,
    required this.latitude,
    required this.longitude,
    this.precisaoGps,
    this.observacoes = '',
    required this.dataRegistro,
    this.statusSync = StatusSincronizacao.pendente,
  }) : assert(fotos.length > 0, 'Evidência deve ter ao menos uma foto');

  RegistroEvidencia copyWith({StatusSincronizacao? statusSync}) {
    return RegistroEvidencia(
      id: id,
      areaId: areaId,
      autorId: autorId,
      autorNome: autorNome,
      tipo: tipo,
      fotos: fotos,
      latitude: latitude,
      longitude: longitude,
      precisaoGps: precisaoGps,
      observacoes: observacoes,
      dataRegistro: dataRegistro,
      statusSync: statusSync ?? this.statusSync,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'areaId': areaId,
    'autorId': autorId,
    'autorNome': autorNome,
    'tipo': tipo.code,
    'fotos': fotos.map((f) => f.toJson()).toList(),
    'latitude': latitude,
    'longitude': longitude,
    'precisaoGps': precisaoGps,
    'observacoes': observacoes,
    'dataRegistro': dataRegistro.toIso8601String(),
    'statusSync': statusSync.code,
  };

  factory RegistroEvidencia.fromJson(Map<String, dynamic> j) => RegistroEvidencia(
    id: j['id'] as String,
    areaId: j['areaId'] as String,
    autorId: j['autorId'] as String,
    autorNome: j['autorNome'] as String,
    tipo: TipoEvidencia.fromCode(j['tipo'] as String),
    fotos: (j['fotos'] as List).map((e) => FotoEvidencia.fromJson(e as Map<String, dynamic>)).toList(),
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    precisaoGps: (j['precisaoGps'] as num?)?.toDouble(),
    observacoes: j['observacoes'] as String? ?? '',
    dataRegistro: DateTime.parse(j['dataRegistro'] as String),
    statusSync: StatusSyncExt.fromCode(j['statusSync'] as String),
  );
}

class FotoEvidencia {
  final String pathLocal;
  final double latitude;
  final double longitude;
  final DateTime capturadaEm;

  const FotoEvidencia({
    required this.pathLocal,
    required this.latitude,
    required this.longitude,
    required this.capturadaEm,
  });

  Map<String, dynamic> toJson() => {
    'pathLocal': pathLocal,
    'latitude': latitude,
    'longitude': longitude,
    'capturadaEm': capturadaEm.toIso8601String(),
  };

  factory FotoEvidencia.fromJson(Map<String, dynamic> j) => FotoEvidencia(
    pathLocal: j['pathLocal'] as String,
    latitude: (j['latitude'] as num).toDouble(),
    longitude: (j['longitude'] as num).toDouble(),
    capturadaEm: DateTime.parse(j['capturadaEm'] as String),
  );
}

enum TipoEvidencia {
  vistoria('VISTORIA', 'Vistoria técnica', 'Avaliação geral da área'),
  plantio('PLANTIO', 'Plantio', 'Registro de plantio de mudas'),
  regeneracao('REGENERACAO', 'Regeneração', 'Evidência de regeneração natural'),
  ocorrencia('OCORRENCIA', 'Ocorrência', 'Incidente ou evento anormal');

  final String code;
  final String displayName;
  final String description;
  const TipoEvidencia(this.code, this.displayName, this.description);

  static TipoEvidencia fromCode(String code) => TipoEvidencia.values.firstWhere(
    (e) => e.code == code,
    orElse: () => TipoEvidencia.vistoria,
  );
}

enum StatusSincronizacao {
  pendente('PENDENTE'),
  enviando('ENVIANDO'),
  enviado('ENVIADO'),
  erro('ERRO');

  final String code;
  const StatusSincronizacao(this.code);
}

extension StatusSyncExt on StatusSincronizacao {
  static StatusSincronizacao fromCode(String code) =>
      StatusSincronizacao.values.firstWhere(
        (s) => s.code == code,
        orElse: () => StatusSincronizacao.pendente,
      );
}

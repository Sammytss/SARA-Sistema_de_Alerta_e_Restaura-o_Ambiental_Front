import 'package:latlong2/latlong.dart';

enum AlertaFonte {
  inpe('INPE', 'INPE / BDQueimadas'),
  cigma('CIGMA', 'CIGMA-TO'),
  mapbiomas('MAPBIOMAS', 'MapBiomas Alerta');

  final String code;
  final String displayName;
  const AlertaFonte(this.code, this.displayName);

  static AlertaFonte fromCode(String code) => AlertaFonte.values.firstWhere(
        (f) => f.code == code.toUpperCase(),
        orElse: () => AlertaFonte.inpe,
      );
}

enum AlertaTipo {
  fogo('FOGO', 'Foco de fogo'),
  desmatamento('DESMATAMENTO', 'Desmatamento'),
  seca('SECA', 'Seca prolongada');

  final String code;
  final String displayName;
  const AlertaTipo(this.code, this.displayName);

  static AlertaTipo fromCode(String code) => AlertaTipo.values.firstWhere(
        (t) => t.code == code.toUpperCase(),
        orElse: () => AlertaTipo.fogo,
      );
}

enum AlertaSeveridade {
  baixa('BAIXA', 'Baixa'),
  media('MEDIA', 'Média'),
  alta('ALTA', 'Alta'),
  critica('CRITICA', 'Crítica');

  final String code;
  final String displayName;
  const AlertaSeveridade(this.code, this.displayName);

  static AlertaSeveridade fromCode(String code) =>
      AlertaSeveridade.values.firstWhere(
        (s) => s.code == code.toUpperCase(),
        orElse: () => AlertaSeveridade.media,
      );
}

/// Alerta de ameaça (fogo / desmatamento) gerado pelo backend
/// a partir do cruzamento de focos de satélite com as áreas monitoradas.
class Alerta {
  final String id;
  final AlertaFonte fonte;
  final AlertaTipo tipo;
  final AlertaSeveridade severidade;
  final double latitude;
  final double longitude;

  /// Distância do foco ao centro da área (calculada pelo backend).
  final double? distanciaMetros;

  /// Área afetada. Null = alerta geral sem área vinculada.
  final String? areaId;

  final DateTime detectadoEm;
  final bool lido;

  const Alerta({
    required this.id,
    required this.fonte,
    required this.tipo,
    required this.severidade,
    required this.latitude,
    required this.longitude,
    this.distanciaMetros,
    this.areaId,
    required this.detectadoEm,
    this.lido = false,
  });

  LatLng get posicao => LatLng(latitude, longitude);

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(
        id: json['id'] as String,
        fonte: AlertaFonte.fromCode(json['fonte'] as String),
        tipo: AlertaTipo.fromCode(json['tipo'] as String),
        severidade: AlertaSeveridade.fromCode(json['severidade'] as String),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        distanciaMetros: json['distanciaMetros'] != null
            ? (json['distanciaMetros'] as num).toDouble()
            : null,
        areaId: json['areaId'] as String?,
        detectadoEm: DateTime.parse(json['detectadoEm'] as String),
        lido: json['lido'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fonte': fonte.code,
        'tipo': tipo.code,
        'severidade': severidade.code,
        'latitude': latitude,
        'longitude': longitude,
        'distanciaMetros': distanciaMetros,
        'areaId': areaId,
        'detectadoEm': detectadoEm.toIso8601String(),
        'lido': lido,
      };

  Alerta copyWith({bool? lido}) => Alerta(
        id: id,
        fonte: fonte,
        tipo: tipo,
        severidade: severidade,
        latitude: latitude,
        longitude: longitude,
        distanciaMetros: distanciaMetros,
        areaId: areaId,
        detectadoEm: detectadoEm,
        lido: lido ?? this.lido,
      );
}

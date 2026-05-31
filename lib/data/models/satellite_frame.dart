/// Frame anual de imagem de satélite de uma área monitorada.
/// Fonte principal: MapBiomas (coleções anuais de uso/cobertura do solo).
class SatelliteFrame {
  final String id;
  final String areaId;
  final int ano;
  final SatelliteLayer camada;

  /// URL do PNG estático (mock) ou vazio quando se usa tileUrl.
  final String imagemUrl;

  /// Template XYZ de tiles Sentinel-2 (Planetary Computer) para flutter_map.
  /// Presente quando há imagem real. Ex: `.../tiles/{z}/{x}/{y}@1x?...`
  final String? tileUrl;
  final String? thumbnailUrl;

  /// Verdadeiro quando há tiles reais de satélite disponíveis.
  bool get temTiles => tileUrl != null && tileUrl!.contains('{z}');

  /// Percentual de vegetação nativa/florestal no polígono naquele ano (0–100).
  final double? percentualVegetacao;

  /// Histograma de classes MapBiomas: nome da classe → percentual da área.
  final Map<String, double>? classes;

  final String fonte;

  const SatelliteFrame({
    required this.id,
    required this.areaId,
    required this.ano,
    required this.camada,
    required this.imagemUrl,
    this.tileUrl,
    this.thumbnailUrl,
    this.percentualVegetacao,
    this.classes,
    this.fonte = 'MAPBIOMAS',
  });

  factory SatelliteFrame.fromJson(Map<String, dynamic> json) {
    return SatelliteFrame(
      id: json['id'] as String,
      areaId: json['areaId'] as String,
      ano: json['ano'] as int,
      camada: SatelliteLayer.values.firstWhere(
        (e) => e.code == (json['camada'] as String),
        orElse: () => SatelliteLayer.landCover,
      ),
      imagemUrl: json['imagemUrl'] as String? ?? '',
      tileUrl: json['tileUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      percentualVegetacao: (json['percentualVegetacao'] as num?)?.toDouble(),
      classes: (json['classes'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
      fonte: json['fonte'] as String? ?? 'MAPBIOMAS',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'areaId': areaId,
        'ano': ano,
        'camada': camada.code,
        'imagemUrl': imagemUrl,
        if (tileUrl != null) 'tileUrl': tileUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (percentualVegetacao != null)
          'percentualVegetacao': percentualVegetacao,
        if (classes != null) 'classes': classes,
        'fonte': fonte,
      };
}

enum SatelliteLayer {
  /// Classificação de uso/cobertura do solo — MapBiomas (principal).
  landCover('LAND_COVER'),

  /// Imagem true-color — Sentinel-2 (complemento futuro).
  trueColor('TRUE_COLOR'),

  /// Índice NDVI — Sentinel-2 (complemento futuro).
  ndvi('NDVI');

  final String code;
  const SatelliteLayer(this.code);

  String get displayName => switch (this) {
        SatelliteLayer.landCover => 'Uso do Solo',
        SatelliteLayer.trueColor => 'True Color',
        SatelliteLayer.ndvi => 'NDVI',
      };
}

/// Resposta do endpoint GET /areas/{id}/satellite-timeline.
class SatelliteTimeline {
  final List<SatelliteFrame> frames;

  /// GeoJSON geometry type present on the server-side for this area.
  final String geometria;

  const SatelliteTimeline({
    required this.frames,
    required this.geometria,
  });

  factory SatelliteTimeline.fromJson(Map<String, dynamic> json) {
    return SatelliteTimeline(
      frames: (json['frames'] as List<dynamic>)
          .map((f) => SatelliteFrame.fromJson(f as Map<String, dynamic>))
          .toList(),
      geometria: json['geometria'] as String? ?? 'point',
    );
  }
}

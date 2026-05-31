import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../core/utils/geo_utils.dart';

/// Área de PRAD monitorada pelo SARA APP.
class AreaMonitorada {
  final String id;
  final String nome;
  final String municipio;
  final String? produtorId;
  final String? tecnicoAtribuidoId;
  final AreaStatus status;
  final double percentualRegeneracao;
  final LatLng coordenadaReferencia;

  /// Vértices do polígono demarcado manualmente. Principal forma de demarcação.
  final List<LatLng>? poligono;

  /// Raio circular em metros. Legado — usado quando polígono não está disponível.
  final double? raioMetros;

  final DateTime? ultimaEvidencia;
  final int totalEvidencias;

  const AreaMonitorada({
    required this.id,
    required this.nome,
    required this.municipio,
    this.produtorId,
    this.tecnicoAtribuidoId,
    required this.status,
    required this.percentualRegeneracao,
    required this.coordenadaReferencia,
    this.poligono,
    this.raioMetros,
    this.ultimaEvidencia,
    this.totalEvidencias = 0,
  });

  bool get estaDemarcada =>
      (poligono != null && poligono!.length >= 3) || raioMetros != null;

  bool get temPoligono => poligono != null && poligono!.length >= 3;

  /// Área em hectares: usa polígono se disponível, senão calcula pelo raio.
  double? get areaHectares {
    if (temPoligono) return GeoUtils.polygonAreaHectares(poligono!);
    if (raioMetros != null) {
      return math.pi * raioMetros! * raioMetros! / 10000;
    }
    return null;
  }

  /// Centro da área: centroide do polígono ou coordenadaReferencia.
  LatLng get centroide {
    if (temPoligono) return GeoUtils.polygonCentroid(poligono!);
    return coordenadaReferencia;
  }

  AreaMonitorada copyWith({
    LatLng? coordenadaReferencia,
    List<LatLng>? poligono,
    double? raioMetros,
    DateTime? ultimaEvidencia,
    int? totalEvidencias,
    double? percentualRegeneracao,
    AreaStatus? status,
  }) {
    return AreaMonitorada(
      id: id,
      nome: nome,
      municipio: municipio,
      produtorId: produtorId,
      tecnicoAtribuidoId: tecnicoAtribuidoId,
      status: status ?? this.status,
      percentualRegeneracao: percentualRegeneracao ?? this.percentualRegeneracao,
      coordenadaReferencia: coordenadaReferencia ?? this.coordenadaReferencia,
      poligono: poligono ?? this.poligono,
      raioMetros: raioMetros ?? this.raioMetros,
      ultimaEvidencia: ultimaEvidencia ?? this.ultimaEvidencia,
      totalEvidencias: totalEvidencias ?? this.totalEvidencias,
    );
  }
}

enum AreaStatus {
  regular('REGULAR', 'Regular'),
  atencao('ATENCAO', 'Em atenção'),
  critica('CRITICA', 'Crítica');

  final String code;
  final String displayName;
  const AreaStatus(this.code, this.displayName);
}

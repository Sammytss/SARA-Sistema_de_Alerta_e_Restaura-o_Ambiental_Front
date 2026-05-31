import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Utilitários geográficos compartilhados (polígono, círculo, área, centroide).
class GeoUtils {
  GeoUtils._();

  static const double _metersPerDegree = 111320.0;
  static const double _earthRadiusM = 6371000.0;

  /// Ray-casting: retorna true se [point] está dentro de [polygon].
  static bool pointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) return false;
    bool inside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;
      if (((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  /// Retorna true se [point] está dentro do círculo definido por [center] e [radiusMeters].
  static bool pointInCircle(
      LatLng point, LatLng center, double radiusMeters) {
    return distanceMeters(point, center) <= radiusMeters;
  }

  /// Distância haversine entre dois pontos em metros.
  static double distanceMeters(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * _earthRadiusM * math.asin(math.sqrt(h));
  }

  /// Área do polígono em hectares via fórmula de shoelace com projeção equiretangular.
  static double polygonAreaHectares(List<LatLng> polygon) {
    if (polygon.length < 3) return 0;
    final lat0 =
        polygon.map((p) => p.latitude).reduce((a, b) => a + b) / polygon.length;
    final cosLat = math.cos(lat0 * math.pi / 180);

    double area = 0;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].longitude * _metersPerDegree * cosLat;
      final yi = polygon[i].latitude * _metersPerDegree;
      final xj = polygon[j].longitude * _metersPerDegree * cosLat;
      final yj = polygon[j].latitude * _metersPerDegree;
      area += (xj + xi) * (yj - yi);
      j = i;
    }
    return (area.abs() / 2) / 10000;
  }

  /// Centroide como média simples dos vértices.
  static LatLng polygonCentroid(List<LatLng> polygon) {
    if (polygon.isEmpty) return const LatLng(0, 0);
    final lat =
        polygon.map((p) => p.latitude).reduce((a, b) => a + b) / polygon.length;
    final lng =
        polygon.map((p) => p.longitude).reduce((a, b) => a + b) / polygon.length;
    return LatLng(lat, lng);
  }
}

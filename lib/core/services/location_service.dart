import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Serviço de geolocalização para captura de GPS em campo.
class LocationService {
  /// Solicita permissões e retorna a posição atual.
  /// Lança [LocationException] em caso de falha.
  static Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'GPS desativado. Ative a localização do dispositivo.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Permissão de localização negada. Ative nas configurações.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Permissão de localização bloqueada permanentemente. Acesse Configurações > Aplicativos > SARA.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 30),
      ),
    );
  }

  /// Verifica se a permissão de localização já foi concedida.
  static Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Abre as configurações do app para o usuário conceder a permissão.
  static Future<void> openSettings() => Geolocator.openAppSettings();

  // ── Geodésia ────────────────────────────────────────────────

  /// Distância em metros entre dois pontos (fórmula de Haversine).
  static double distanciaMetros(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final c = sinLat * sinLat +
        math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * sinLng * sinLng;
    return R * 2 * math.atan2(math.sqrt(c), math.sqrt(1 - c));
  }

  /// True se [ponto] está dentro do [raioMetros] centrado em [centro].
  static bool estaDentroDoRaio(LatLng centro, double raioMetros, LatLng ponto) =>
      distanciaMetros(centro, ponto) <= raioMetros;

  static double _rad(double deg) => deg * math.pi / 180;
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}

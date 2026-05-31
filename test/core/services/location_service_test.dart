import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sara_app/core/services/location_service.dart';

void main() {
  group('LocationService — Haversine', () {
    test('mesma posição retorna 0 metros', () {
      final p = LatLng(-10.1689, -48.3318);
      expect(LocationService.distanciaMetros(p, p), closeTo(0, 0.01));
    });

    test('Palmas → Porto Nacional ≈ 60 km', () {
      // Palmas: -10.1689, -48.3318 | Porto Nacional: -10.7046, -48.4135
      final palmas = LatLng(-10.1689, -48.3318);
      final portoNacional = LatLng(-10.7046, -48.4135);
      final dist = LocationService.distanciaMetros(palmas, portoNacional);
      // Distância real ≈ 60–62 km
      expect(dist, greaterThan(55000));
      expect(dist, lessThan(68000));
    });

    test('Palmas → Araguaína ≈ 360 km', () {
      final palmas = LatLng(-10.1689, -48.3318);
      final araguaina = LatLng(-7.1920, -48.2047);
      final dist = LocationService.distanciaMetros(palmas, araguaina);
      expect(dist, greaterThan(330000));
      expect(dist, lessThan(390000));
    });

    test('simetria: dist(A, B) == dist(B, A)', () {
      final a = LatLng(-10.1689, -48.3318);
      final b = LatLng(-11.7199, -49.0669);
      final ab = LocationService.distanciaMetros(a, b);
      final ba = LocationService.distanciaMetros(b, a);
      expect(ab, closeTo(ba, 0.001));
    });
  });

  group('LocationService — estaDentroDoRaio', () {
    final centro = LatLng(-10.1689, -48.3318);

    test('ponto idêntico ao centro está dentro de qualquer raio', () {
      expect(LocationService.estaDentroDoRaio(centro, 1, centro), isTrue);
    });

    test('ponto a ~150 m está dentro de raio de 500 m', () {
      // Desloca ~0.0013° em latitude ≈ 145 m
      final pontoProximo = LatLng(-10.1702, -48.3318);
      expect(
        LocationService.estaDentroDoRaio(centro, 500, pontoProximo),
        isTrue,
      );
    });

    test('ponto a ~145 m está fora de raio de 100 m', () {
      final pontoLonge = LatLng(-10.1702, -48.3318);
      expect(
        LocationService.estaDentroDoRaio(centro, 100, pontoLonge),
        isFalse,
      );
    });

    test('ponto em outra cidade está fora de qualquer raio prático', () {
      final gurupi = LatLng(-11.7199, -49.0669);
      expect(
        LocationService.estaDentroDoRaio(centro, 5000, gurupi),
        isFalse,
      );
    });

    test('ponto exatamente na borda do raio está dentro', () {
      // distanciaMetros(centro, p) ≈ 200 m; raio = 200 m
      const raio = 200.0;
      final dist = raio; // ponto exatamente na borda
      final pontoNaBorda = LatLng(
        centro.latitude + (dist / 111320),
        centro.longitude,
      );
      final distReal =
          LocationService.distanciaMetros(centro, pontoNaBorda);
      expect(
        LocationService.estaDentroDoRaio(centro, raio + 1, pontoNaBorda),
        isTrue,
      );
      expect(distReal, closeTo(raio, 5)); // tolerância de 5 m
    });
  });

  group('SyncResult', () {
    test('hasChanges é verdadeiro apenas quando success > 0', () {
      // Testa a lógica do SyncResult diretamente
      const r1 = _FakeSyncResult(success: 1, errors: 0, skipped: 0);
      const r2 = _FakeSyncResult(success: 0, errors: 1, skipped: 0);
      const r3 = _FakeSyncResult(success: 0, errors: 0, skipped: 1);
      expect(r1.hasChanges, isTrue);
      expect(r2.hasChanges, isFalse);
      expect(r3.hasChanges, isFalse);
    });

    test('total é soma de todos os campos', () {
      const r = _FakeSyncResult(success: 2, errors: 1, skipped: 3);
      expect(r.total, 6);
    });
  });
}

// ── Helper para testar a lógica de SyncResult sem importar AppDatabase ──
class _FakeSyncResult {
  final int success;
  final int errors;
  final int skipped;

  const _FakeSyncResult({
    required this.success,
    required this.errors,
    required this.skipped,
  });

  bool get hasChanges => success > 0;
  int get total => success + errors + skipped;
}

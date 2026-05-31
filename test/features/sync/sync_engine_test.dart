import 'package:flutter_test/flutter_test.dart';
import 'package:sara_app/data/models/alerta.dart';
import 'package:sara_app/data/mock/mock_alertas.dart';

void main() {
  group('MockAlertas', () {
    test('lista não está vazia', () {
      expect(MockAlertas.todos, isNotEmpty);
    });

    test('todos os alertas têm id não vazio', () {
      for (final a in MockAlertas.todos) {
        expect(a.id, isNotEmpty);
      }
    });

    test('todos os alertas têm coordenadas plausíveis para Tocantins', () {
      for (final a in MockAlertas.todos) {
        // Tocantins: lat -5° a -13°, lng -45° a -51°
        expect(a.latitude, greaterThan(-14));
        expect(a.latitude, lessThan(-4));
        expect(a.longitude, greaterThan(-52));
        expect(a.longitude, lessThan(-44));
      }
    });

    test('posicao getter retorna LatLng coerente', () {
      final a = MockAlertas.todos.first;
      expect(a.posicao.latitude, closeTo(a.latitude, 0.0001));
      expect(a.posicao.longitude, closeTo(a.longitude, 0.0001));
    });
  });

  group('Alerta.fromJson / toJson', () {
    test('round-trip preserva campos', () {
      final original = MockAlertas.todos.first;
      final json = original.toJson();
      final restaurado = Alerta.fromJson(json);

      expect(restaurado.id, original.id);
      expect(restaurado.fonte, original.fonte);
      expect(restaurado.tipo, original.tipo);
      expect(restaurado.severidade, original.severidade);
      expect(restaurado.latitude, closeTo(original.latitude, 0.000001));
      expect(restaurado.longitude, closeTo(original.longitude, 0.000001));
      expect(restaurado.lido, original.lido);
    });
  });

  group('AlertaSeveridade displayName', () {
    test('todos os valores têm displayName não vazio', () {
      for (final s in AlertaSeveridade.values) {
        expect(s.displayName, isNotEmpty);
      }
    });

    test('order correta de severidade (code em maiúsculas)', () {
      expect(AlertaSeveridade.baixa.code, 'BAIXA');
      expect(AlertaSeveridade.media.code, 'MEDIA');
      expect(AlertaSeveridade.alta.code, 'ALTA');
      expect(AlertaSeveridade.critica.code, 'CRITICA');
    });
  });

  group('AlertaFonte displayName', () {
    test('todos os valores têm displayName não vazio', () {
      for (final f in AlertaFonte.values) {
        expect(f.displayName, isNotEmpty);
      }
    });
  });
}

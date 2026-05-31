import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../core/database/app_database.dart';
import '../models/area_monitorada.dart';
import 'area_repository.dart';

/// Implementação SQLite — lê do banco local (seeded de mocks no primeiro boot).
class AreaRepositoryDb implements AreaRepository {
  const AreaRepositoryDb(this._db);

  final AppDatabase _db;

  @override
  Future<List<AreaMonitorada>> getAreasParaTecnico(String tecnicoId) async {
    final rows = await _db.getAreasByTecnico(tecnicoId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<AreaMonitorada>> getAreasParaProdutor(String produtorId) async {
    final rows = await _db.getAreasByProdutor(produtorId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<List<AreaMonitorada>> getTodasAreas() async {
    final rows = await _db.getAllAreas();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<AreaMonitorada?> getAreaPorId(String id) async {
    final row = await _db.getAreaById(id);
    return row == null ? null : _fromRow(row);
  }

  static AreaMonitorada _fromRow(Map<String, dynamic> r) {
    return AreaMonitorada(
      id: r['id'] as String,
      nome: r['nome'] as String,
      municipio: r['municipio'] as String,
      produtorId: r['produtor_id'] as String?,
      tecnicoAtribuidoId: r['tecnico_atribuido_id'] as String?,
      status: _parseStatus(r['status'] as String),
      percentualRegeneracao: (r['percentual_regeneracao'] as num).toDouble(),
      coordenadaReferencia: LatLng(
        (r['centro_lat'] as num).toDouble(),
        (r['centro_lng'] as num).toDouble(),
      ),
      poligono: _parsePoligono(r['poligono_json'] as String?),
      raioMetros: r['raio_metros'] != null
          ? (r['raio_metros'] as num).toDouble()
          : null,
      ultimaEvidencia: r['ultima_evidencia'] != null
          ? DateTime.fromMillisecondsSinceEpoch(r['ultima_evidencia'] as int)
          : null,
      totalEvidencias: (r['total_evidencias'] as int?) ?? 0,
    );
  }

  static List<LatLng>? _parsePoligono(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => LatLng(
                (e['lat'] as num).toDouble(),
                (e['lng'] as num).toDouble(),
              ))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static AreaStatus _parseStatus(String code) {
    return AreaStatus.values.firstWhere(
      (s) => s.code == code,
      orElse: () => AreaStatus.regular,
    );
  }
}

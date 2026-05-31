import '../../core/database/app_database.dart';
import '../models/registro_evidencia.dart';
import 'evidencia_repository.dart';

/// Implementação SQLite do repositório de evidências (offline-first).
/// Substitui o JSON plano da versão anterior.
class EvidenciaRepositoryDb implements EvidenciaRepository {
  EvidenciaRepositoryDb(this._db);

  final AppDatabase _db;

  @override
  Future<List<RegistroEvidencia>> getAll() async {
    final rows = await _db.getAllEvidencias();
    return Future.wait(rows.map(_fromRow));
  }

  @override
  Future<List<RegistroEvidencia>> getParaArea(String areaId) async {
    final rows = await _db.getEvidenciasByArea(areaId);
    return Future.wait(rows.map(_fromRow));
  }

  @override
  Future<List<RegistroEvidencia>> getPendentes() async {
    final rows = await _db.getPendentesSync();
    return Future.wait(rows.map(_fromRow));
  }

  @override
  Future<RegistroEvidencia?> getById(String id) async {
    final row = await _db.getEvidenciaById(id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<void> salvar(RegistroEvidencia evidencia) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.insertEvidencia({
      'id': evidencia.id,
      'area_id': evidencia.areaId,
      'autor_id': evidencia.autorId,
      'autor_nome': evidencia.autorNome,
      'tipo': evidencia.tipo.code,
      'latitude': evidencia.latitude,
      'longitude': evidencia.longitude,
      'precisao_gps': evidencia.precisaoGps,
      'observacoes': evidencia.observacoes,
      'data_registro': evidencia.dataRegistro.millisecondsSinceEpoch,
      'status_sync': evidencia.statusSync.code,
      'updated_at': now,
      'dirty': 1,
    });

    for (int i = 0; i < evidencia.fotos.length; i++) {
      final foto = evidencia.fotos[i];
      await _db.insertFoto({
        'id': '${evidencia.id}_$i',
        'evidencia_id': evidencia.id,
        'path_local': foto.pathLocal,
        'latitude': foto.latitude,
        'longitude': foto.longitude,
        'capturada_em': foto.capturadaEm.millisecondsSinceEpoch,
        'uploaded': 0,
      });
    }

    // Insere na fila de sincronização (outbox)
    await _db.insertOutboxItem({
      'entidade': 'evidencia',
      'entidade_id': evidencia.id,
      'operacao': 'create',
      'proxima_tentativa': DateTime.now().millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> atualizarStatus(String id, StatusSincronizacao status) =>
      _db.updateEvidenciaStatus(id, status.code);

  @override
  Future<int> contarPendentes() => _db.countPendentesSync();

  // ── Conversão SQLite → domínio ────────────────────────────
  Future<RegistroEvidencia> _fromRow(Map<String, dynamic> r) async {
    final fotoRows = await _db.getFotosByEvidencia(r['id'] as String);

    final fotos = fotoRows.map((f) => FotoEvidencia(
          pathLocal: f['path_local'] as String,
          latitude: (f['latitude'] as num).toDouble(),
          longitude: (f['longitude'] as num).toDouble(),
          capturadaEm: DateTime.fromMillisecondsSinceEpoch(
              f['capturada_em'] as int),
        )).toList();

    // Garante o assert de >= 1 foto; se o banco tiver corrompido, usa placeholder
    if (fotos.isEmpty) {
      fotos.add(FotoEvidencia(
        pathLocal: '',
        latitude: r['latitude'] as double,
        longitude: r['longitude'] as double,
        capturadaEm: DateTime.fromMillisecondsSinceEpoch(
            r['data_registro'] as int),
      ));
    }

    return RegistroEvidencia(
      id: r['id'] as String,
      areaId: r['area_id'] as String,
      autorId: r['autor_id'] as String,
      autorNome: r['autor_nome'] as String,
      tipo: TipoEvidencia.fromCode(r['tipo'] as String),
      fotos: fotos,
      latitude: (r['latitude'] as num).toDouble(),
      longitude: (r['longitude'] as num).toDouble(),
      precisaoGps: (r['precisao_gps'] as num?)?.toDouble(),
      observacoes: r['observacoes'] as String? ?? '',
      dataRegistro: DateTime.fromMillisecondsSinceEpoch(
          r['data_registro'] as int),
      statusSync: StatusSyncExt.fromCode(r['status_sync'] as String),
    );
  }
}

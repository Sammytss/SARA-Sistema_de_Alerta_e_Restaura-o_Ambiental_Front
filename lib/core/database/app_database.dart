import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../data/mock/mock_areas.dart';
import '../../data/models/registro_evidencia.dart';

// ── Schema SQL ────────────────────────────────────────────────
const _createAreas = '''
  CREATE TABLE IF NOT EXISTS areas (
    id                      TEXT PRIMARY KEY,
    nome                    TEXT NOT NULL,
    municipio               TEXT NOT NULL,
    produtor_id             TEXT,
    tecnico_atribuido_id    TEXT,
    status                  TEXT NOT NULL,
    percentual_regeneracao  REAL NOT NULL,
    centro_lat              REAL NOT NULL,
    centro_lng              REAL NOT NULL,
    raio_metros             REAL,
    poligono_json           TEXT,
    ultima_evidencia        INTEGER,
    total_evidencias        INTEGER NOT NULL DEFAULT 0,
    updated_at              INTEGER NOT NULL,
    dirty                   INTEGER NOT NULL DEFAULT 0
  )
''';

const _createEvidencias = '''
  CREATE TABLE IF NOT EXISTS evidencias (
    id             TEXT PRIMARY KEY,
    area_id        TEXT NOT NULL,
    autor_id       TEXT NOT NULL,
    autor_nome     TEXT NOT NULL,
    tipo           TEXT NOT NULL,
    latitude       REAL NOT NULL,
    longitude      REAL NOT NULL,
    precisao_gps   REAL,
    observacoes    TEXT NOT NULL DEFAULT '',
    data_registro  INTEGER NOT NULL,
    status_sync    TEXT NOT NULL DEFAULT 'PENDENTE',
    updated_at     INTEGER NOT NULL,
    dirty          INTEGER NOT NULL DEFAULT 1
  )
''';

const _createFotos = '''
  CREATE TABLE IF NOT EXISTS fotos (
    id           TEXT PRIMARY KEY,
    evidencia_id TEXT NOT NULL,
    path_local   TEXT NOT NULL,
    remote_url   TEXT,
    latitude     REAL NOT NULL,
    longitude    REAL NOT NULL,
    capturada_em INTEGER NOT NULL,
    uploaded     INTEGER NOT NULL DEFAULT 0
  )
''';

const _createOutbox = '''
  CREATE TABLE IF NOT EXISTS outbox_items (
    seq               INTEGER PRIMARY KEY AUTOINCREMENT,
    entidade          TEXT NOT NULL,
    entidade_id       TEXT NOT NULL,
    operacao          TEXT NOT NULL,
    tentativas        INTEGER NOT NULL DEFAULT 0,
    proxima_tentativa INTEGER NOT NULL,
    processando       INTEGER NOT NULL DEFAULT 0
  )
''';

// ── AppDatabase ───────────────────────────────────────────────
class AppDatabase {
  static const _dbName = 'sara_db.sqlite';
  static const _dbVersion = 2;

  Database? _db;

  /// Abre e inicializa o banco (idempotente — chame no boot).
  Future<void> initialize() async {
    _db ??= await _openDatabase();
    await seedAreasIfEmpty();
    await migrateFromJsonIfNeeded();
  }

  Future<Database> get _database async {
    _db ??= await _openDatabase();
    return _db!;
  }

  Future<Database> _openDatabase() async {
    // Windows/Linux: usa FFI. Android/iOS: usa plugin nativo.
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = await _dbPath();
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute(_createAreas);
        await db.execute(_createEvidencias);
        await db.execute(_createFotos);
        await db.execute(_createOutbox);
        await db.execute(
            'CREATE INDEX idx_evidencias_area ON evidencias(area_id)');
        await db.execute(
            'CREATE INDEX idx_evidencias_sync ON evidencias(status_sync)');
        await db.execute(
            'CREATE INDEX idx_fotos_evidencia ON fotos(evidencia_id)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE areas ADD COLUMN poligono_json TEXT');
        }
      },
    );
  }

  Future<String> _dbPath() async {
    if (Platform.isWindows || Platform.isLinux) {
      final dir = await getApplicationDocumentsDirectory();
      return p.join(dir.path, _dbName);
    }
    return p.join(await getDatabasesPath(), _dbName);
  }

  Future<void> close() async => (await _database).close();

  // ── Areas ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllAreas() async =>
      (await _database).query('areas');

  Future<List<Map<String, dynamic>>> getAreasByTecnico(
          String tecnicoId) async =>
      (await _database).query('areas',
          where: 'tecnico_atribuido_id = ?', whereArgs: [tecnicoId]);

  Future<List<Map<String, dynamic>>> getAreasByProdutor(
          String produtorId) async =>
      (await _database).query('areas',
          where: 'produtor_id = ?', whereArgs: [produtorId]);

  Future<Map<String, dynamic>?> getAreaById(String id) async {
    final rows = await (await _database)
        .query('areas', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> upsertArea(Map<String, dynamic> data) async =>
      (await _database)
          .insert('areas', data, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Atualiza centro GPS e raio de uma área; grava no outbox para sync.
  Future<void> updateAreaRaio(
    String areaId,
    double centroLat,
    double centroLng,
    double raioMetros,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _database;
    await db.update(
      'areas',
      {
        'centro_lat': centroLat,
        'centro_lng': centroLng,
        'raio_metros': raioMetros,
        'dirty': 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [areaId],
    );
    await db.insert(
      'outbox_items',
      {
        'entidade': 'area',
        'entidade_id': areaId,
        'operacao': 'update',
        'tentativas': 0,
        'proxima_tentativa': now,
        'processando': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atualiza o polígono de uma área; grava no outbox para sync.
  Future<void> updateAreaPoligono(
    String areaId,
    List<LatLng> vertices,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final poligonoJson = jsonEncode(
      vertices
          .map((v) => {'lat': v.latitude, 'lng': v.longitude})
          .toList(),
    );
    final db = await _database;
    await db.update(
      'areas',
      {
        'poligono_json': poligonoJson,
        'dirty': 1,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [areaId],
    );
    await db.insert(
      'outbox_items',
      {
        'entidade': 'area',
        'entidade_id': areaId,
        'operacao': 'update',
        'tentativas': 0,
        'proxima_tentativa': now,
        'processando': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> seedAreasIfEmpty() async {
    final db = await _database;
    final count =
        Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM areas'));
    if ((count ?? 0) > 0) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final area in MockAreas.todas) {
      await db.insert('areas', {
        'id': area.id,
        'nome': area.nome,
        'municipio': area.municipio,
        'produtor_id': area.produtorId,
        'tecnico_atribuido_id': area.tecnicoAtribuidoId,
        'status': area.status.code,
        'percentual_regeneracao': area.percentualRegeneracao,
        'centro_lat': area.coordenadaReferencia.latitude,
        'centro_lng': area.coordenadaReferencia.longitude,
        'raio_metros': area.raioMetros,
        'ultima_evidencia': area.ultimaEvidencia?.millisecondsSinceEpoch,
        'total_evidencias': area.totalEvidencias,
        'updated_at': now,
        'dirty': 0,
      });
    }
  }

  // ── Evidencias ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getAllEvidencias() async =>
      (await _database).query('evidencias',
          orderBy: 'data_registro DESC');

  Future<List<Map<String, dynamic>>> getEvidenciasByArea(
          String areaId) async =>
      (await _database).query('evidencias',
          where: 'area_id = ?',
          whereArgs: [areaId],
          orderBy: 'data_registro DESC');

  Future<List<Map<String, dynamic>>> getPendentesSync() async =>
      (await _database).query('evidencias',
          where: "status_sync IN ('PENDENTE','ERRO')",
          orderBy: 'data_registro DESC');

  Future<int> countPendentesSync() async {
    final count = Sqflite.firstIntValue(await (await _database)
        .rawQuery(
            "SELECT COUNT(*) FROM evidencias WHERE status_sync IN ('PENDENTE','ERRO')"));
    return count ?? 0;
  }

  Future<Map<String, dynamic>?> getEvidenciaById(String id) async {
    final rows = await (await _database)
        .query('evidencias', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> insertEvidencia(Map<String, dynamic> data) async =>
      (await _database)
          .insert('evidencias', data, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateEvidenciaStatus(String id, String status) async =>
      (await _database).update(
          'evidencias', {'status_sync': status, 'dirty': status != 'ENVIADO' ? 1 : 0},
          where: 'id = ?', whereArgs: [id]);

  // ── Fotos ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getFotosByEvidencia(
          String evidenciaId) async =>
      (await _database).query('fotos',
          where: 'evidencia_id = ?', whereArgs: [evidenciaId]);

  Future<void> insertFoto(Map<String, dynamic> data) async =>
      (await _database)
          .insert('fotos', data, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> markFotoUploaded(String id, String remoteUrl) async =>
      (await _database).update('fotos', {'uploaded': 1, 'remote_url': remoteUrl},
          where: 'id = ?', whereArgs: [id]);

  // ── Outbox ─────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getPendingOutboxItems() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return (await _database).query('outbox_items',
        where: 'processando = 0 AND proxima_tentativa <= ?',
        whereArgs: [now],
        orderBy: 'seq ASC');
  }

  Future<int> insertOutboxItem(Map<String, dynamic> data) async =>
      (await _database).insert('outbox_items', data);

  Future<void> deleteOutboxItem(int seq) async =>
      (await _database)
          .delete('outbox_items', where: 'seq = ?', whereArgs: [seq]);

  Future<void> failOutboxItem(int seq) async {
    final db = await _database;
    final rows =
        await db.query('outbox_items', where: 'seq = ?', whereArgs: [seq]);
    if (rows.isEmpty) return;
    final tentativas = (rows.first['tentativas'] as int? ?? 0) + 1;
    final backoffSec = 30 * tentativas;
    final proxima = DateTime.now()
        .add(Duration(seconds: backoffSec))
        .millisecondsSinceEpoch;
    await db.update(
      'outbox_items',
      {'tentativas': tentativas, 'proxima_tentativa': proxima, 'processando': 0},
      where: 'seq = ?',
      whereArgs: [seq],
    );
  }

  Future<void> markOutboxProcessando(int seq, {required bool value}) async =>
      (await _database).update('outbox_items', {'processando': value ? 1 : 0},
          where: 'seq = ?', whereArgs: [seq]);

  // ── Dashboard ─────────────────────────────────────────────
  /// Totais agregados por status para o dashboard do gestor.
  Future<Map<String, dynamic>> getDashboardResumo() async {
    final db = await _database;
    final rows = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 'CRITICA' THEN 1 ELSE 0 END) AS critica,
        SUM(CASE WHEN status = 'ATENCAO' THEN 1 ELSE 0 END) AS atencao,
        SUM(CASE WHEN status = 'REGULAR' THEN 1 ELSE 0 END) AS regular,
        COALESCE(SUM(total_evidencias), 0) AS total_evidencias,
        AVG(percentual_regeneracao) AS media_regeneracao
      FROM areas
    ''');
    if (rows.isEmpty) return {};
    final r = rows.first;
    return {
      'total': (r['total'] as int?) ?? 0,
      'critica': (r['critica'] as int?) ?? 0,
      'atencao': (r['atencao'] as int?) ?? 0,
      'regular': (r['regular'] as int?) ?? 0,
      'total_evidencias': (r['total_evidencias'] as int?) ?? 0,
      'media_regeneracao':
          (r['media_regeneracao'] as num?)?.toDouble() ?? 0.0,
    };
  }

  /// Breakdown por município para gráfico do dashboard / indicadores públicos.
  Future<List<Map<String, dynamic>>> getResumoByMunicipio() async {
    final db = await _database;
    return db.rawQuery('''
      SELECT
        municipio,
        COUNT(*) AS total,
        SUM(CASE WHEN status = 'CRITICA' THEN 1 ELSE 0 END) AS critica,
        SUM(CASE WHEN status = 'ATENCAO' THEN 1 ELSE 0 END) AS atencao,
        SUM(CASE WHEN status = 'REGULAR' THEN 1 ELSE 0 END) AS regular,
        AVG(percentual_regeneracao) AS media_regeneracao
      FROM areas
      GROUP BY municipio
      ORDER BY total DESC
    ''');
  }

  // ── Migração JSON → SQLite ─────────────────────────────────
  /// Importa evidências do arquivo JSON legado para o banco SQLite.
  Future<void> migrateFromJsonIfNeeded() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final jsonFile = File(p.join(docDir.path, 'evidencias_queue.json'));
      if (!await jsonFile.exists()) return;

      final raw = await jsonFile.readAsString();
      final list = jsonDecode(raw) as List;
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final e in list) {
        final ev = RegistroEvidencia.fromJson(e as Map<String, dynamic>);
        final existing = await getEvidenciaById(ev.id);
        if (existing != null) continue;

        await insertEvidencia({
          'id': ev.id,
          'area_id': ev.areaId,
          'autor_id': ev.autorId,
          'autor_nome': ev.autorNome,
          'tipo': ev.tipo.code,
          'latitude': ev.latitude,
          'longitude': ev.longitude,
          'precisao_gps': ev.precisaoGps,
          'observacoes': ev.observacoes,
          'data_registro': ev.dataRegistro.millisecondsSinceEpoch,
          'status_sync': ev.statusSync.code,
          'updated_at': now,
          'dirty': ev.statusSync != StatusSincronizacao.enviado ? 1 : 0,
        });

        for (int i = 0; i < ev.fotos.length; i++) {
          final foto = ev.fotos[i];
          await insertFoto({
            'id': '${ev.id}_$i',
            'evidencia_id': ev.id,
            'path_local': foto.pathLocal,
            'latitude': foto.latitude,
            'longitude': foto.longitude,
            'capturada_em': foto.capturadaEm.millisecondsSinceEpoch,
            'uploaded': 0,
          });
        }
      }

      await jsonFile.rename('${docDir.path}/evidencias_queue.json.migrated');
    } catch (_) {
      // Migração não-crítica — falha silenciosa para não travar o boot
    }
  }
}

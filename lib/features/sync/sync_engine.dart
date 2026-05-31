import '../../core/database/app_database.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/datasources/remote/evidencia_remote_datasource.dart';

/// Resultado de uma rodada de sincronização.
class SyncResult {
  final int success;
  final int errors;
  final int skipped;

  const SyncResult({
    this.success = 0,
    this.errors = 0,
    this.skipped = 0,
  });

  bool get hasChanges => success > 0;
  int get total => success + errors + skipped;
}

/// Motor de sincronização offline → online (padrão Outbox).
///
/// Fluxo de [push]:
/// 1. Drena o outbox (itens com proximaTentativa <= agora, não processando).
/// 2. Para cada item, tenta enviar ao backend via [EvidenciaRemoteDatasource].
/// 3. Sucesso → remove do outbox, atualiza status = ENVIADO.
/// 4. Falha → incrementa tentativas, agenda próxima tentativa (backoff exponencial).
class SyncEngine {
  SyncEngine({
    required AppDatabase db,
    required EvidenciaRemoteDatasource remote,
    required ConnectivityService connectivity,
  })  : _db = db,
        _remote = remote,
        _connectivity = connectivity;

  final AppDatabase _db;
  final EvidenciaRemoteDatasource _remote;
  final ConnectivityService _connectivity;

  bool _running = false;

  /// Tenta sincronizar todos os itens pendentes no outbox.
  /// Retorna [SyncResult] com contagem de sucesso/erro/skipped.
  Future<SyncResult> push() async {
    if (_running) return const SyncResult(skipped: 1);

    final isOnline = await _connectivity.isConnected();
    if (!isOnline) return const SyncResult(skipped: 1);

    _running = true;
    int success = 0;
    int errors = 0;

    try {
      final pending = await _db.getPendingOutboxItems();

      for (final item in pending) {
        final seq = item['seq'] as int;
        final entidade = item['entidade'] as String;
        final entidadeId = item['entidade_id'] as String;

        await _db.markOutboxProcessando(seq, value: true);

        try {
          if (entidade == 'evidencia') {
            await _syncEvidencia(entidadeId);
          }
          await _db.deleteOutboxItem(seq);
          success++;
        } catch (_) {
          await _db.failOutboxItem(seq);
          await _db.updateEvidenciaStatus(entidadeId, 'ERRO');
          errors++;
        }
      }
    } finally {
      _running = false;
    }

    return SyncResult(success: success, errors: errors);
  }

  Future<void> _syncEvidencia(String evidenciaId) async {
    final evidRow = await _db.getEvidenciaById(evidenciaId);
    if (evidRow == null) return;

    await _db.updateEvidenciaStatus(evidenciaId, 'ENVIANDO');

    // Upload de fotos não enviadas
    final fotoRows = await _db.getFotosByEvidencia(evidenciaId);
    for (final foto in fotoRows) {
      if ((foto['uploaded'] as int? ?? 0) == 1) continue;
      final remoteUrl = await _remote.uploadFoto(foto['path_local'] as String);
      await _db.markFotoUploaded(foto['id'] as String, remoteUrl);
    }

    // Envia a evidência ao backend
    final fotosAtualizadas = await _db.getFotosByEvidencia(evidenciaId);
    await _remote.createEvidencia(evidRow, fotosAtualizadas);

    // Marca como sincronizada
    await _db.updateEvidenciaStatus(evidenciaId, 'ENVIADO');
  }
}

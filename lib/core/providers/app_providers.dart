import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/network/api_client.dart';
import '../../core/security/secure_store.dart';
import '../../core/services/connectivity_service.dart';
import '../../data/datasources/remote/evidencia_remote_datasource.dart';
import '../../data/repositories/area_repository.dart';
import '../../data/repositories/area_repository_db.dart';
import '../../data/repositories/evidencia_repository.dart';
import '../../data/repositories/evidencia_repository_db.dart';
import '../../features/sync/sync_engine.dart';

// ── Infra ──────────────────────────────────────────────────────
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(secureStore: ref.watch(secureStoreProvider));
});

final secureStoreProvider = Provider<SecureStore>((_) => SecureStore());

final connectivityServiceProvider =
    Provider<ConnectivityService>((_) => ConnectivityService());

// ── Repositórios ───────────────────────────────────────────────
final areaRepositoryProvider = Provider<AreaRepository>((ref) {
  return AreaRepositoryDb(ref.watch(appDatabaseProvider));
});

final evidenciaRepositoryProvider = Provider<EvidenciaRepository>((ref) {
  return EvidenciaRepositoryDb(ref.watch(appDatabaseProvider));
});

// ── Sync ───────────────────────────────────────────────────────
final evidenciaRemoteProvider =
    Provider<EvidenciaRemoteDatasource>((_) => EvidenciaRemoteMock());

final syncEngineProvider = Provider<SyncEngine>((ref) {
  return SyncEngine(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(evidenciaRemoteProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  );
});

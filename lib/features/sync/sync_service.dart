import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../areas/areas_provider.dart';
import 'sync_engine.dart';

/// Estado da sincronização exposto à UI.
class SyncState {
  final bool isRunning;
  final SyncResult? lastResult;
  final String? errorMessage;

  const SyncState({
    this.isRunning = false,
    this.lastResult,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isRunning,
    SyncResult? lastResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncState(
      isRunning: isRunning ?? this.isRunning,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier que expõe o estado de sync e dispara push() manualmente.
/// O auto-sync por conectividade é tratado em [AutoSyncService].
class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier(this._ref) : super(const SyncState());

  final Ref _ref;

  Future<SyncResult> syncNow() async {
    if (state.isRunning) return const SyncResult(skipped: 1);

    state = state.copyWith(isRunning: true, clearError: true);

    try {
      final engine = _ref.read(syncEngineProvider);
      final result = await engine.push();

      state = state.copyWith(isRunning: false, lastResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Erro ao sincronizar: $e',
      );
      return const SyncResult(errors: 1);
    }
  }
}

final syncNotifierProvider =
    StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

/// Serviço de auto-sync: escuta conectividade e dispara push() ao voltar a conexão.
/// Inicialize chamando [AutoSyncService.init] no boot do app.
class AutoSyncService {
  AutoSyncService(this._ref);

  final WidgetRef _ref;

  void init() {
    final connectivity = _ref.read(connectivityServiceProvider);
    connectivity.statusStream.listen((isConnected) {
      if (isConnected) {
        _ref.read(syncNotifierProvider.notifier).syncNow().then((_) {
          _ref.invalidate(filaSyncProvider);
          _ref.invalidate(pendenciasCountProvider);
        });
      }
    });
  }
}

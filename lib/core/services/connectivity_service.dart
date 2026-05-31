import 'package:connectivity_plus/connectivity_plus.dart';

/// Serviço de monitoramento de conectividade.
/// Usado pelo SyncEngine para disparar sincronização automática ao voltar a conexão.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Emite `true` quando conectado, `false` quando offline.
  Stream<bool> get statusStream => _connectivity.onConnectivityChanged
      .map((results) => results.any((r) => r != ConnectivityResult.none));
}

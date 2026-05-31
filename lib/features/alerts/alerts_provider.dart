import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';
import '../../data/datasources/remote/alerts_remote_datasource.dart';
import '../../data/models/alerta.dart';
import '../../data/repositories/alerts_repository.dart';
import '../../data/repositories/alerts_repository_mock.dart';
import '../../data/repositories/alerts_repository_real.dart';
import '../areas/areas_provider.dart';

// ── Repositório ───────────────────────────────────────────────────

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  if (AppConfig.useMockData) {
    return AlertsRepositoryMock(AlertsRemoteMock());
  }
  return AlertsRepositoryReal(AlertsRemoteReal(ref.watch(apiClientProvider)));
});

// ── Providers de dados ────────────────────────────────────────────

/// Todos os alertas acessíveis ao usuário logado (filtrado pelas suas áreas).
final todosAlertasProvider = FutureProvider<List<Alerta>>((ref) async {
  final areasAsync = ref.watch(areasDoUsuarioProvider);
  final areaIds = areasAsync.valueOrNull?.map((a) => a.id).toSet() ?? {};

  final repo = ref.watch(alertsRepositoryProvider);
  final todos = await repo.getTodosAlertas();

  return todos
      .where((a) => a.areaId == null || areaIds.contains(a.areaId))
      .toList()
    ..sort((a, b) => b.detectadoEm.compareTo(a.detectadoEm));
});

/// Alertas de uma área específica.
final alertasParaAreaProvider =
    FutureProvider.family<List<Alerta>, String>((ref, areaId) async {
  final repo = ref.watch(alertsRepositoryProvider);
  final lista = await repo.getAlertasParaArea(areaId);
  return lista..sort((a, b) => b.detectadoEm.compareTo(a.detectadoEm));
});

/// Contagem de alertas não lidos do usuário (para badge).
final alertasNaoLidosProvider = Provider<int>((ref) {
  final alertas = ref.watch(todosAlertasProvider);
  return alertas.valueOrNull?.where((a) => !a.lido).length ?? 0;
});

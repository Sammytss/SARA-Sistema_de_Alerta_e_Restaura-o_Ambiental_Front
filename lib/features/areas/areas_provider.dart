import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../data/models/area_monitorada.dart';
import '../../data/models/registro_evidencia.dart';
import '../auth/auth_provider.dart';
import '../access_control/user_role.dart';

// ── Áreas do usuário logado (filtradas por perfil) ────────────
final areasDoUsuarioProvider =
    FutureProvider<List<AreaMonitorada>>((ref) async {
  final authState = ref.watch(authProvider);
  final repo = ref.watch(areaRepositoryProvider);
  final usuario = authState.usuario;

  if (usuario == null) return [];

  return switch (usuario.perfil) {
    UserRole.tecnico => repo.getAreasParaTecnico(usuario.id),
    UserRole.produtor => repo.getAreasParaProdutor(usuario.id),
    UserRole.gestor => repo.getTodasAreas(),
    _ => [],
  };
});

// ── Detalhe de uma área específica ────────────────────────────
final areaDetalheProvider =
    FutureProvider.family<AreaMonitorada?, String>((ref, areaId) async {
  final repo = ref.watch(areaRepositoryProvider);
  return repo.getAreaPorId(areaId);
});

// ── Evidências de uma área ────────────────────────────────────
final evidenciasDaAreaProvider =
    FutureProvider.family<List<RegistroEvidencia>, String>(
        (ref, areaId) async {
  final repo = ref.watch(evidenciaRepositoryProvider);
  return repo.getParaArea(areaId);
});

// ── Contador de pendências de sync ────────────────────────────
final pendenciasCountProvider = FutureProvider<int>((ref) async {
  final repo = ref.watch(evidenciaRepositoryProvider);
  return repo.contarPendentes();
});

// ── Fila de sync (para a tela de sync) ───────────────────────
final filaSyncProvider =
    FutureProvider<List<RegistroEvidencia>>((ref) async {
  final repo = ref.watch(evidenciaRepositoryProvider);
  return repo.getPendentes();
});

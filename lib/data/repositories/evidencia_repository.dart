import '../models/registro_evidencia.dart';

/// Interface do repositório de evidências de campo.
abstract class EvidenciaRepository {
  Future<List<RegistroEvidencia>> getAll();
  Future<List<RegistroEvidencia>> getParaArea(String areaId);
  Future<List<RegistroEvidencia>> getPendentes();
  Future<RegistroEvidencia?> getById(String id);
  Future<void> salvar(RegistroEvidencia evidencia);
  Future<void> atualizarStatus(String id, StatusSincronizacao status);
  Future<int> contarPendentes();
}

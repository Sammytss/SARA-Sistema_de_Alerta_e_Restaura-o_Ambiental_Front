import '../models/area_monitorada.dart';

/// Interface do repositório de áreas monitoradas.
/// Trocar implementação (mock → sqflite → REST) sem tocar a UI.
abstract class AreaRepository {
  Future<List<AreaMonitorada>> getAreasParaTecnico(String tecnicoId);
  Future<List<AreaMonitorada>> getAreasParaProdutor(String produtorId);
  Future<List<AreaMonitorada>> getTodasAreas();
  Future<AreaMonitorada?> getAreaPorId(String id);
}

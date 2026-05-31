import '../mock/mock_areas.dart';
import '../models/area_monitorada.dart';
import 'area_repository.dart';

/// Implementação mock — retorna dados estáticos sem banco.
/// Usada quando AppConfig.useMockData = true ou banco ainda não inicializado.
class AreaRepositoryMock implements AreaRepository {
  const AreaRepositoryMock();

  @override
  Future<List<AreaMonitorada>> getAreasParaTecnico(String tecnicoId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockAreas.paraTecnico(tecnicoId);
  }

  @override
  Future<List<AreaMonitorada>> getAreasParaProdutor(String produtorId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockAreas.paraProdutor(produtorId);
  }

  @override
  Future<List<AreaMonitorada>> getTodasAreas() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockAreas.todas;
  }

  @override
  Future<AreaMonitorada?> getAreaPorId(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return MockAreas.todas.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}

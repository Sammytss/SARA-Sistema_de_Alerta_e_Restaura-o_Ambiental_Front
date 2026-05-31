import '../datasources/remote/alerts_remote_datasource.dart';
import '../models/alerta.dart';
import 'alerts_repository.dart';

class AlertsRepositoryMock implements AlertsRepository {
  final AlertsRemoteDatasource _remote;

  AlertsRepositoryMock(this._remote);

  @override
  Future<List<Alerta>> getTodosAlertas() async {
    final result = await _remote.getAlertas();
    return result.valueOrNull ?? [];
  }

  @override
  Future<List<Alerta>> getAlertasParaArea(String areaId) async {
    final result = await _remote.getAlertas(areaId: areaId);
    return result.valueOrNull ?? [];
  }
}

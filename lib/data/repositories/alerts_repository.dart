import '../models/alerta.dart';

/// Contrato de repositório de alertas de ameaça.
abstract class AlertsRepository {
  Future<List<Alerta>> getTodosAlertas();
  Future<List<Alerta>> getAlertasParaArea(String areaId);
}

/// Datasource remoto de evidências.
/// M1: implementação mock com delay e falha simulada.
/// Fase 4: substituir os métodos por chamadas Dio reais (sem mexer na interface).
abstract class EvidenciaRemoteDatasource {
  Future<String> uploadFoto(String pathLocal);
  Future<void> createEvidencia(Map<String, dynamic> evidenciaRow,
      List<Map<String, dynamic>> fotoRows);
}

class EvidenciaRemoteMock implements EvidenciaRemoteDatasource {
  @override
  Future<String> uploadFoto(String pathLocal) async {
    await Future.delayed(const Duration(milliseconds: 600));
    // Simula URL remota gerada pelo servidor
    final ts = DateTime.now().millisecondsSinceEpoch;
    return 'https://api.sara.to.gov.br/fotos/$ts.jpg';
  }

  @override
  Future<void> createEvidencia(Map<String, dynamic> evidenciaRow,
      List<Map<String, dynamic>> fotoRows) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // 10% de chance de falha para testar retry/backoff
    if (evidenciaRow['id'].hashCode % 10 == 0) {
      throw Exception('Falha simulada de rede');
    }
  }
}

/// Permissões do SARA MVP.
/// Escopo enxuto — foco no loop de registro de evidências em campo.
enum Permission {
  // ── Visualização ───────────────────────────────────────────
  /// Dados agregados públicos (sem login).
  areaViewAggregated('AREA_VIEW_AGGREGATED', 'Ver dados agregados'),

  /// Ver apenas as próprias áreas (produtor).
  areaViewOwn('AREA_VIEW_OWN', 'Ver áreas próprias'),

  /// Ver áreas atribuídas (técnico).
  areaViewAssigned('AREA_VIEW_ASSIGNED', 'Ver áreas atribuídas'),

  /// Ver todas as áreas do sistema (gestor).
  areaViewAll('AREA_VIEW_ALL', 'Ver todas as áreas'),

  /// Ver dados sensíveis de qualquer área (técnico, gestor).
  sensitiveDataView('SENSITIVE_DATA_VIEW', 'Ver dados sensíveis'),

  /// Ver dados sensíveis apenas das próprias áreas (produtor).
  sensitiveDataViewOwn('SENSITIVE_DATA_VIEW_OWN', 'Ver dados sensíveis próprios'),

  // ── Registro de evidências (núcleo do MVP) ────────────────
  /// Registrar evidência com foto e GPS (técnico, produtor).
  evidenceCreate('EVIDENCE_CREATE', 'Registrar evidência'),

  // ── Sincronização ─────────────────────────────────────────
  /// Sincronizar dados offline → online.
  syncOffline('SYNC_OFFLINE', 'Sincronizar offline'),

  // ── Administração (gestor) ────────────────────────────────
  /// Atribuir áreas a técnicos.
  areaAssign('AREA_ASSIGN', 'Atribuir áreas');

  final String code;
  final String displayName;

  const Permission(this.code, this.displayName);

  static Permission fromCode(String code) {
    return Permission.values.firstWhere(
      (p) => p.code == code,
      orElse: () => Permission.areaViewAggregated,
    );
  }
}

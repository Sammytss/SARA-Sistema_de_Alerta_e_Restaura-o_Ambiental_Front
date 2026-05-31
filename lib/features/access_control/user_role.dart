/// Perfis de acesso do SARA APP.
/// Cada perfil define um nível de acesso e conjunto de permissões.
/// Conforme Seção 3 e 7 do documento de requisitos.
enum UserRole {
  publico('PUBLICO', 'Público', 'Acesso sem login'),
  gestor('GESTOR', 'Gestor', 'Visão estratégica e administrativa'),
  produtor('PRODUTOR', 'Produtor', 'Proprietário ou responsável da área'),
  analista('ANALISTA', 'Analista', 'Avaliação técnico-administrativa'),
  auditor('AUDITOR', 'Auditor', 'Controle e rastreabilidade'),
  tecnico('TECNICO', 'Técnico', 'Coleta de campo e vistorias'),
  operario('OPERARIO', 'Operário', 'Execução de tarefas práticas');

  final String code;
  final String displayName;
  final String description;

  const UserRole(this.code, this.displayName, this.description);

  /// Retorna o UserRole a partir de um código string.
  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (role) => role.code == code.toUpperCase(),
      orElse: () => UserRole.publico,
    );
  }

  /// Se o perfil é autenticado (não público).
  bool get isAuthenticated => this != UserRole.publico;

  /// Se o perfil tem acesso administrativo.
  bool get isAdmin => this == UserRole.gestor;

  /// Se o perfil trabalha em campo.
  bool get isFieldWorker =>
      this == UserRole.tecnico || this == UserRole.operario;

  /// Se o perfil é somente leitura.
  bool get isReadOnly => this == UserRole.auditor;
}

/// Status do usuário no sistema.
/// Conforme Seção 7 do documento de requisitos.
enum UserStatus {
  ativo('ATIVO', 'Ativo'),
  inativo('INATIVO', 'Inativo'),
  pendente('PENDENTE', 'Pendente'),
  bloqueado('BLOQUEADO', 'Bloqueado');

  final String code;
  final String displayName;

  const UserStatus(this.code, this.displayName);

  static UserStatus fromCode(String code) {
    return UserStatus.values.firstWhere(
      (status) => status.code == code.toUpperCase(),
      orElse: () => UserStatus.pendente,
    );
  }

  bool get canLogin => this == UserStatus.ativo;
}

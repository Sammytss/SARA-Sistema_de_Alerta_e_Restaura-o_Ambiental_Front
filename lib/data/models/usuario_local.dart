import '../../features/access_control/user_role.dart';
import '../../features/access_control/permission.dart';
import '../../features/access_control/permission_service.dart';

/// Modelo do usuário local armazenado no app.
/// Conforme Seção 12 do documento de requisitos.
class UsuarioLocal {
  final String id;
  final String nome;
  final String email;
  final UserRole perfil;
  final List<Permission> permissoes;
  final String? token;
  final UserStatus status;
  final DateTime? ultimoLogin;
  final String? telefone;
  final String? documento;
  final String? orgaoInstituicao;
  final DateTime? dataCadastro;

  UsuarioLocal({
    required this.id,
    required this.nome,
    required this.email,
    required this.perfil,
    List<Permission>? permissoes,
    this.token,
    this.status = UserStatus.ativo,
    this.ultimoLogin,
    this.telefone,
    this.documento,
    this.orgaoInstituicao,
    this.dataCadastro,
  }) : permissoes = permissoes ??
            PermissionService.getPermissionsForRole(perfil).toList();

  /// Verifica se o usuário tem uma permissão específica.
  bool hasPermission(Permission permission) {
    return permissoes.contains(permission);
  }

  /// Cria uma cópia com campos alterados.
  UsuarioLocal copyWith({
    String? id,
    String? nome,
    String? email,
    UserRole? perfil,
    List<Permission>? permissoes,
    String? token,
    UserStatus? status,
    DateTime? ultimoLogin,
    String? telefone,
    String? documento,
    String? orgaoInstituicao,
    DateTime? dataCadastro,
  }) {
    return UsuarioLocal(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      perfil: perfil ?? this.perfil,
      permissoes: permissoes ?? this.permissoes,
      token: token ?? this.token,
      status: status ?? this.status,
      ultimoLogin: ultimoLogin ?? this.ultimoLogin,
      telefone: telefone ?? this.telefone,
      documento: documento ?? this.documento,
      orgaoInstituicao: orgaoInstituicao ?? this.orgaoInstituicao,
      dataCadastro: dataCadastro ?? this.dataCadastro,
    );
  }

  /// Converte para Map (para armazenamento local).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'perfil': perfil.code,
      'permissoes': permissoes.map((p) => p.code).toList(),
      'token': token,
      'status': status.code,
      'ultimoLogin': ultimoLogin?.toIso8601String(),
      'telefone': telefone,
      'documento': documento,
      'orgaoInstituicao': orgaoInstituicao,
      'dataCadastro': dataCadastro?.toIso8601String(),
    };
  }

  /// Cria a partir de um Map.
  factory UsuarioLocal.fromMap(Map<String, dynamic> map) {
    return UsuarioLocal(
      id: map['id'] as String,
      nome: map['nome'] as String,
      email: map['email'] as String,
      perfil: UserRole.fromCode(map['perfil'] as String),
      permissoes: (map['permissoes'] as List<dynamic>?)
              ?.map((p) => Permission.fromCode(p as String))
              .toList() ??
          [],
      token: map['token'] as String?,
      status: UserStatus.fromCode(map['status'] as String? ?? 'ATIVO'),
      ultimoLogin: map['ultimoLogin'] != null
          ? DateTime.parse(map['ultimoLogin'] as String)
          : null,
      telefone: map['telefone'] as String?,
      documento: map['documento'] as String?,
      orgaoInstituicao: map['orgaoInstituicao'] as String?,
      dataCadastro: map['dataCadastro'] != null
          ? DateTime.parse(map['dataCadastro'] as String)
          : null,
    );
  }
}

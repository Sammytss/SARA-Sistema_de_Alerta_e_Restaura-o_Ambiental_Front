import 'package:flutter/material.dart';
import '../user_role.dart';
import '../permission.dart';
import '../permission_service.dart';

/// Widget condicional que exibe conteúdo apenas se o usuário tem a permissão necessária.
///
/// Usado para ocultar/exibir botões, cards, seções inteiras de tela
/// com base nas permissões do perfil logado.
///
/// Exemplo:
/// ```dart
/// PermissionWidget(
///   role: currentUserRole,
///   permission: Permission.inspectionCreate,
///   child: ElevatedButton(...),
///   fallback: Text('Sem permissão'),
/// )
/// ```
class PermissionWidget extends StatelessWidget {
  /// O perfil atual do usuário.
  final UserRole role;

  /// A permissão necessária para exibir o [child].
  final Permission? permission;

  /// Lista de permissões — exibe se tiver TODAS.
  final List<Permission>? allPermissions;

  /// Lista de permissões — exibe se tiver QUALQUER UMA.
  final List<Permission>? anyPermissions;

  /// Widget a exibir quando o usuário tem permissão.
  final Widget child;

  /// Widget a exibir quando o usuário NÃO tem permissão (opcional).
  final Widget? fallback;

  const PermissionWidget({
    super.key,
    required this.role,
    this.permission,
    this.allPermissions,
    this.anyPermissions,
    required this.child,
    this.fallback,
  }) : assert(
         permission != null || allPermissions != null || anyPermissions != null,
         'Deve fornecer permission, allPermissions ou anyPermissions',
       );

  @override
  Widget build(BuildContext context) {
    final hasAccess = _checkPermission();

    if (hasAccess) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }

  bool _checkPermission() {
    if (permission != null) {
      return PermissionService.hasPermission(role, permission!);
    }
    if (allPermissions != null) {
      return PermissionService.hasAllPermissions(role, allPermissions!);
    }
    if (anyPermissions != null) {
      return PermissionService.hasAnyPermission(role, anyPermissions!);
    }
    return false;
  }
}

/// Widget que exibe conteúdo baseado em múltiplos perfis permitidos.
///
/// Exemplo:
/// ```dart
/// RoleWidget(
///   currentRole: userRole,
///   allowedRoles: [UserRole.gestor, UserRole.analista],
///   child: AdminPanel(),
/// )
/// ```
class RoleWidget extends StatelessWidget {
  final UserRole currentRole;
  final List<UserRole> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleWidget({
    super.key,
    required this.currentRole,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (allowedRoles.contains(currentRole)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}

import 'user_role.dart';
import 'permission.dart';

/// Serviço RBAC do SARA MVP.
/// 3 perfis ativos: Técnico (campo), Produtor (campo), Gestor (consolidação).
class PermissionService {
  PermissionService._();

  static Set<Permission> getPermissionsForRole(UserRole role) {
    switch (role) {
      case UserRole.publico:
        return _publicPermissions;
      case UserRole.produtor:
        return _produtorPermissions;
      case UserRole.tecnico:
        return _tecnicoPermissions;
      case UserRole.gestor:
        return _gestorPermissions;
      // Perfis pós-MVP — mesmas permissões de público enquanto não implementados
      case UserRole.analista:
      case UserRole.auditor:
      case UserRole.operario:
        return _publicPermissions;
    }
  }

  static bool hasPermission(UserRole role, Permission permission) {
    return getPermissionsForRole(role).contains(permission);
  }

  static bool hasAllPermissions(UserRole role, List<Permission> permissions) {
    final rolePermissions = getPermissionsForRole(role);
    return permissions.every((p) => rolePermissions.contains(p));
  }

  static bool hasAnyPermission(UserRole role, List<Permission> permissions) {
    final rolePermissions = getPermissionsForRole(role);
    return permissions.any((p) => rolePermissions.contains(p));
  }

  // ── Público ───────────────────────────────────────────────
  static final Set<Permission> _publicPermissions = {
    Permission.areaViewAggregated,
  };

  // ── Produtor: campo na própria propriedade ────────────────
  // Registra evidências, vê apenas suas áreas, não vê dados de terceiros.
  static final Set<Permission> _produtorPermissions = {
    Permission.areaViewAggregated,
    Permission.areaViewOwn,
    Permission.sensitiveDataViewOwn,
    Permission.evidenceCreate,
    Permission.syncOffline,
  };

  // ── Técnico: vistoria em campo nas áreas atribuídas ───────
  // Registra evidências, acessa dados sensíveis das áreas que cobre.
  static final Set<Permission> _tecnicoPermissions = {
    Permission.areaViewAggregated,
    Permission.areaViewAssigned,
    Permission.sensitiveDataView,
    Permission.evidenceCreate,
    Permission.syncOffline,
  };

  // ── Gestor: consolidação read-only + atribuição ───────────
  // Vê tudo, atribui áreas, não registra evidências diretamente.
  static final Set<Permission> _gestorPermissions = {
    Permission.areaViewAggregated,
    Permission.areaViewOwn,
    Permission.areaViewAssigned,
    Permission.areaViewAll,
    Permission.sensitiveDataView,
    Permission.sensitiveDataViewOwn,
    Permission.areaAssign,
    Permission.syncOffline,
  };
}

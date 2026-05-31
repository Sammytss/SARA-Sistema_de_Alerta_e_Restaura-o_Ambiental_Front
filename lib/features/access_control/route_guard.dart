import 'user_role.dart';

/// Guard de navegação por perfil para integração com GoRouter.
/// MVP: 3 perfis ativos — Técnico, Produtor, Gestor.
class RouteGuard {
  RouteGuard._();

  /// Rotas privadas e os perfis que podem acessá-las.
  static const Map<String, List<UserRole>> _routePermissions = {
    '/manager': [UserRole.gestor],
    '/technician': [UserRole.tecnico],
    '/producer': [UserRole.produtor],
  };

  /// Rota home de cada perfil.
  static const Map<UserRole, String> _roleHomeRoutes = {
    UserRole.gestor: '/manager',
    UserRole.tecnico: '/technician',
    UserRole.produtor: '/producer',
    UserRole.publico: '/public',
    // Pós-MVP: analista, auditor, operario mapeados para público temporariamente
    UserRole.analista: '/public',
    UserRole.auditor: '/public',
    UserRole.operario: '/public',
  };

  static String homeRouteForRole(UserRole role) {
    return _roleHomeRoutes[role] ?? '/';
  }

  static bool canAccess(UserRole role, String path) {
    final allowed = _routePermissions[path];
    if (allowed == null) return true;
    return allowed.contains(role);
  }

  static bool _isPublicPath(String path) {
    return path == '/' ||
        path == '/login' ||
        path == '/public' ||
        path.startsWith('/public/');
  }

  static String? redirect({
    required bool isAuthenticated,
    required UserRole role,
    required String path,
  }) {
    if (!isAuthenticated && !_isPublicPath(path)) {
      return '/login';
    }

    if (isAuthenticated && _routePermissions.containsKey(path)) {
      if (!canAccess(role, path)) {
        return homeRouteForRole(role);
      }
    }

    if (isAuthenticated && path == '/') {
      return homeRouteForRole(role);
    }

    return null;
  }
}

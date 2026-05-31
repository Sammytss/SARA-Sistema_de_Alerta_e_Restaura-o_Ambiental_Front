import 'package:flutter_test/flutter_test.dart';
import 'package:sara_app/features/access_control/user_role.dart';
import 'package:sara_app/features/access_control/permission.dart';
import 'package:sara_app/features/access_control/permission_service.dart';

void main() {
  group('PermissionService MVP', () {
    test('Público vê apenas dados agregados', () {
      final permissions = PermissionService.getPermissionsForRole(UserRole.publico);
      expect(permissions.contains(Permission.areaViewAggregated), true);
      expect(permissions.contains(Permission.sensitiveDataView), false);
      expect(permissions.contains(Permission.areaViewAll), false);
      expect(permissions.length, 1);
    });

    test('Técnico pode criar evidência e ver áreas atribuídas', () {
      expect(
        PermissionService.hasPermission(UserRole.tecnico, Permission.evidenceCreate),
        true,
      );
      expect(
        PermissionService.hasPermission(UserRole.tecnico, Permission.areaViewAssigned),
        true,
      );
      expect(
        PermissionService.hasPermission(UserRole.tecnico, Permission.areaViewAll),
        false,
      );
    });

    test('Técnico pode sincronizar offline', () {
      expect(
        PermissionService.hasPermission(UserRole.tecnico, Permission.syncOffline),
        true,
      );
    });

    test('Produtor vê apenas áreas próprias e pode criar evidência', () {
      expect(
        PermissionService.hasPermission(UserRole.produtor, Permission.areaViewOwn),
        true,
      );
      expect(
        PermissionService.hasPermission(UserRole.produtor, Permission.evidenceCreate),
        true,
      );
      expect(
        PermissionService.hasPermission(UserRole.produtor, Permission.areaViewAll),
        false,
      );
      expect(
        PermissionService.hasPermission(UserRole.produtor, Permission.sensitiveDataView),
        false,
      );
    });

    test('Gestor vê todas as áreas mas não registra evidência', () {
      expect(
        PermissionService.hasPermission(UserRole.gestor, Permission.areaViewAll),
        true,
      );
      expect(
        PermissionService.hasPermission(UserRole.gestor, Permission.areaAssign),
        true,
      );
      expect(
        PermissionService.hasPermission(UserRole.gestor, Permission.evidenceCreate),
        false,
      );
    });

    test('Gestor tem acesso a dados sensíveis', () {
      expect(
        PermissionService.hasPermission(UserRole.gestor, Permission.sensitiveDataView),
        true,
      );
    });
  });
}

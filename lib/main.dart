import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/services/notification_service.dart';
import 'features/auth/auth_provider.dart';

/// Entry point do SARA APP.
/// Inicializa banco local, sessão de auth e serviço de notificações antes de montar a UI.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().initialize();

  final container = ProviderContainer();
  await Future.wait([
    container.read(appDatabaseProvider).initialize(),
    container.read(authProvider.notifier).initialize(),
  ]);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SaraApp(),
    ),
  );
}

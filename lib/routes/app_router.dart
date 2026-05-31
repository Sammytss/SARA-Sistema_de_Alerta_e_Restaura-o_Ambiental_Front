import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/widgets/authenticated_shell.dart';
import '../features/public/screens/public_home_screen.dart';
import '../features/home/screens/manager_home_screen.dart';
import '../features/home/screens/technician_home_screen.dart';
import '../features/home/screens/role_home_screen.dart';
import '../features/access_control/route_guard.dart';
import '../features/public/screens/public_map_screen.dart';
import '../features/public/screens/public_indicators_screen.dart';
import '../features/public/screens/public_alerts_screen.dart';
import '../features/public/screens/about_sara_screen.dart';
import '../features/public/screens/environmental_education_screen.dart';
import '../features/alerts/screens/alerts_screen.dart';
import '../features/alerts/screens/area_alerts_screen.dart';
import '../features/areas/screens/area_detail_screen.dart';
import '../features/areas/screens/demarcate_area_screen.dart';
import '../features/evidence/screens/capture_evidence_screen.dart';
import '../features/manager/screens/manager_map_screen.dart';
import '../features/satellite/screens/satellite_timeline_screen.dart';
import '../features/sync/screens/sync_queue_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,

    redirect: (context, state) => RouteGuard.redirect(
      isAuthenticated: authState.isAuthenticated,
      role: authState.currentRole,
      path: state.uri.path,
    ),

    routes: [
      // ── Welcome ──────────────────────────────────────────────
      GoRoute(
        path: '/',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // ── Login ────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Módulo Público ───────────────────────────────────────
      GoRoute(
        path: '/public',
        name: 'public',
        builder: (context, state) => const PublicHomeScreen(),
        routes: [
          GoRoute(
            path: 'map',
            name: 'public-map',
            builder: (context, state) => const PublicMapScreen(),
          ),
          GoRoute(
            path: 'indicators',
            name: 'public-indicators',
            builder: (context, state) => const PublicIndicatorsScreen(),
          ),
          GoRoute(
            path: 'alerts',
            name: 'public-alerts',
            builder: (context, state) => const PublicAlertsScreen(),
          ),
          GoRoute(
            path: 'about',
            name: 'about-sara',
            builder: (context, state) => const AboutSaraScreen(),
          ),
          GoRoute(
            path: 'education',
            name: 'environmental-education',
            builder: (context, state) => const EnvironmentalEducationScreen(),
          ),
        ],
      ),

      // ── Rotas full-page (com próprio AppBar, fora do Shell) ──
      GoRoute(
        path: '/area/:id',
        name: 'area-detail',
        builder: (context, state) => AreaDetailScreen(
          areaId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'capture',
            name: 'capture-evidence',
            builder: (context, state) => CaptureEvidenceScreen(
              areaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'demarcate',
            name: 'demarcate-area',
            builder: (context, state) => DemarcateAreaScreen(
              areaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'alerts',
            name: 'area-alerts',
            builder: (context, state) => AreaAlertsScreen(
              areaId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'satellite',
            name: 'satellite-timeline',
            builder: (context, state) => SatelliteTimelineScreen(
              areaId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/alerts',
        name: 'alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/manager/map',
        name: 'manager-map',
        builder: (context, state) => const ManagerMapScreen(),
      ),
      GoRoute(
        path: '/sync',
        name: 'sync-queue',
        builder: (context, state) => const SyncQueueScreen(),
      ),

      // ── Rotas autenticadas (com Shell: AppBar de perfil + logout) ─
      ShellRoute(
        builder: (context, state, child) => AuthenticatedShell(child: child),
        routes: [
          GoRoute(
            path: '/manager',
            name: 'manager',
            builder: (context, state) => const ManagerHomeScreen(),
          ),
          GoRoute(
            path: '/technician',
            name: 'technician',
            builder: (context, state) => const TechnicianHomeScreen(),
          ),
          GoRoute(
            path: '/producer',
            name: 'producer',
            builder: (context, state) => RoleHomeScreen.produtor(),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Página não encontrada',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.path,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    ),
  );
});

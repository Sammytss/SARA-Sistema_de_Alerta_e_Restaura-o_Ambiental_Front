import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/alerta.dart';

/// Serviço de notificações locais para alertas de fogo e desmatamento.
///
/// Suportado em Android, iOS e macOS. No-op em Windows e Web.
/// Chame [initialize] uma vez no boot antes de [notificarAlerta].
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  /// IDs de alertas já notificados nesta sessão — evita duplicatas.
  final _notifiedIds = <String>{};

  bool _initialized = false;

  bool get _isSupported =>
      !kIsWeb &&
      (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isLinux);

  Future<void> initialize() async {
    if (!_isSupported) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Abrir SARA');

    final initSettings = InitializationSettings(
      android: Platform.isAndroid ? androidSettings : null,
      iOS: Platform.isIOS ? darwinSettings : null,
      macOS: Platform.isMacOS ? darwinSettings : null,
      linux: Platform.isLinux ? linuxSettings : null,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Mostra notificação para um [alerta] de alta ou crítica severidade,
  /// apenas se ainda não foi notificado nesta sessão e está não lido.
  Future<void> notificarAlerta(Alerta alerta) async {
    if (!_initialized) return;
    if (_notifiedIds.contains(alerta.id)) return;
    if (alerta.lido) return;
    if (alerta.severidade != AlertaSeveridade.critica &&
        alerta.severidade != AlertaSeveridade.alta) {
      return;
    }

    _notifiedIds.add(alerta.id);

    const androidDetails = AndroidNotificationDetails(
      'sara_alertas',
      'Alertas SARA',
      channelDescription: 'Alertas ambientais — fogo e desmatamento próximos a áreas monitoradas',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final titulo = alerta.severidade == AlertaSeveridade.critica
        ? '🔴 CRÍTICO: ${alerta.tipo.displayName}'
        : '🟠 ALERTA: ${alerta.tipo.displayName}';

    final corpo = '${alerta.fonte.displayName}'
        '${alerta.distanciaMetros != null ? " • ${_formatDist(alerta.distanciaMetros!)}" : ""}';

    await _plugin.show(
      // ID único por alerta (hashCode do id string, truncado a 6 dígitos)
      alerta.id.hashCode.abs() % 1000000,
      titulo,
      corpo,
      details,
    );
  }

  /// Itera uma lista de alertas e notifica os que qualificam.
  Future<void> notificarPendentes(List<Alerta> alertas) async {
    for (final a in alertas) {
      await notificarAlerta(a);
    }
  }

  String _formatDist(double m) => m >= 1000
      ? '${(m / 1000).toStringAsFixed(1)} km da área'
      : '${m.toStringAsFixed(0)} m da área';
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Servicio simple para notificaciones locales.
/// Usado para el Reto 1: notificar al llegar a 30 pasos.
class LocalNotificationsService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> showStepGoalReached({
    required int steps,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'steps_channel',
      'Steps',
      channelDescription: 'Notificaciones de metas de pasos',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1,
      '¡Meta alcanzada!',
      'Has superado $steps pasos 🎉',
      details,
    );
  }

  Future<void> showFallDetected() async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'fall_channel',
      'Fall Detection',
      channelDescription: 'Alertas de caídas',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      2,
      '⚠️ Posible caída detectada',
      'Se detectó un pico de aceleración alto. Revisa tu estado.',
      details,
    );
  }
}

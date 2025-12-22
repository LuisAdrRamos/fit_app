import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  // Singleton para usar la misma instancia en toda la app
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Configuración para Android (Icono por defecto del sistema)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showStepGoalNotification() async {
    // Pedir permiso en Android 13+ (si no se tiene)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'fitness_goals_channel', // Id del canal
          'Metas de Fitness', // Nombre del canal
          channelDescription: 'Notificaciones al alcanzar metas de pasos',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      0, // ID de la notificación
      '¡Felicitaciones! 🎉', // Título
      'Has alcanzado tu meta de 30 pasos. ¡Sigue así!', // Cuerpo
      platformChannelSpecifics,
    );
  }
}

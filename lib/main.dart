import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'core/notifications/local_notifications_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initServiceLocator();

  // Inicializa notificaciones (necesario para retos)
  await sl<LocalNotificationsService>().init();

  runApp(const FitnessApp());
}

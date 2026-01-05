import 'package:get_it/get_it.dart';

import '../notifications/local_notifications_service.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/domain/usecases/authenticate_user.dart';
import '../../features/location/data/location_repository_impl.dart';
import '../../features/location/domain/location_repository.dart';
import '../../features/location/domain/usecases/start_location_stream.dart';
import '../../features/location/domain/usecases/stop_location_stream.dart';
import '../../features/steps/data/steps_repository_impl.dart';
import '../../features/steps/domain/steps_repository.dart';
import '../../features/steps/domain/usecases/start_sensors.dart';
import '../../features/steps/domain/usecases/stop_sensors.dart';

final sl = GetIt.instance;

/// Registrar dependencias (DI)
Future<void> initServiceLocator() async {
  // Services
  sl.registerLazySingleton<LocalNotificationsService>(
    () => LocalNotificationsService(),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerLazySingleton<LocationRepository>(() => LocationRepositoryImpl());
  sl.registerLazySingleton<StepsRepositoryImpl>(() => StepsRepositoryImpl());
  sl.registerLazySingleton<StepsRepository>(() => sl<StepsRepositoryImpl>());

  // Usecases
  sl.registerLazySingleton(() => AuthenticateUser(sl<AuthRepository>()));

  sl.registerLazySingleton(() => StartLocationStream(sl<LocationRepository>()));
  sl.registerLazySingleton(() => StopLocationStream(sl<LocationRepository>()));

  sl.registerLazySingleton(() => StartSensors(sl<StepsRepository>()));
  sl.registerLazySingleton(() => StopSensors(sl<StepsRepository>()));
}

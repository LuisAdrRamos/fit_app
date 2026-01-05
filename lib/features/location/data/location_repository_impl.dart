import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../domain/entities/location_point.dart';
import '../domain/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  StreamSubscription<Position>? _sub;

  @override
  Future<bool> ensurePermissionsAndService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) return false;
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  @override
  Stream<LocationPoint> locationStream() async* {
    final ok = await ensurePermissionsAndService();
    if (!ok) {
      throw Exception('Permisos GPS o servicio desactivado');
    }

    final controller = StreamController<LocationPoint>();

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 2, // metros
      ),
    ).listen((pos) {
      controller.add(
        LocationPoint(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          speed: pos.speed,
          timestamp: DateTime.now(),
        ),
      );
    }, onError: controller.addError);

    yield* controller.stream;
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }
}

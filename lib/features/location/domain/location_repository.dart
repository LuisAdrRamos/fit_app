import 'entities/location_point.dart';

abstract class LocationRepository {
  Stream<LocationPoint> locationStream();
  Future<bool> ensurePermissionsAndService();
  Future<void> stop();
}

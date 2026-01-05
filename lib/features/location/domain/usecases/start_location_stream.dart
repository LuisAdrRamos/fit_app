import '../location_repository.dart';
import '../entities/location_point.dart';

class StartLocationStream {
  final LocationRepository _repo;
  StartLocationStream(this._repo);

  Stream<LocationPoint> call() => _repo.locationStream();
}

import '../location_repository.dart';

class StopLocationStream {
  final LocationRepository _repo;
  StopLocationStream(this._repo);

  Future<void> call() => _repo.stop();
}

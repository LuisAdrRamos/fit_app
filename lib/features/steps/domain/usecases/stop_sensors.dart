import '../steps_repository.dart';

class StopSensors {
  final StepsRepository _repo;
  StopSensors(this._repo);

  Future<void> call() => _repo.stop();
}

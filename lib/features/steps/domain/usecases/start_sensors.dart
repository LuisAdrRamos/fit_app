import '../steps_repository.dart';

class StartSensors {
  final StepsRepository _repo;
  StartSensors(this._repo);

  Future<void> call() => _repo.start();
}

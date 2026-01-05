import 'entities/step_metrics.dart';

abstract class StepsRepository {
  Stream<StepMetrics> metricsStream();
  Future<void> start();
  Future<void> stop();
}

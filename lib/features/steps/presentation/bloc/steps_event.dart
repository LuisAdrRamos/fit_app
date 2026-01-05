part of 'steps_bloc.dart';

sealed class StepsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

final class StepsStarted extends StepsEvent {}
final class StepsStopped extends StepsEvent {}

final class _MetricsArrived extends StepsEvent {
  final StepMetrics metrics;
  _MetricsArrived(this.metrics);

  @override
  List<Object?> get props => [metrics];
}

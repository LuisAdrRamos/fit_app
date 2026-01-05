part of 'steps_bloc.dart';

enum StepsStatus { initial, tracking, stopped, error }

class StepsState extends Equatable {
  final StepsStatus status;
  final StepMetrics metrics;
  final String? error;
  final bool goalNotified;

  const StepsState({
    required this.status,
    required this.metrics,
    this.error,
    required this.goalNotified,
  });

  const StepsState.initial()
      : this(
          status: StepsStatus.initial,
          metrics: const StepMetrics(
            stepCount: 0,
            magnitudeAvg: 0,
            activityType: ActivityType.stationary,
            fallDetected: false,
          ),
          goalNotified: false,
        );

  StepsState copyWith({
    StepsStatus? status,
    StepMetrics? metrics,
    String? error,
    bool? goalNotified,
  }) {
    return StepsState(
      status: status ?? this.status,
      metrics: metrics ?? this.metrics,
      error: error,
      goalNotified: goalNotified ?? this.goalNotified,
    );
  }

  @override
  List<Object?> get props => [status, metrics, error, goalNotified];
}

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/notifications/local_notifications_service.dart';
import '../../domain/entities/step_metrics.dart';
import '../../domain/usecases/start_sensors.dart';
import '../../domain/usecases/stop_sensors.dart';

part 'steps_event.dart';
part 'steps_state.dart';

class StepsBloc extends Bloc<StepsEvent, StepsState> {
  final StartSensors startSensors;
  final StopSensors stopSensors;
  final Stream<StepMetrics> metricsStream;
  final LocalNotificationsService notifications;

  StreamSubscription<StepMetrics>? _sub;
  bool _goalNotified = false;

  StepsBloc({
    required this.startSensors,
    required this.stopSensors,
    required this.metricsStream,
    required this.notifications,
  }) : super(const StepsState.initial()) {
    on<StepsStarted>(_onStart);
    on<StepsStopped>(_onStop);
    on<_MetricsArrived>(_onMetrics);
  }

  Future<void> _onStart(StepsStarted event, Emitter<StepsState> emit) async {
    emit(state.copyWith(status: StepsStatus.tracking, error: null, goalNotified: false));
    _goalNotified = false;

    await startSensors();
    await _sub?.cancel();
    _sub = metricsStream.listen(
      (m) => add(_MetricsArrived(m)),
      onError: (e) => emit(state.copyWith(status: StepsStatus.error, error: e.toString())),
    );
  }

  Future<void> _onStop(StepsStopped event, Emitter<StepsState> emit) async {
    await _sub?.cancel();
    _sub = null;
    await stopSensors();
    emit(state.copyWith(status: StepsStatus.stopped));
  }

  Future<void> _onMetrics(_MetricsArrived event, Emitter<StepsState> emit) async {
    final m = event.metrics;

    // Reto 1: Notificación a los 30 pasos
    if (!_goalNotified && m.stepCount >= 30) {
      _goalNotified = true;
      await notifications.showStepGoalReached(steps: m.stepCount);
      emit(state.copyWith(goalNotified: true));
    }

    // Reto 2: Caída detectada
    if (m.fallDetected) {
      await notifications.showFallDetected();
    }

    emit(state.copyWith(metrics: m));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await stopSensors();
    return super.close();
  }
}

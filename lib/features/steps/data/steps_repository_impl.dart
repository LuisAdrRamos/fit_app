import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../domain/entities/step_metrics.dart';
import '../domain/steps_repository.dart';

class StepsRepositoryImpl implements StepsRepository {
  StreamSubscription<AccelerometerEvent>? _sub;

  final _controller = StreamController<StepMetrics>.broadcast();

  // Estado interno
  int _steps = 0;
  double _lastMagnitude = 0;
  bool _running = false;

  // Suavizado
  final List<double> _history = [];
  static const int _historySize = 10;

  // Para evitar falsos positivos de pasos
  DateTime _lastStepTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Fall detection
  bool _fallDetected = false;
  DateTime _lastFallTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Stream<StepMetrics> metricsStream() => _controller.stream;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;
    _steps = 0;
    _fallDetected = false;
    _history.clear();
    _lastMagnitude = 0;

    _sub = accelerometerEvents.listen((e) {
      // Magnitud (m/s^2), incluye gravedad.
      final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

      _history.add(mag);
      if (_history.length > _historySize) _history.removeAt(0);
      final avg = _history.isEmpty ? mag : _history.reduce((a, b) => a + b) / _history.length;

      // Activity heuristic
      final activity = avg < 10.5
          ? ActivityType.stationary
          : (avg < 13.5 ? ActivityType.walking : ActivityType.running);

      // Paso: cruce de umbral + debounce
      final now = DateTime.now();
      const stepThreshold = 12.0; // ajustable
      if (mag > stepThreshold && _lastMagnitude <= stepThreshold) {
        if (now.difference(_lastStepTime).inMilliseconds > 280) {
          _steps++;
          _lastStepTime = now;
        }
      }
      _lastMagnitude = mag;

      // Reto 2: Caídas (pico > 25 m/s^2) con cooldown
      const fallPeak = 25.0;
      const cooldownMs = 3000;
      if (mag >= fallPeak && now.difference(_lastFallTime).inMilliseconds > cooldownMs) {
        _fallDetected = true;
        _lastFallTime = now;
      }

      _controller.add(
        StepMetrics(
          stepCount: _steps,
          magnitudeAvg: avg,
          activityType: activity,
          fallDetected: _fallDetected,
        ),
      );

      // Reset bandera de caída después de un ratito (UI)
      if (_fallDetected && now.difference(_lastFallTime).inMilliseconds > 1500) {
        _fallDetected = false;
      }
    }, onError: _controller.addError);
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _sub?.cancel();
    _sub = null;
  }
}

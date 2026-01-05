enum ActivityType { stationary, walking, running }

class StepMetrics {
  final int stepCount;
  final double magnitudeAvg;
  final ActivityType activityType;
  final bool fallDetected;

  const StepMetrics({
    required this.stepCount,
    required this.magnitudeAvg,
    required this.activityType,
    required this.fallDetected,
  });

  double get calories => stepCount * 0.04;
}

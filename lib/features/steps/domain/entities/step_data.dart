import 'package:equatable/equatable.dart';

/// Tipos de actividad detectados
enum ActivityType {
  stationary, // Quieto
  walking, // Caminando
  running, // Corriendo
}

/// Datos del acelerómetro procesados
class StepData extends Equatable {
  final int stepCount;
  final ActivityType activityType;
  final double magnitude;

  const StepData({
    required this.stepCount,
    required this.activityType,
    required this.magnitude,
  });

  /// Calorías estimadas (aprox 0.04 cal por paso promedio)
  double get estimatedCalories => stepCount * 0.04;

  /// Factory para convertir el Map que nos envía Android a un objeto Dart
  factory StepData.fromMap(Map<dynamic, dynamic> map) {
    final activityTypeString = map['activityType'] as String;

    return StepData(
      stepCount: map['stepCount'] as int,
      activityType: _parseActivityType(activityTypeString),
      magnitude: (map['magnitude'] as num).toDouble(),
    );
  }

  static ActivityType _parseActivityType(String type) {
    switch (type) {
      case 'walking':
        return ActivityType.walking;
      case 'running':
        return ActivityType.running;
      default:
        return ActivityType.stationary;
    }
  }

  @override
  List<Object> get props => [stepCount, activityType, magnitude];
}

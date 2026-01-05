import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/steps_bloc.dart';
import '../../domain/entities/step_metrics.dart';

class StepsCard extends StatelessWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<StepsBloc, StepsState>(
          builder: (context, state) {
            final tracking = state.status == StepsStatus.tracking;
            final m = state.metrics;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sensores (sensors_plus)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<StepsBloc>().add(tracking ? StepsStopped() : StepsStarted());
                      },
                      icon: Icon(tracking ? Icons.stop : Icons.play_arrow),
                      label: Text(tracking ? 'Detener' : 'Iniciar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (state.status == StepsStatus.error && state.error != null)
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
                Row(
                  children: [
                    Expanded(
                      child: _bigNumber(title: 'Pasos', value: '${m.stepCount}'),
                    ),
                    Expanded(
                      child: _bigNumber(
                        title: 'Calorías',
                        value: m.calories.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _chip(
                      icon: _activityIcon(m.activityType),
                      label: _activityLabel(m.activityType),
                    ),
                    _chip(
                      icon: Icons.show_chart,
                      label: 'Mag: ${m.magnitudeAvg.toStringAsFixed(1)}',
                    ),
                    _chip(
                      icon: Icons.notifications_active,
                      label: state.goalNotified ? 'Meta 30: ✅' : 'Meta 30: —',
                    ),
                    _chip(
                      icon: Icons.warning_amber_rounded,
                      label: m.fallDetected ? 'Caída: ⚠️' : 'Caída: —',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Reto 1: notificación al superar 30 pasos.'
                  'Reto 2: posible caída si magnitud > 25 m/s².',
                  style: TextStyle(color: Colors.black54),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bigNumber({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }

  IconData _activityIcon(ActivityType t) {
    switch (t) {
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.stationary:
        return Icons.accessibility_new;
    }
  }

  String _activityLabel(ActivityType t) {
    switch (t) {
      case ActivityType.walking:
        return 'Caminando';
      case ActivityType.running:
        return 'Corriendo';
      case ActivityType.stationary:
        return 'Quieto';
    }
  }
}

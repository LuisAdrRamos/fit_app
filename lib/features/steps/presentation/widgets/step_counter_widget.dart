import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/datasources/accelerometer_datasource.dart';
import '../../domain/entities/step_data.dart';
import '../../../../core/platform/notification_service.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  // Instanciamos el DataSource directamente (podría inyectarse, pero por simplicidad lo hacemos aquí)
  final AccelerometerDataSource _dataSource = AccelerometerDataSourceImpl();

  // La suscripción al stream para poder cancelarla después
  StreamSubscription<StepData>? _subscription;

  // Estado local para la UI
  StepData? _currentData;
  bool _isTracking = false;

  @override
  void dispose() {
    // IMPORTANTE: Siempre cancelar streams al cerrar el widget para evitar fugas de memoria
    _subscription?.cancel();
    super.dispose();
  }

  void _toggleTracking() {
    if (_isTracking) {
      _stopTracking();
    } else {
      _startTracking();
    }
  }

  void _startTracking() async {
    // 1. Pedir permisos antes de empezar
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se necesitan permisos de actividad física para contar pasos',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Iniciar el servicio en Android
    await _dataSource.startCounting();

    // 3. Suscribirse al stream de datos (EventChannel)
    _subscription = _dataSource.stepStream.listen(
      (data) {
        setState(() {
          _currentData = data;
        });

        // --- LÓGICA DEL RETO 1 ---
        // Si los pasos superan 30 (y para no spamear, hazlo solo una vez o cada X pasos)
        if (data.stepCount == 30) {
          NotificationService().showStepGoalNotification();
        }

        // --- RETO 2: ALERTA DE CAÍDA ---
        if (data.isFall) {
          _showFallAlert();
        }
      },
      onError: (error) {
        print('Error recibiendo pasos: $error');
      },
    );

    setState(() {
      _isTracking = true;
    });
  }

  void _stopTracking() async {
    await _dataSource.stopCounting();
    _subscription?.cancel();
    setState(() {
      _isTracking = false;
    });
  }

  void _showFallAlert() {
    // 1. Mostrar Notificación del Sistema
    // (Podrías crear un método específico en NotificationService si quieres cambiar el texto)
    NotificationService().showStepGoalNotification(); // Reusamos por simplicidad o crea uno nuevo

    // 2. Mostrar Diálogo de Alerta en la App (SnackBar roja)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('¡CAÍDA DETECTADA! ¿Estás bien?'),
            ],
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header del Card
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Contador de Pasos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _toggleTracking,
                  icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
                  label: Text(_isTracking ? 'Detener' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // Número gigante de pasos
            Text(
              '${_currentData?.stepCount ?? 0}',
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const Text(
              'pasos',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // Chips de información (Actividad y Calorías)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoChip(
                  icon: _getActivityIcon(_currentData?.activityType),
                  label: _getActivityLabel(_currentData?.activityType),
                  color: Colors.blue,
                ),
                _buildInfoChip(
                  icon: Icons.local_fire_department,
                  label:
                      '${_currentData?.estimatedCalories.toStringAsFixed(1) ?? "0"} cal',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper para construir las etiquetas de colores
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.stationary:
        return Icons.accessibility_new;
      default:
        return Icons.help_outline;
    }
  }

  String _getActivityLabel(ActivityType? type) {
    switch (type) {
      case ActivityType.walking:
        return 'Caminando';
      case ActivityType.running:
        return 'Corriendo';
      case ActivityType.stationary:
        return 'Quieto';
      default:
        return '---';
    }
  }
}

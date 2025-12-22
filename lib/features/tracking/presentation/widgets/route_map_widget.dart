import 'package:flutter/material.dart' hide Route; // Ocultamos Route de Flutter para usar la nuestra
import 'dart:async';
import '../../data/datasources/gps_datasource.dart';
import '../../domain/entities/location_point.dart';

class RouteMapWidget extends StatefulWidget {
  const RouteMapWidget({super.key});

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  final GpsDataSource _dataSource = GpsDataSourceImpl();
  
  // Nuestra entidad Route que acumula puntos
  final Route _route = Route();
  
  StreamSubscription<LocationPoint>? _subscription;
  bool _isTracking = false;
  String _statusMessage = 'Presiona Iniciar';

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _stopTracking();
    } else {
      await _startTracking();
    }
  }

  Future<void> _startTracking() async {
    // 1. Pedir Permisos
    final hasPermission = await _dataSource.requestPermissions();
    if (!hasPermission) {
      setState(() {
        _statusMessage = 'Permisos denegados';
      });
      return;
    }

    // 2. Verificar si el GPS está prendido
    final gpsEnabled = await _dataSource.isGpsEnabled();
    if (!gpsEnabled) {
      setState(() {
        _statusMessage = 'Enciende tu GPS por favor';
      });
      return;
    }

    // 3. Escuchar el stream
    _subscription = _dataSource.locationStream.listen(
      (point) {
        // Solo agregamos el punto si nos movimos al menos 2 metros para evitar ruido
        if (_route.points.isEmpty) {
          setState(() {
            _route.addPoint(point);
            _statusMessage = 'Rastreando...';
          });
        } else {
          final lastPoint = _route.points.last;
          final distance = lastPoint.distanceTo(point);
          
          if (distance >= 2) {
            setState(() {
              _route.addPoint(point);
            });
          }
        }
      },
      onError: (error) {
        setState(() {
          _statusMessage = 'Error GPS: $error';
        });
      },
    );

    setState(() {
      _isTracking = true;
      _statusMessage = 'Buscando satélites...';
    });
  }

  void _stopTracking() {
    _subscription?.cancel();
    _route.finish();
    setState(() {
      _isTracking = false;
      _statusMessage = 'Ruta finalizada';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ruta GPS',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isTracking ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
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
          ),

          // EL MAPA (CANVAS)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: RoutePainter(route: _route),
                size: Size.infinite,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Métricas (Distancia, Tiempo, Velocidad)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetric(
                  icon: Icons.straighten,
                  value: '${_route.distanceKm.toStringAsFixed(2)} km',
                  label: 'Distancia',
                ),
                _buildMetric(
                  icon: Icons.timer,
                  value: _formatDuration(_route.duration),
                  label: 'Tiempo',
                ),
                _buildMetric(
                  icon: Icons.speed,
                  value: '${_route.averageSpeed.toStringAsFixed(1)} km/h',
                  label: 'Velocidad',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// PINTOR: Dibuja la línea azul basada en las coordenadas
class RoutePainter extends CustomPainter {
  final Route route;
  RoutePainter({required this.route});

  @override
  void paint(Canvas canvas, Size size) {
    if (route.points.isEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'Sin datos de ruta',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
      );
      return;
    }

    // Calcular límites (bounding box) para escalar el dibujo al tamaño del contenedor
    double minLat = route.points.first.latitude;
    double maxLat = route.points.first.latitude;
    double minLon = route.points.first.longitude;
    double maxLon = route.points.first.longitude;

    for (final point in route.points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    final padding = 20.0;
    final drawWidth = size.width - padding * 2;
    final drawHeight = size.height - padding * 2;

    // Función para convertir Lat/Lon a Pixeles X/Y
    Offset toPixel(LocationPoint point) {
      final latRange = maxLat - minLat;
      final lonRange = maxLon - minLon;

      final x = lonRange == 0
          ? drawWidth / 2
          : ((point.longitude - minLon) / lonRange) * drawWidth;
          
      final y = latRange == 0
          ? drawHeight / 2
          : ((maxLat - point.latitude) / latRange) * drawHeight;

      return Offset(x + padding, y + padding);
    }

    // Configuración del lápiz
    final linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dibujar el camino
    final path = Path();
    path.moveTo(toPixel(route.points.first).dx, toPixel(route.points.first).dy);
    
    for (int i = 1; i < route.points.length; i++) {
      final pixel = toPixel(route.points[i]);
      path.lineTo(pixel.dx, pixel.dy);
    }
    
    canvas.drawPath(path, linePaint);

    // Dibujar punto de inicio (Verde)
    canvas.drawCircle(toPixel(route.points.first), 6, Paint()..color = Colors.green);
    // Dibujar punto actual (Rojo)
    canvas.drawCircle(toPixel(route.points.last), 6, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(RoutePainter oldDelegate) => true;
}
import 'package:flutter/material.dart';

import '../../domain/entities/location_point.dart';

class RouteCanvas extends StatelessWidget {
  final List<LocationPoint> points;
  const RouteCanvas({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _RoutePainter(points),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<LocationPoint> points;
  _RoutePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(text: 'Sin ruta aún', style: TextStyle(color: Colors.grey)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }

    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLon = points.first.longitude, maxLon = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }

    const padding = 18.0;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;

    Offset toPixel(LocationPoint p) {
      final latRange = maxLat - minLat;
      final lonRange = maxLon - minLon;
      final x = lonRange == 0 ? w / 2 : ((p.longitude - minLon) / lonRange) * w;
      final y = latRange == 0 ? h / 2 : ((maxLat - p.latitude) / latRange) * h;
      return Offset(x + padding, y + padding);
    }

    final paintLine = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(toPixel(points.first).dx, toPixel(points.first).dy);
    for (int i = 1; i < points.length; i++) {
      final px = toPixel(points[i]);
      path.lineTo(px.dx, px.dy);
    }
    canvas.drawPath(path, paintLine);

    final startPaint = Paint()..color = Colors.green;
    final endPaint = Paint()..color = Colors.red;
    canvas.drawCircle(toPixel(points.first), 7, startPaint);
    canvas.drawCircle(toPixel(points.last), 7, endPaint);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.points.length != points.length;
}

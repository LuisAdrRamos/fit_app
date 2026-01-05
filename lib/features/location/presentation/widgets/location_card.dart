import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/location_bloc.dart';
import 'route_canvas.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            final tracking = state.status == LocationStatus.tracking;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ruta GPS (geolocator)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<LocationBloc>().add(
                              tracking ? LocationStopped() : LocationStarted(),
                            );
                      },
                      icon: Icon(tracking ? Icons.stop : Icons.play_arrow),
                      label: Text(tracking ? 'Detener' : 'Iniciar'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (state.status == LocationStatus.error && state.error != null)
                  Text(state.error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 10),
                RouteCanvas(points: state.points),
                const SizedBox(height: 10),
                Text('Puntos: ${state.points.length}'),
                if (state.points.isNotEmpty)
                  Text(
                    'Último: ${state.points.last.latitude.toStringAsFixed(5)}, '
                    '${state.points.last.longitude.toStringAsFixed(5)} '
                    '(±${state.points.last.accuracy.toStringAsFixed(0)}m)',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

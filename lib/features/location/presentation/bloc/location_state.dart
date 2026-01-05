part of 'location_bloc.dart';

enum LocationStatus { initial, tracking, stopped, error }

class LocationState extends Equatable {
  final LocationStatus status;
  final List<LocationPoint> points;
  final String? error;

  const LocationState({
    required this.status,
    required this.points,
    this.error,
  });

  const LocationState.initial() : this(status: LocationStatus.initial, points: const []);

  LocationState copyWith({
    LocationStatus? status,
    List<LocationPoint>? points,
    String? error,
  }) {
    return LocationState(
      status: status ?? this.status,
      points: points ?? this.points,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, points, error];
}

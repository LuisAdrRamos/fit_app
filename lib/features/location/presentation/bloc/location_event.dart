part of 'location_bloc.dart';

sealed class LocationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

final class LocationStarted extends LocationEvent {}
final class LocationStopped extends LocationEvent {}

final class _LocationPointArrived extends LocationEvent {
  final LocationPoint point;
  _LocationPointArrived(this.point);

  @override
  List<Object?> get props => [point];
}

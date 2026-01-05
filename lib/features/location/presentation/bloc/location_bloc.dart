import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/location_point.dart';
import '../../domain/usecases/start_location_stream.dart';
import '../../domain/usecases/stop_location_stream.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final StartLocationStream startStream;
  final StopLocationStream stopStream;

  StreamSubscription<LocationPoint>? _sub;

  LocationBloc(this.startStream, this.stopStream) : super(const LocationState.initial()) {
    on<LocationStarted>(_onStarted);
    on<LocationStopped>(_onStopped);
    on<_LocationPointArrived>(_onPoint);
  }

  Future<void> _onStarted(LocationStarted event, Emitter<LocationState> emit) async {
    emit(state.copyWith(status: LocationStatus.tracking, error: null));

    await _sub?.cancel();
    _sub = startStream().listen(
      (p) => add(_LocationPointArrived(p)),
      onError: (e) => emit(state.copyWith(status: LocationStatus.error, error: e.toString())),
    );
  }

  Future<void> _onStopped(LocationStopped event, Emitter<LocationState> emit) async {
    await _sub?.cancel();
    _sub = null;
    await stopStream();
    emit(state.copyWith(status: LocationStatus.stopped));
  }

  void _onPoint(_LocationPointArrived event, Emitter<LocationState> emit) {
    final points = List<LocationPoint>.from(state.points);
    if (points.isEmpty) {
      points.add(event.point);
      emit(state.copyWith(points: points));
      return;
    }

    final last = points.last;
    if (last.distanceTo(event.point) >= 2) {
      points.add(event.point);
      emit(state.copyWith(points: points));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await stopStream();
    return super.close();
  }
}

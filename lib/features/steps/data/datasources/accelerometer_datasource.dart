import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/platform/platform_channels.dart';
import '../../domain/entities/step_data.dart';

abstract class AccelerometerDataSource {
  Stream<StepData> get stepStream;
  Future<void> startCounting();
  Future<void> stopCounting();
  Future<bool> requestPermissions();
}

class AccelerometerDataSourceImpl implements AccelerometerDataSource {
  /// EventChannel: Tubería por donde Android nos mandará datos continuamente
  final EventChannel _eventChannel = const EventChannel(
    PlatformChannels.accelerometer,
  );

  /// MethodChannel auxiliar: Solo para decirle a Android "Enciende" o "Apaga" el sensor
  final MethodChannel _methodChannel = const MethodChannel(
    '${PlatformChannels.accelerometer}/control',
  );

  @override
  Stream<StepData> get stepStream {
    /// receiveBroadcastStream(): Abre la llave del grifo
    return _eventChannel.receiveBroadcastStream().map((event) {
      // Convertimos cada gota de agua (Map) en un objeto StepData
      return StepData.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  @override
  Future<void> startCounting() async {
    await _methodChannel.invokeMethod('start');
  }

  @override
  Future<void> stopCounting() async {
    await _methodChannel.invokeMethod('stop');
  }

  @override
  Future<bool> requestPermissions() async {
    // Android 10+ requiere permiso para "Activity Recognition"
    final activityStatus = await Permission.activityRecognition.request();
    // Permiso general de sensores
    final sensorsStatus = await Permission.sensors.request();

    return activityStatus.isGranted && sensorsStatus.isGranted;
  }
}

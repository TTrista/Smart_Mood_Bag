import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleHelper {
  final Uuid serviceUuid;
  final Uuid charUuid;
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _notifySubscription;

  BleHelper({
    required this.serviceUuid,
    required this.charUuid,
  });

  void connectAndListen({
    required String deviceId,
    required void Function(Map<String, dynamic>) onData,
    required void Function(String) onError,
  }) {
    _connection?.cancel();
    _connection = _ble
        .connectToDevice(id: deviceId)
        .listen((connectionState) async {
      if (connectionState.connectionState == DeviceConnectionState.connected) {
        try {
          await _ble.discoverServices(deviceId);
          _notifySubscription = _ble
              .subscribeToCharacteristic(
                QualifiedCharacteristic(
                  deviceId: deviceId,
                  serviceId: serviceUuid,
                  characteristicId: charUuid,
                ),
              )
              .listen((data) {
            try {
              final text = utf8.decode(data);
              final parts = text.split(',');
              if (parts.length == 3) {
                final hr = double.tryParse(parts[0]);
                final hrv = double.tryParse(parts[1]);
                final signal = double.tryParse(parts[2]);

                if (hr != null && hrv != null && signal != null) {
                  onData({
                    'hr': hr,
                    'hrv': hrv,
                    'signal': signal,
                  });
                }
              }
            } catch (e) {
              onError("Parse error: $e");
            }
          }, onError: (e) {
            onError("Notify error: $e");
          });
        } catch (e) {
          onError("Service discovery or notification error: $e");
        }
      } else if (connectionState.connectionState ==
          DeviceConnectionState.disconnected) {
        onError("Device disconnected");
      }
    }, onError: (e) {
      onError("Connection error: $e");
    });
  }

  void disconnect() {
    _connection?.cancel();
    _notifySubscription?.cancel();
  }
}

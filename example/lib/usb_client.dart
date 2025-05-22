import 'dart:async';
import 'dart:typed_data';

import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/ftdi_serial.dart';
import 'package:ftdi_serial/serial_device.dart';

class USBClient {
  final FtdiSerial _ftdiSerial = FtdiSerial();
  Stream<dynamic>? _dataStream;
  StreamSubscription? _subscription;

  Stream<bool>? _deviceStatusDataStream;
  StreamSubscription? _deviceStatusSubscription;

  Future<DeviceListResult> init() async {
    // Initialize the USB client
    DeviceListResult deviceListResult = await _ftdiSerial.createDeviceList();

    return deviceListResult;
  }

  Future<bool> requestUsbPermission() async {
    // Request USB permission
    return await _ftdiSerial.requestUsbPermission();
  }

  Future write(Uint8List data) async {
    await _ftdiSerial.write(data);
  }

  Future<bool> connect() async {
    return await _ftdiSerial.connectToDevice();
  }

  static Future<SerialDevice> getAttachedDevice() async {
    return await FtdiSerial.getAttachedDevice();
  }

  void startListening({
    required Function(dynamic data) onDataReceived,
    Function(dynamic error)? onError,
  }) {
    // Cancel existing subscription if any
    _subscription?.cancel();

    // Get the stream from FtdiSerial
    _dataStream = _ftdiSerial.dataStream;

    // Subscribe to the stream
    _subscription = _dataStream?.listen(
      (data) {
        // Handle received data
        onDataReceived(data);
      },
      onError: (error) {
        // Handle errors
        if (onError != null) {
          onError(error);
        }
        print('Stream error: $error');
      },
      onDone: () {
        print('Stream closed');
        _subscription = null;
      },
    );
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void startDeviceStatusListening({
    required Function(dynamic data) onStatusReceived,
    Function(dynamic error)? onError,
  }) {
    // Cancel existing subscription if any
    _deviceStatusSubscription?.cancel();

    // Get the stream from FtdiSerial
    _deviceStatusDataStream = _ftdiSerial.deviceStatusStream;

    // Subscribe to the stream
    _deviceStatusSubscription = _deviceStatusDataStream?.listen(
      (data) {
        // Handle received data
        onStatusReceived(data);
      },
      onError: (error) {
        // Handle errors
        if (onError != null) {
          onError(error);
        }
        print('Stream error: $error');
      },
      onDone: () {
        print('Stream closed');
        _deviceStatusSubscription = null;
      },
    );
  }

  void stopDeviceStatusListening() {
    _deviceStatusSubscription?.cancel();
    _deviceStatusSubscription = null;
  }

  // Don't forget to dispose
  void dispose() {
    stopListening();
    stopDeviceStatusListening();
  }
}

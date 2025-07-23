import 'dart:async';
import 'dart:typed_data';

import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/ftdi_serial.dart';
import 'package:ftdi_serial/serial_device.dart';

class USBClient {
  final FtdiSerial _ftdiSerial = FtdiSerial();
  Stream<dynamic>? _dataStream;
  StreamSubscription? _subscription;

  Stream<bool>? _usbStatusDataStream;
  StreamSubscription? _usbStatusSubscription;

  Stream<bool>? _deviceConnectionStatusDataStream;
  StreamSubscription? _deviceConnectionStatusSubscription;

  Future<DeviceListResult> createDeviceList() async {
    // Initialize the USB client
    DeviceListResult deviceListResult = await _ftdiSerial.createDeviceList();

    return deviceListResult;
  }

  static Future<bool> hasUsbPermission() async {
    // Check if USB permission is granted
    return await FtdiSerial.hasUsbPermission();
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

  void startUsbStatusListening({
    required Function(dynamic data) onStatusReceived,
    Function(dynamic error)? onError,
  }) {
    // Cancel existing subscription if any
    _usbStatusSubscription?.cancel();

    // Get the stream from FtdiSerial
    _usbStatusDataStream = FtdiSerial.usbStatusStream;

    // Subscribe to the stream
    _usbStatusSubscription = _usbStatusDataStream?.listen(
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
        _usbStatusSubscription = null;
      },
    );
  }

  void stopUsbStatusListening() {
    _usbStatusSubscription?.cancel();
    _usbStatusSubscription = null;
  }

  void startDeviceConnectionStatusListening({
    required Function(dynamic data) onStatusReceived,
    Function(dynamic error)? onError,
  }) {
    // Cancel existing subscription if any
    _deviceConnectionStatusSubscription?.cancel();

    // Get the stream from FtdiSerial
    _deviceConnectionStatusDataStream =
        _ftdiSerial.deviceConnectionStatusStream;

    // Subscribe to the stream
    _deviceConnectionStatusSubscription = _deviceConnectionStatusDataStream
        ?.listen(
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
            _deviceConnectionStatusSubscription = null;
          },
        );
  }

  void stopDeviceConnectionStatusListening() {
    _deviceConnectionStatusSubscription?.cancel();
    _deviceConnectionStatusSubscription = null;
  }

  // Don't forget to dispose
  void dispose() {
    stopListening();
    stopUsbStatusListening();
    stopDeviceConnectionStatusListening();
  }
}

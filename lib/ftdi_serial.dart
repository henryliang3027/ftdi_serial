import 'dart:typed_data';

import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/serial_device.dart';

import 'ftdi_serial_platform_interface.dart';

class FtdiSerial {
  // 使用靜態變數來緩存同一個廣播流 (broadcast stream) 實例
  static Stream<bool>? _sharedUsbStatusStream;
  static Stream<dynamic>? _sharedDataStream;
  static Stream<bool>? _sharedDeviceConnectionStatusStream;

  Stream<dynamic> get dataStream {
    // 第一次調用 FtdiSerial.dataStream 時會創建廣播流
    // 多個監聽者可以共享同一個流實例
    _sharedDataStream ??= FtdiSerialPlatform.instance.dataStream;
    return _sharedDataStream!;
  }

  static Stream<bool> get usbStatusStream {
    // 第一次調用 FtdiSerial.usbStatusStream 時會創建廣播流
    // 多個監聽者可以共享同一個流實例
    _sharedUsbStatusStream ??= FtdiSerialPlatform.instance.usbStatusStream;
    return _sharedUsbStatusStream!;
  }

  static Future<SerialDevice> getAttachedDevice() {
    return FtdiSerialPlatform.instance.getAttachedDevice();
  }

  static Future<bool> hasUsbPermission() {
    return FtdiSerialPlatform.instance.hasUsbPermission();
  }

  static Future<bool> requestUsbPermission() {
    return FtdiSerialPlatform.instance.requestUsbPermission();
  }

  Stream<bool> get deviceConnectionStatusStream {
    // 第一次調用 FtdiSerial.deviceConnectionStatusStream 時會創建廣播流
    // 多個監聽者可以共享同一個流實例
    _sharedDeviceConnectionStatusStream ??=
        FtdiSerialPlatform.instance.deviceConnectionStatusStream;
    return _sharedDeviceConnectionStatusStream!;
  }

  Future<DeviceListResult> createDeviceList() {
    return FtdiSerialPlatform.instance.createDeviceList();
  }

  Future<bool> connectToDevice() {
    return FtdiSerialPlatform.instance.connectToDevice();
  }

  Future<bool> write(Uint8List data) {
    return FtdiSerialPlatform.instance.write(data);
  }
}

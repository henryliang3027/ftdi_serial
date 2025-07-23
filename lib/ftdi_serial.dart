import 'dart:typed_data';

import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/serial_device.dart';

import 'ftdi_serial_platform_interface.dart';

class FtdiSerial {
  Stream<dynamic> get dataStream {
    return FtdiSerialPlatform.instance.dataStream;
  }

  static Stream<bool> get usbStatusStream {
    return FtdiSerialPlatform.instance.usbStatusStream;
  }

  static Stream<bool> get usbPermissionStream {
    return FtdiSerialPlatform.instance.usbPermissionStream;
  }

  static Future<SerialDevice> getAttachedDevice() {
    return FtdiSerialPlatform.instance.getAttachedDevice();
  }

  static Future<bool> hasUsbPermission() {
    return FtdiSerialPlatform.instance.hasUsbPermission();
  }

  Stream<bool> get deviceConnectionStatusStream {
    return FtdiSerialPlatform.instance.deviceConnectionStatusStream;
  }

  Future<bool> requestUsbPermission() {
    return FtdiSerialPlatform.instance.requestUsbPermission();
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

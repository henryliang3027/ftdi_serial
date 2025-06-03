import 'dart:typed_data';

import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/serial_device.dart';

import 'ftdi_serial_platform_interface.dart';

class FtdiSerial {
  Stream<dynamic> get dataStream {
    return FtdiSerialPlatform.instance.dataStream;
  }

  Stream<bool> get deviceStatusStream {
    return FtdiSerialPlatform.instance.deviceStatusStream;
  }

  static Future<SerialDevice> getAttachedDevice() {
    return FtdiSerialPlatform.instance.getAttachedDevice();
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

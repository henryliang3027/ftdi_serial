import 'dart:typed_data';

import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/device_status.dart';

import 'ftdi_serial_platform_interface.dart';

class FtdiSerial {
  Future<String?> getPlatformVersion() {
    return FtdiSerialPlatform.instance.getPlatformVersion();
  }

  Stream<dynamic> get dataStream {
    return FtdiSerialPlatform.instance.dataStream;
  }

  Future<DeviceListResult> createDeviceList() {
    return FtdiSerialPlatform.instance.createDeviceList();
  }

  Future<DeviceStatus> checkDeviceStatus() {
    return FtdiSerialPlatform.instance.checkDeviceStatus();
  }

  Future<void> write(Uint8List data) {
    return FtdiSerialPlatform.instance.write(data);
  }
}

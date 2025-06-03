import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/serial_device.dart';

import 'ftdi_serial_platform_interface.dart';

/// An implementation of [FtdiSerialPlatform] that uses method channels.
class MethodChannelFtdiSerial extends FtdiSerialPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ftdi_serial');

  /// The event channel for streaming data
  final EventChannel _readDataChannel = const EventChannel(
    'ftdi_serial/read_data',
  );

  final EventChannel _deviceStatusChannel = const EventChannel(
    'ftdi_serial/device_status',
  );

  @override
  Stream<dynamic> get dataStream => _readDataChannel.receiveBroadcastStream();

  @override
  Stream<bool> get deviceStatusStream => _deviceStatusChannel
      .receiveBroadcastStream()
      .map((event) => event as bool);

  @override
  Future<bool> requestUsbPermission() async {
    try {
      // 這邊會回傳 true 或 false
      // true: 使用者允許 USB 權限
      // false: 使用者拒絕 USB 權限
      final bool result = await methodChannel.invokeMethod(
        'requestUsbPermission',
      );
      return result;
    } on PlatformException catch (e) {
      return false;
    }
  }

  @override
  Future<SerialDevice> getAttachedDevice() async {
    final result = await methodChannel.invokeMethod('getAttachedDevice');
    final Map<String, dynamic> resultMap = Map<String, dynamic>.from(
      result as Map,
    );
    SerialDevice serialDevice = SerialDevice.fromMap(resultMap);
    return serialDevice;
  }

  @override
  Future<DeviceListResult> createDeviceList() async {
    final result = await methodChannel.invokeMethod('createDeviceList');

    // invokeMethod 回傳 dynamic
    // method channel 將 Java 的 Map 轉換成 Dart 的 _Map<Object?, Object?>
    // Map.from() 會建立一個新的 Map 並進行適當的型別轉換
    // 安全的類型轉換寫法
    final Map<String, dynamic> resultMap = Map<String, dynamic>.from(
      result as Map,
    );

    return DeviceListResult.fromMap(resultMap);
  }

  @override
  Future<bool> connectToDevice() async {
    final bool result = await methodChannel.invokeMethod('connectToDevice');
    return result;
  }

  @override
  Future<bool> write(Uint8List data) async {
    try {
      final bool result = await methodChannel.invokeMethod('write', {
        'data': data,
      });
      return result;
    } catch (e) {
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/device_status.dart';

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

  @override
  Stream<dynamic> get dataStream => _readDataChannel.receiveBroadcastStream();

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<DeviceListResult> createDeviceList() async {
    try {
      final Map<String, dynamic> result = await methodChannel.invokeMethod(
        'createDeviceList',
      );
      return DeviceListResult.fromMap(result);
    } catch (e) {
      return DeviceListResult(
        success: false,
        error: e.toString(),
        deviceCount: -1,
      );
    }
  }

  @override
  Future<DeviceStatus> checkDeviceStatus() async {
    final String status = await methodChannel.invokeMethod('checkDeviceStatus');
    return DeviceStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toUpperCase() == status,
    );
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

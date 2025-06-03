import 'dart:typed_data';

import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/serial_device.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'ftdi_serial_method_channel.dart';

abstract class FtdiSerialPlatform extends PlatformInterface {
  /// Constructs a FtdiSerialPlatform.
  FtdiSerialPlatform() : super(token: _token);

  static final Object _token = Object();

  static FtdiSerialPlatform _instance = MethodChannelFtdiSerial();

  /// The default instance of [FtdiSerialPlatform] to use.
  ///
  /// Defaults to [MethodChannelFtdiSerial].
  static FtdiSerialPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FtdiSerialPlatform] when
  /// they register themselves.
  static set instance(FtdiSerialPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<dynamic> get dataStream;
  Stream<bool> get deviceStatusStream;

  Future<bool> requestUsbPermission() {
    throw UnimplementedError(
      'requestUsbPermission() has not been implemented.',
    );
  }

  Future<SerialDevice> getAttachedDevice() {
    throw UnimplementedError('getAttachedDevice() has not been implemented.');
  }

  Future<DeviceListResult> createDeviceList() {
    throw UnimplementedError('createDeviceList() has not been implemented.');
  }

  Future<bool> connectToDevice() {
    throw UnimplementedError('connectToDevice() has not been implemented.');
  }

  Future<bool> write(Uint8List data) {
    throw UnimplementedError('write() has not been implemented.');
  }
}

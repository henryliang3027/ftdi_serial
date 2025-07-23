import 'package:flutter_test/flutter_test.dart';
import 'package:ftdi_serial/ftdi_serial.dart';
import 'package:ftdi_serial/ftdi_serial_platform_interface.dart';
import 'package:ftdi_serial/ftdi_serial_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFtdiSerialPlatform
    with MockPlatformInterfaceMixin
    implements FtdiSerialPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FtdiSerialPlatform initialPlatform = FtdiSerialPlatform.instance;

  test('$MethodChannelFtdiSerial is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFtdiSerial>());
  });
}

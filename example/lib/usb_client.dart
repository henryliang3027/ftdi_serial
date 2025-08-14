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

  // 創建設備列表
  Future<DeviceListResult> createDeviceList() async {
    return await _ftdiSerial.createDeviceList();
  }

  // 檢查 USB 權限
  static Future<bool> hasUsbPermission() async {
    return await FtdiSerial.hasUsbPermission();
  }

  // 請求 USB 權限
  Future<bool> requestUsbPermission() async {
    return await _ftdiSerial.requestUsbPermission();
  }

  // 連接設備
  Future<bool> connect() async {
    return await _ftdiSerial.connectToDevice();
  }

  // 獲取已連接設備資訊
  static Future<SerialDevice> getAttachedDevice() async {
    return await FtdiSerial.getAttachedDevice();
  }

  // 發送數據
  Future write(Uint8List data) async {
    await _ftdiSerial.write(data);
  }

  // 開始監聽數據（重要：處理分包）
  void startListening({
    required Function(dynamic data) onDataReceived,
    Function(dynamic error)? onError,
  }) {
    _subscription?.cancel();
    _dataStream = _ftdiSerial.dataStream;

    _subscription = _dataStream?.listen(
      (data) {
        // 每個封包都會觸發這個回調
        onDataReceived(data);
      },
      onError: (error) {
        if (onError != null) onError(error);
        print('Stream error: $error');
      },
      onDone: () {
        print('Stream closed');
        _subscription = null;
      },
    );
  }

  // 停止監聽數據
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  // USB 狀態監聽
  void startUsbStatusListening({
    required Function(dynamic data) onStatusReceived,
    Function(dynamic error)? onError,
  }) {
    _usbStatusSubscription?.cancel();
    _usbStatusDataStream = FtdiSerial.usbStatusStream;

    _usbStatusSubscription = _usbStatusDataStream?.listen(
      (data) => onStatusReceived(data),
      onError: (error) {
        if (onError != null) onError(error);
        print('USB Status Stream error: $error');
      },
    );
  }

  // USB 狀態監聽
  void stopUsbStatusListening() {
    _usbStatusSubscription?.cancel();
    _usbStatusSubscription = null;
  }

  // 設備連接狀態監聽
  void startDeviceConnectionStatusListening({
    required Function(dynamic data) onStatusReceived,
    Function(dynamic error)? onError,
  }) {
    _deviceConnectionStatusSubscription?.cancel();
    _deviceConnectionStatusDataStream =
        _ftdiSerial.deviceConnectionStatusStream;

    _deviceConnectionStatusSubscription = _deviceConnectionStatusDataStream
        ?.listen(
          (data) => onStatusReceived(data),
          onError: (error) {
            if (onError != null) onError(error);
            print('Device Connection Stream error: $error');
          },
        );
  }

  // 停止設備連接狀態監聽
  void stopDeviceConnectionStatusListening() {
    _deviceConnectionStatusSubscription?.cancel();
    _deviceConnectionStatusSubscription = null;
  }

  // 清理資源
  void dispose() {
    stopListening();
    stopUsbStatusListening();
    stopDeviceConnectionStatusListening();
  }
}

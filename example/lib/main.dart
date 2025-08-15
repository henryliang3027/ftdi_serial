import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/serial_device.dart';
import 'package:ftdi_serial_example/usb_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _attachedInfo = 'Unknown';
  bool _hasPermission = false;
  bool _isStartUsbStatusListening = false;
  bool _isStartDataListening = false;
  bool _isConnected = false;
  int _dataReceivedCount = 0;
  String _usbStatus = 'Unknown (插拔時觸發更新)';

  // 🔥 重要：用於組合分包數據
  List<int> _combinedData = [];

  USBClient usbClient = USBClient();

  @override
  void initState() {
    super.initState();
    // 不會自動連接，讓用戶手動操作
  }

  // 🔥 重要：處理分包數據的方法
  void startDataListening() {
    usbClient.startListening(
      onDataReceived: (data) {
        print('接收到封包: $data');
        print('封包大小: ${data.length} bytes');

        setState(() {
          _dataReceivedCount++; // 記錄收到的封包數量
          _combinedData.addAll(data); // 🔥 將每個封包加入組合數據
        });
      },
      onError: (error) {
        print('數據接收錯誤: $error');
      },
    );
  }

  // 初始化完整流程
  Future<void> init() async {
    // 開始 USB 狀態監聽
    startUsbStatusListening();

    SerialDevice serialDevice = await USBClient.getAttachedDevice();
    String text =
        'VendorId: ${serialDevice.vendorId}\n'
        'ProductId: ${serialDevice.productId}\n'
        'DeviceName: ${serialDevice.deviceName}\n'
        'ProductName: ${serialDevice.productName}\n'
        'ManufacturerName: ${serialDevice.manufacturerName}';

    setState(() {
      _attachedInfo = text;
    });

    bool hasPermission = await USBClient.hasUsbPermission();
    bool isPermissionAllowed = false;

    if (!hasPermission) {
      isPermissionAllowed = await USBClient.requestUsbPermission();
    }

    setState(() {
      _hasPermission = hasPermission || isPermissionAllowed;
    });

    // 創建設備列表
    DeviceListResult deviceListResult = await usbClient.createDeviceList();

    print('找到設備數量: ${deviceListResult.deviceCount}');
    print('錯誤: ${deviceListResult.error ?? '無'}');
    print('成功: ${deviceListResult.success}');

    if (deviceListResult.deviceCount == 0) {
      print('未找到 ACI+ 放大器');
      return;
    }

    // 連接設備
    bool isConnected = await usbClient.connect();
    print('ACI+ 放大器連接狀態: $isConnected');

    if (!isConnected) {
      print('連接失敗');
      return;
    }

    // 開始數據監聽
    startDataListening();

    setState(() {
      _isStartUsbStatusListening = true;
      _isStartDataListening = true;
      _isConnected = true;
    });
  }

  // USB 狀態監聽
  void startUsbStatusListening() {
    usbClient.startUsbStatusListening(
      onStatusReceived: (data) {
        print('USB 狀態: $data');

        setState(() {
          _usbStatus = data ? '已連接' : '未連接';
        });
        if (data == false) {
          // 設備被拔除，停止監聽
          usbClient.stopListening();
          setState(() {
            _isConnected = false;
            _isStartDataListening = false;
          });
        }
      },
      onError: (error) {
        print('USB 狀態錯誤: $error');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('ACI+ 放大器控制範例')),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 狀態顯示卡片
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '設備資訊：$_attachedInfo',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'USB 權限：$_hasPermission',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'USB 狀態監聽：$_isStartUsbStatusListening',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '數據監聽：$_isStartDataListening',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '設備連接：$_isConnected',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'USB 狀態：$_usbStatus',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.indigo,
                            ),
                          ),
                          // 🔥 重要：顯示分包資訊
                          Text(
                            '接收封包數：$_dataReceivedCount',
                            style: TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                          Text(
                            '組合數據長度：${_combinedData.length} bytes',
                            style: TextStyle(fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // 基本操作按鈕
                  Text(
                    '基本操作：',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      // 停止所有監聽
                      usbClient.stopUsbStatusListening();
                      usbClient.stopListening();
                      usbClient.stopDeviceConnectionStatusListening();
                      setState(() {
                        _isStartUsbStatusListening = false;
                        _isStartDataListening = false;
                        _isConnected = false;
                        _combinedData.clear();
                        _dataReceivedCount = 0;
                      });

                      init(); // 初始化
                    },
                    child: const Text('初始化'),
                  ),

                  SizedBox(height: 20),

                  // ACI+ 指令按鈕
                  Text(
                    'ACI+ 控制指令：',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      // 🔥 重要：發送前清空組合數據
                      _combinedData.clear();
                      _dataReceivedCount = 0;

                      List<int> data = [176, 3, 0, 0, 0, 6, 222, 41];
                      Uint8List bytes = Uint8List.fromList(data);
                      usbClient.write(bytes);
                      print(
                        '發送 ACI+ 標準指令: ${data.map((e) => '0x${e.toRadixString(16).padLeft(2, '0')}').join(' ')}',
                      );
                    },
                    child: const Text('發送標準指令 [176, 3, 0, 0, 0, 6, 222, 41]'),
                  ),

                  SizedBox(height: 20),

                  // 清理按鈕
                  Text(
                    '清理操作：',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      // 停止所有監聽
                      usbClient.stopUsbStatusListening();
                      usbClient.stopListening();
                      usbClient.stopDeviceConnectionStatusListening();
                      setState(() {
                        _isStartUsbStatusListening = false;
                        _isStartDataListening = false;
                        _isConnected = false;
                        _combinedData.clear();
                        _dataReceivedCount = 0;
                      });
                    },
                    child: const Text('停止所有監聽'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

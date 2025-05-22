import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ftdi_serial/device_list_result.dart';
import 'package:ftdi_serial/ftdi_serial.dart';
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
  String _platformVersion = 'Unknown';
  String _isInitialized = 'Unknown';
  String isAttached = 'False';
  String _isPermissionAllowed = 'False';

  final _ftdiSerialPlugin = FtdiSerial();

  USBClient usbClient = USBClient();

  List<int> rawData = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // init();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _ftdiSerialPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<bool> requestUsbPermission() async {
    bool result = await usbClient.requestUsbPermission();
    print('USB Permission: $result');
    return result;
  }

  Future<void> init() async {
    usbClient.startDeviceStatusListening(
      onStatusReceived: (data) {
        print('Device Status: $data');
      },
      onError: (error) {
        print('Device Status Error: $error');
      },
    );

    // // Initialize the USB client
    DeviceListResult deviceListResult = await usbClient.init();
    print('deviceCount : ${deviceListResult.deviceCount}');
    print('error: ${deviceListResult.error ?? ''}');
    print('success: ${deviceListResult.success}');

    // bool isConnected = await usbClient.connect();
    // print('Connected to device: $isConnected');

    // // Start listening for data
    // usbClient.startListening(
    //   onDataReceived: (data) {
    //     print('Data received: $data');

    //     print('Data length: ${data.length}');
    //   },
    //   onError: (error) {
    //     print('Error: $error');
    //   },
    // );

    // setState(() {
    //   _isInitialized = 'Done';
    // });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Column(
          children: [
            Center(child: Text('Running on: $_platformVersion\n')),
            Center(child: Text('USB Client: $_isInitialized\n')),
            Center(child: Text('USB Attach: $isAttached\n')),
            Center(child: Text(rawData.length.toString())),
            ElevatedButton(
              onPressed: () {
                List<int> data = [176, 3, 0, 0, 0, 6, 222, 41];

                Uint8List bytes = Uint8List.fromList(data);

                usbClient.write(bytes);
              },
              child: const Text('Send Data'),
            ),
            ElevatedButton(
              onPressed: () async {
                SerialDevice serialDevice = await USBClient.getAttachedDevice();
                String text =
                    'vendorId:${serialDevice.vendorId}\n productId:${serialDevice.productId}\n deviceName:${serialDevice.deviceName}\n productName:${serialDevice.productName}\n manufacturerName:${serialDevice.manufacturerName}\n';

                print(text);

                setState(() {
                  isAttached = text;
                });
              },
              child: const Text('check attach'),
            ),
            ElevatedButton(
              onPressed: () {
                usbClient.stopListening();

                setState(() {
                  _isInitialized = 'Unknown';
                  isAttached = 'False';
                });

                init();
              },
              child: const Text('Refresh'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool isPermissionAllowed =
                    await usbClient.requestUsbPermission();

                print('USB Permission: $isPermissionAllowed');

                setState(() {
                  _isPermissionAllowed = isPermissionAllowed.toString();
                });
              },
              child: const Text('requestUsbPermission'),
            ),
          ],
        ),
      ),
    );
  }
}

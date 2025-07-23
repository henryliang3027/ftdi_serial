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

  String _attachedInfo = 'Unknown';
  bool _hasPermission = false;
  bool _isPermissionAllowed = false;
  bool _isStartUsbStatusListening = false;
  bool _isStartDeviceConnectionStatusListening = false;
  bool _isStartDataListening = false;
  bool _isConnected = false;
  final _ftdiSerialPlugin = FtdiSerial();
  int _dataReceivedCount = 0;
  int _dataLength = 0;

  USBClient usbClient = USBClient();

  List<int> rawData = [];

  @override
  void initState() {
    super.initState();
    // initPlatformState();
    // init();
  }

  Future<bool> requestUsbPermission() async {
    bool result = await usbClient.requestUsbPermission();
    print('USB Permission: $result');
    return result;
  }

  void startUsbStatusListening() {
    usbClient.startUsbStatusListening(
      onStatusReceived: (data) {
        print('Device Status: $data');

        if (data == false) {
          usbClient.stopListening();
        }
      },
      onError: (error) {
        print('Device Status Error: $error');
      },
    );
    print('Started Device Status Listening');
  }

  void startDataListening() {
    usbClient.startListening(
      onDataReceived: (data) {
        print('Data received: $data');

        print('Data length: ${data.length}');

        setState(() {
          _dataReceivedCount++;
          _dataLength = data.length;
        });
      },
      onError: (error) {
        print('readSink Error: $error');
      },
    );
  }

  void startDeviceConnectionStatusListening() {
    usbClient.startDeviceConnectionStatusListening(
      onStatusReceived: (data) {
        print('Device Connection Status: $data');

        if (data == false) {
          usbClient.stopDeviceConnectionStatusListening();
        }
      },
      onError: (error) {
        print('Device Connection Error: $error');
      },
    );
    print('Started Device Connection Status Listening');
  }

  Future<void> init() async {
    startUsbStatusListening();

    // Initialize the USB client
    DeviceListResult deviceListResult = await usbClient.createDeviceList();
    print('deviceCount : ${deviceListResult.deviceCount}');
    print('error: ${deviceListResult.error ?? ''}');
    print('success: ${deviceListResult.success}');

    if (deviceListResult.deviceCount == 0) {
      return;
    }

    bool isConnected = await usbClient.connect();
    print('Connected to device: $isConnected');

    if (!isConnected) {
      return;
    }

    // Start listening for data
    startDataListening();

    setState(() {
      _isStartUsbStatusListening = true;
      _isStartDataListening = true;
      _isConnected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(child: Text('Running on: $_platformVersion\n')),
              Center(child: Text('Attached Info: $_attachedInfo\n')),
              Center(child: Text('Has USB Permission : $_hasPermission\n')),
              Center(
                child: Text('USB Permission allowed: $_isPermissionAllowed\n'),
              ),
              Center(
                child: Text(
                  'Usb Status Listening: $_isStartUsbStatusListening\n',
                ),
              ),
              Center(
                child: Text('Device Data Listining: $_isStartDataListening\n'),
              ),
              Center(
                child: Text(
                  'Device Connection Status Listining: $_isStartDeviceConnectionStatusListening\n',
                ),
              ),
              Center(child: Text('Connected: $_isConnected\n')),
              Center(
                child: Text(
                  'Data Received: ${_dataLength}_${_dataReceivedCount}\n',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  SerialDevice serialDevice =
                      await USBClient.getAttachedDevice();
                  String text =
                      'vendorId:${serialDevice.vendorId}\n productId:${serialDevice.productId}\n deviceName:${serialDevice.deviceName}\n productName:${serialDevice.productName}\n manufacturerName:${serialDevice.manufacturerName}\n';

                  setState(() {
                    _attachedInfo = text;
                  });
                },
                child: const Text('check attach'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool hasPermission = await USBClient.hasUsbPermission();

                  print('Has USB Permission: $hasPermission');

                  setState(() {
                    _hasPermission = hasPermission;
                  });
                },
                child: const Text('HasUsbPermission'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool isPermissionAllowed =
                      await usbClient.requestUsbPermission();

                  print('USB Permission: $isPermissionAllowed');

                  setState(() {
                    _isPermissionAllowed = true;
                  });
                },
                child: const Text('requestUsbPermission'),
              ),
              ElevatedButton(
                onPressed: () {
                  startUsbStatusListening();

                  setState(() {
                    _isStartUsbStatusListening = true;
                  });
                },
                child: const Text('Start Usb Status Listening'),
              ),
              ElevatedButton(
                onPressed: () {
                  startDeviceConnectionStatusListening();

                  setState(() {
                    _isStartDeviceConnectionStatusListening = true;
                  });
                },
                child: const Text('Start Device Connection Status Listening'),
              ),
              ElevatedButton(
                onPressed: () async {
                  DeviceListResult deviceListResult =
                      await usbClient.createDeviceList();
                  print('deviceCount : ${deviceListResult.deviceCount}');
                  print('error: ${deviceListResult.error ?? ''}');
                  print('success: ${deviceListResult.success}');

                  bool isConnected = await usbClient.connect();
                  setState(() {
                    _isConnected = true;
                  });
                },
                child: const Text('connect'),
              ),
              ElevatedButton(
                onPressed: () {
                  startDataListening();

                  setState(() {
                    _isStartDataListening = true;
                  });
                },
                child: const Text('Start Data Listening'),
              ),

              ElevatedButton(
                onPressed: () {
                  List<int> data = [176, 3, 0, 0, 0, 6, 222, 41];
                  Uint8List bytes = Uint8List.fromList(data);
                  usbClient.write(bytes);
                },
                child: const Text('Send Data'),
              ),

              ElevatedButton(
                onPressed: () {
                  usbClient.stopUsbStatusListening();
                  usbClient.stopListening();

                  setState(() {
                    _isStartUsbStatusListening = false;
                    _isStartDeviceConnectionStatusListening = false;
                    _isStartDataListening = false;
                    _isConnected = false;
                  });
                },
                child: const Text('dispose'),
              ),

              ElevatedButton(
                onPressed: () {
                  init();
                },
                child: const Text('reinitialize'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

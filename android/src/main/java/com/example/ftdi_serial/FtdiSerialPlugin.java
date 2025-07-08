package com.example.ftdi_serial;

import androidx.annotation.NonNull;
import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.hardware.usb.UsbManager;
import android.hardware.usb.UsbDevice;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import io.flutter.Log;

import android.app.PendingIntent;
import java.util.HashMap;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.ExecutionException;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;

import com.ftdi.j2xx.D2xxManager; // Import the FTDI library
import com.ftdi.j2xx.FT_Device;// Import the FTDI library

/** FtdiSerialPlugin */
public class FtdiSerialPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native
    /// Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine
    /// and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    // for reading data
    private EventChannel readChannel;
    private EventSink readSink;
    private ReadThread readThread;

    // for detecting device status
    private EventChannel usbStatusChannel;
    private EventSink usbStatusSink;

    // for monitoring FTDI device connection status
    private EventChannel deviceConnectionChannel;
    private EventSink deviceConnectionSink;
    private DeviceConnectionStatusThread deviceConnectionStatusThread;

    private UsbManager usbManager;
    private BroadcastReceiver usbStatusReceiver;
    private BroadcastReceiver permissionReceiver;

    // Handler to post results back to the main thread
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    public static D2xxManager ftD2xx = null;
    FT_Device ftDev;
    private Context context;
    private int portIndex = -1;

    // Resume transmission
    private static final byte XON = 0x11;

    // Pause transmission
    private static final byte XOFF = 0x13;

    private static final int USB_DATA_BUFFER = 8192;
    private static final String ACTION_USB_PERMISSION = "com.example.ftdi_serial";

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "ftdi_serial");
        channel.setMethodCallHandler(this);

        readChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "ftdi_serial/read_data");
        readChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                readSink = events;
                startReading();
            }

            @Override
            public void onCancel(Object arguments) {
                readSink = null;
                stopReading();
            }
        });

        // Add device status channel
        usbStatusChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "ftdi_serial/usb_status");
        usbStatusChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                usbStatusSink = events;
                registerUsbStatusReceiver();
            }

            @Override
            public void onCancel(Object arguments) {
                usbStatusSink = null;

                if (usbStatusReceiver != null) {
                    context.unregisterReceiver(usbStatusReceiver);
                    usbStatusReceiver = null;
                }
            }
        });

        // Add device connection monitoring channel
        deviceConnectionChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(),
                "ftdi_serial/device_connection_status");
        deviceConnectionChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                deviceConnectionSink = events;
                startDeviceConnectionMonitoring();
            }

            @Override
            public void onCancel(Object arguments) {
                deviceConnectionSink = null;
                stopDeviceConnectionMonitoring();
            }
        });

        context = flutterPluginBinding.getApplicationContext();

    }

    private CompletableFuture<Boolean> requestUsbPermission() {
        CompletableFuture<Boolean> permissionFuture = new CompletableFuture<>();

        UsbManager usbManager = (UsbManager) context.getSystemService(Context.USB_SERVICE);
        HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();

        if (deviceList.isEmpty()) {
            permissionFuture.complete(false);
            return permissionFuture;
        }

        UsbDevice device = (UsbDevice) deviceList.values().toArray()[0];
        if (device == null) {
            permissionFuture.complete(false);
            return permissionFuture;
        }

        if (usbManager.hasPermission(device)) {
            Log.d("TAG", "Already has permission");
            permissionFuture.complete(true);
            return permissionFuture;
        }

        // subscribe to the permission broadcast to get the result
        permissionReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context ctx, Intent intent) {
                String action = intent.getAction();

                Log.d("TAG", "received action:" + action);
                if (ACTION_USB_PERMISSION.equals(action)) {

                    UsbDevice receivedDevice;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        // android 13, api level 33
                        receivedDevice = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice.class);
                    } else {
                        receivedDevice = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
                    }

                    boolean granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false);

                    Log.d("TAG", "granted: " + granted);
                    context.unregisterReceiver(this);
                    permissionFuture.complete(granted); // 完成 Future

                }
            }
        };

        // Register the receiver
        IntentFilter filter = new IntentFilter(ACTION_USB_PERMISSION);

        context.registerReceiver(permissionReceiver, filter, Context.RECEIVER_NOT_EXPORTED);

        // Send the permission request
        Intent intent = new Intent(ACTION_USB_PERMISSION);
        intent.setPackage(context.getPackageName());

        // use FLAG_MUTABLE to avoid the error:
        // https://stackoverflow.com/questions/73267829/androidstudio-usb-extra-permission-granted-returns-false-always
        PendingIntent permissionIntent = PendingIntent.getBroadcast(context, 0,
                intent, PendingIntent.FLAG_MUTABLE);
        usbManager.requestPermission(device, permissionIntent);

        return permissionFuture;
    }

    private void registerUsbStatusReceiver() {
        usbStatusReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();

                if (UsbManager.ACTION_USB_DEVICE_ATTACHED.equals(action)) {
                    // Device was attached
                    Log.d("TAG", "Device was attached");
                    if (usbStatusSink != null) {
                        mainHandler.post(() -> {
                            usbStatusSink.success(true);
                        });
                    }

                } else if (UsbManager.ACTION_USB_DEVICE_DETACHED.equals(action)) {
                    // Device was detached
                    Log.d("TAG", "Device was detached");
                    if (usbStatusSink != null) {
                        mainHandler.post(() -> {
                            usbStatusSink.success(false);
                        });
                    }

                }
            }
        };

        // Register for USB events
        IntentFilter filter = new IntentFilter();
        filter.addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED);
        filter.addAction(UsbManager.ACTION_USB_DEVICE_DETACHED);
        context.registerReceiver(usbStatusReceiver, filter);
    }

    private void disconnect() {
        // Clean up resources
        if (ftDev != null) {
            if (ftDev.isOpen()) {
                ftDev.close();
            }
            ftDev = null;
        }
        portIndex = -1;
    }

    private void startReading() {
        readThread = new ReadThread();
        readThread.start();
    }

    private void stopReading() {
        disconnect();
        if (readThread != null) {
            readThread.interrupt();
            readThread = null;

        }

    }

    private void startDeviceConnectionMonitoring() {
        deviceConnectionStatusThread = new DeviceConnectionStatusThread();
        deviceConnectionStatusThread.start();
    }

    private void stopDeviceConnectionMonitoring() {
        if (deviceConnectionStatusThread != null) {
            deviceConnectionStatusThread.interrupt();
            deviceConnectionStatusThread = null;
        }
    }

    private SerialDevice getAttachedDevice() {
        Log.d("TAG", "getAttachedDevice");
        UsbManager usbManager = (UsbManager) context.getSystemService(Context.USB_SERVICE);
        HashMap<String, UsbDevice> deviceList = usbManager.getDeviceList();

        if (deviceList.isEmpty()) {
            return new SerialDevice(
                    -1,
                    -1,
                    "None",
                    "None",
                    "None");
        }

        UsbDevice firstDevice = (UsbDevice) deviceList.values().toArray()[0];
        return new SerialDevice(
                firstDevice.getVendorId(),
                firstDevice.getProductId(),
                firstDevice.getDeviceName() != null ? firstDevice.getDeviceName() : "Unknown",
                firstDevice.getProductName() != null ? firstDevice.getProductName() : "Unknown",
                firstDevice.getManufacturerName() != null ? firstDevice.getManufacturerName() : "Unknown");

    }

    private DeviceListResult createDeviceList() {
        try {
            if (ftD2xx == null) {
                ftD2xx = D2xxManager.getInstance(context);
            }

            int tempDevCount = ftD2xx.createDeviceInfoList(context);
            if (tempDevCount >= 0) {
                if (tempDevCount > 0) {
                    portIndex = 0; // Assuming you want to connect to the first device
                }
                return new DeviceListResult(true, null, tempDevCount);
            } else {
                return new DeviceListResult(false, "No devices found", 0);
            }

        } catch (D2xxManager.D2xxException e) {
            return new DeviceListResult(false, e.getMessage(), -1);
        } catch (Exception e) {
            return new DeviceListResult(false, "Unexpected error: " + e.getMessage(), -1);
        }
    }

    private boolean connectToDevice() {

        if (portIndex == -1) {
            return false;
        }

        ftDev = ftD2xx.openByIndex(context, portIndex);

        if (ftDev == null) {
            return false;
        }

        if (ftDev.isOpen() == false) {
            return false;
        }

        // reset to UART mode for 232 devices
        ftDev.setBitMode((byte) 0, D2xxManager.FT_BITMODE_RESET);
        ftDev.setBaudRate(115200);
        ftDev.setDataCharacteristics(D2xxManager.FT_DATA_BITS_8, D2xxManager.FT_STOP_BITS_1,
                D2xxManager.FT_PARITY_NONE);
        ftDev.setFlowControl(D2xxManager.FT_FLOW_NONE, XON, XOFF);

        return true;
    }

    private boolean write(byte[] data) {
        if (ftDev == null || !ftDev.isOpen()) {
            return false;
        }
        ftDev.write(data, data.length);
        return true;
    }

    class ReadThread extends Thread {

        @Override
        public void run() {

            while (!Thread.currentThread().isInterrupted()) {
                try {
                    Thread.sleep(50);
                } catch (InterruptedException e) {
                    // This exception is thrown when the thread is interrupted during sleep,
                    // The thread's interrupt status is automatically cleared (set to false)
                    // call again to stop the thread and exit the loop
                    Thread.currentThread().interrupt();
                    break;
                }

                // Check if the device is open
                // exit the loop if the ftDev is not open
                if (ftDev == null || !ftDev.isOpen()) {
                    break;
                }

                int readcount = ftDev.getQueueStatus();

                if (readcount > 0) {
                    if (readcount > USB_DATA_BUFFER) {
                        readcount = USB_DATA_BUFFER;
                    }
                    byte[] usbdata = new byte[readcount];
                    ftDev.read(usbdata, readcount);

                    // Send data to Flutter through eventSink
                    if (readSink != null) {
                        // Send to Flutter
                        mainHandler.post(() -> {
                            if (readSink != null) {
                                readSink.success(usbdata);
                            }
                        });
                    }
                }

            }
        }
    }

    class DeviceConnectionStatusThread extends Thread {
        @Override
        public void run() {
            boolean lastConnectionStatus = false;

            while (!Thread.currentThread().isInterrupted()) {
                try {
                    Thread.sleep(500); // Check every 500ms
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                }

                boolean currentConnectionStatus = ftDev != null && ftDev.isOpen();

                // Only emit when status changes to avoid flooding the stream
                if (currentConnectionStatus != lastConnectionStatus) {
                    lastConnectionStatus = currentConnectionStatus;

                    if (deviceConnectionSink != null) {
                        mainHandler.post(() -> {
                            if (deviceConnectionSink != null) {
                                deviceConnectionSink.success(currentConnectionStatus);
                            }
                        });
                    }
                }
            }
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        if (call.method.equals("createDeviceList")) {
            DeviceListResult deviceList = createDeviceList();
            result.success(deviceList.toMap());
        } else if (call.method.equals("requestUsbPermission")) {
            requestUsbPermission().thenAccept(granted -> {
                result.success(granted);
            });
        } else if (call.method.equals("getAttachedDevice")) {
            SerialDevice device = getAttachedDevice();
            result.success(device.toMap());
        } else if (call.method.equals("connectToDevice")) {
            boolean success = connectToDevice();
            result.success(success);
        } else if (call.method.equals("write")) {
            // Direct mapping to Java byte[] from Dart Uint8List
            byte[] data = call.argument("data");
            boolean success = write(data);
            result.success(success);
        } else {
            result.notImplemented();
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        readChannel.setStreamHandler(null); // Remove stream handler
        stopReading(); // Stop the reading thread
        usbStatusChannel.setStreamHandler(null);
        deviceConnectionChannel.setStreamHandler(null);
        stopDeviceConnectionMonitoring();

        if (usbStatusReceiver != null) {
            context.unregisterReceiver(usbStatusReceiver);
            usbStatusReceiver = null;
        }

        if (permissionReceiver != null) {
            context.unregisterReceiver(permissionReceiver);
            permissionReceiver = null;
        }
    }
}

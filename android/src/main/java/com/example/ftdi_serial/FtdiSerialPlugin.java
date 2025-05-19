package com.example.ftdi_serial;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import com.ftdi.j2xx.D2xxManager; // Import the FTDI library

/** FtdiSerialPlugin */
public class FtdiSerialPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private EventChannel eventChannel;
  private EventSink eventSink;
  private ReadThread readThread;

  private final Handler mainHandler = new Handler(Looper.getMainLooper());

  public static D2xxManager ftD2xx = null;
  FT_Device ftDev;
  private Context context;
  private final portIndex = 0;

  private final byte XON = 0x11;    /* Resume transmission */
  private final byte XOFF = 0x13;    /* Pause transmission */

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "ftdi_serial");
    channel.setMethodCallHandler(this);

    eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "ftdi_serial/read_data");
    eventChannel.setStreamHandler(this);

    context = flutterPluginBinding.getApplicationContext();

  }

  @Override
  public void onListen(Object arguments, EventChannel.EventSink events) {
      eventSink = events;
      startReading();
  }

  @Override
  public void onCancel(Object arguments) {
      eventSink = null;
      stopReading();
  }

  private void startReading() {
      readThread = new ReadThread();
      readThread.start();
  }

  private void stopReading() {
      if (readThread != null) {
          readThread.interrupt();
          readThread = null;
      }
  }

  private DeviceListResult createDeviceList() {
    try {
        if (ftD2xx == null) {
            ftD2xx = D2xxManager.getInstance(context);
        }
        
        int tempDevCount = ftD2xx.createDeviceInfoList(context);
        if (tempDevCount >= 0) {

            ftDev = ftD2xx.openByIndex(global_context, portIndex);

            // reset to UART mode for 232 devices
            ftDev.setBitMode((byte) 0, D2xxManager.FT_BITMODE_RESET);
            ftDev.setBaudRate(115200);
            ftDev.setDataCharacteristics(D2xxManager.FT_DATA_BITS_8, D2xxManager.FT_STOP_BITS_1, D2xxManager.FT_PARITY_NONE);
            ftDev.setFlowControl(D2xxManager.FT_FLOW_NONE, XON, XOFF);

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


  private boolean connectToDevice(){

      ftDev = ftD2xx.openByIndex(global_context, portIndex);

      if(ftDev == null) {
          return false;
      }

      if(ftDev.isOpen() == false) {
          return false;
      }

      // reset to UART mode for 232 devices
      ftDev.setBitMode((byte) 0, D2xxManager.FT_BITMODE_RESET);
      ftDev.setBaudRate(115200);
      ftDev.setDataCharacteristics(D2xxManager.FT_DATA_BITS_8, D2xxManager.FT_STOP_BITS_1, D2xxManager.FT_PARITY_NONE);
      ftDev.setFlowControl(D2xxManager.FT_FLOW_NONE, XON, XOFF);

      return true;
  }


private boolean write(byte[] data) {
    try {
        if (ftDev == null || !ftDev.isOpen()) {
            return false;
        }
        ftDev.write(buffer, numBytes);
        return true;
    } catch (Exception e) {
        e.printStackTrace();
        return false;
    }
}


  private DeviceStatus checDeviceStatus() {
    if(ftDev == null || ftDev.isOpen() ==false){
      return DeviceStatus.DISCONNECTED;
    } else {
      return DeviceStatus.CONNECTED;
    }
  }

  

  class ReadThread extends Thread {
    final int USB_DATA_BUFFER = 8192;

    @Override
    public void run() {
        byte[] usbdata = new byte[USB_DATA_BUFFER];

        while (!Thread.interrupted()) {
            try {
                Thread.sleep(50);
            } catch (InterruptedException e) {
                break;
            }

            int readcount = ftDev.getQueueStatus();

            if (readcount > 0) {
                if (readcount > USB_DATA_BUFFER) {
                    readcount = USB_DATA_BUFFER;
                }
                ftDev.read(usbdata, readcount);

                // Send data to Flutter through eventSink
                if (eventSink != null) {
                  // Send to Flutter
                  mainHandler.post(() -> {
                      if (eventSink != null) {
                          eventSink.success(data);
                      }
                  });
                }
            }
        }
    }
}

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("createDeviceList")){
        DeviceListResult deviceList = createDeviceList();
        result.success(deviceList.toMap());
    }else if (call.method.equals("checkDeviceStatus")) {
        DeviceStatus status = checDeviceStatus();

        // Send enum name as string
        result.success(status.name()); 
    }else if (call.method.equals("write")) {
        // Direct mapping to Java byte[] from Dart Uint8List
        byte[] data = call.argument("data");
        boolean success = write(data);
        result.success(success);
    }else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    eventChannel.setStreamHandler(null);  // Remove stream handler
    stopReading();  // Stop the reading thread
  }
}

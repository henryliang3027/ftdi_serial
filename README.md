# FTDI Serial Flutter Plugin 📱

這個插件專為 ACI+ 放大器設計，透過 FTDI USB 轉 UART 晶片與設備進行通信。
ACI+ 放大器使用特定的通信協定，需要發送特定格式的指令來控制設備功能。

## 快速開始

### 1. 安裝插件

在 ACI+ App 專案中的 `pubspec.yaml` 檔案中添加：

方法一：使用 Git Repository
```yaml
  ftdi_serial:
    git:
      url: https://github.com/henryliang3027/ftdi_serial.git # git repository 路徑
      ref: master
```

方法二：使用本地端路徑
```yaml
  ftdi_serial:
    path: /Users/henry.liang/projects_git/20250519/new/ftdi_serial # 本地端路徑
```


然後執行：
```bash
flutter pub get
```

### 2. 基本使用示例

```dart
import 'package:ftdi_serial/ftdi_serial.dart';

// 創建 FTDI 實例
final ftdiSerial = FtdiSerial();

// 發送 ACI+ 放大器控制指令
Future<void> sendAciCommand() async {
  // ACI+ 放大器特定指令格式
  List<int> command = [176, 3, 0, 0, 0, 6, 222, 41];
  await ftdiSerial.write(Uint8List.fromList(command));
}

// 接收 ACI+ 放大器回應數據
void listenForAciResponse() {
  ftdiSerial.dataStream.listen((data) {
    print('ACI+ 回應數據：$data');
    // 根據 ACI+ 指令格式解析數據
    parseAciResponse(data);
  });
}
```


### 3. FTDI 封包傳輸說明

FTDI 晶片的封包大小不固定，當傳輸大量數據（例如 16KB）時，FTDI 晶片會將數據分成多個不同大小的封包進行傳輸。這表示：

```dart
// 錯誤做法：
ftdiSerial.dataStream.listen((data) {
  // 這樣可能只收到部分數據！
  processCompleteData(data); 
});

// 正確做法：組合所有封包
List<int> _combinedData = [];

ftdiSerial.dataStream.listen((data) {
  _combinedData.addAll(data);  // 將每個封包加入組合數據
  
  // 根據協定判斷是否收到完整數據
  if (isCompleteData(_combinedData)) {
    processCompleteData(_combinedData);
    _combinedData.clear();  // 清空準備下次接收
  }
});
```


## 🔧 Android 設定

### 第一步：USB 設備過濾器

在 ACI+ App 專案中創建檔案 `android/app/src/main/res/xml/device_filter.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- FTDI 晶片 ID -->
    <usb-device vendor-id="1027" product-id="24577" /> <!-- FT232RL -->
    <usb-device vendor-id="1027" product-id="24596" /> <!-- FT232H -->
    <usb-device vendor-id="1027" product-id="24592" /> <!-- FT2232C/D/HL -->
    <usb-device vendor-id="1027" product-id="24593" /> <!-- FT4232HL -->
    <usb-device vendor-id="1027" product-id="24597" /> <!-- FT230X -->
    <usb-device vendor-id="1412" product-id="45088" /> <!-- REX-USB60F -->
    <usb-device vendor-id="1027" product-id="24641" /> <!-- FT4233HPQ -->
    <usb-device vendor-id="1027" product-id="24643" /> <!-- FT4232HPQ -->
    <usb-device vendor-id="1027" product-id="24640" /> <!-- FT2233HPQ-->
    <usb-device vendor-id="1027" product-id="24642" /> <!-- FT4232HPQ -->
    <usb-device vendor-id="1027" product-id="24645" /> <!-- FT232HPQ -->
    <usb-device vendor-id="1027" product-id="24644" /> <!-- FT233HPQ -->
</resources>
```

### 第二步：Activity 設定

在 ACI+ App 專案中 `android/app/src/main/AndroidManifest.xml` 中的 Activity 添加：

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTop"
    android:taskAffinity=""
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">
    
    <!-- 你的其他設定... -->

    <!-- USB Device Attached Intent Filter -->
    <intent-filter>
        <action android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED" />
    </intent-filter>

    <!-- USB Device Filter Metadata -->
    <meta-data
        android:name="android.hardware.usb.action.USB_DEVICE_ATTACHED"
        android:resource="@xml/device_filter" />
        
    <!-- 你的其他設定... -->
</activity>
```


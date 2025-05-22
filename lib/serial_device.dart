class SerialDevice {
  // Vendor Id
  final int vendorId;

  // Product Id
  final int productId;
  final String deviceName;
  final String productName;
  final String manufacturerName;

  SerialDevice({
    required this.vendorId,
    required this.productId,
    required this.deviceName,
    required this.productName,
    required this.manufacturerName,
  });

  factory SerialDevice.fromMap(Map<String, dynamic> map) {
    return SerialDevice(
      vendorId: map['vendorId'] as int,
      productId: map['productId'] as int,
      deviceName: map['deviceName'] as String,
      productName: map['productName'] as String,
      manufacturerName: map['manufacturerName'] as String,
    );
  }
}

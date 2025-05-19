class DeviceListResult {
  final bool success;
  final String? error;
  final int deviceCount;

  DeviceListResult({
    required this.success,
    this.error,
    required this.deviceCount,
  });

  factory DeviceListResult.fromMap(Map<String, dynamic> map) {
    return DeviceListResult(
      success: map['success'] as bool,
      error: map['error'] as String?,
      deviceCount: map['deviceCount'] as int,
    );
  }
}

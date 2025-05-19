// First, create a result class to hold the operation result
private static class DeviceListResult {
    final boolean success;
    final String error;
    final int deviceCount;

    private DeviceListResult(boolean success, String error, int deviceCount) {
        this.success = success;
        this.error = error;
        this.deviceCount = deviceCount;
    }

    Map<String, Object> toMap() {
        Map<String, Object> result = new HashMap<>();
        result.put("success", success);
        result.put("deviceCount", deviceCount);
        if (error != null) {
            result.put("error", error);
        }
        return result;
    }
}
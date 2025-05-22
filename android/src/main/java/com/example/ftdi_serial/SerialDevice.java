package com.example.ftdi_serial;

import java.util.Map;
import java.util.HashMap;

public class SerialDevice {
    private final int vendorId;
    private final int productId;
    private final String deviceName;
    private final String productName;
    private final String manufacturerName;

    public SerialDevice(int vendorId, int productId, String deviceName, String productName, String manufacturerName) {
        this.vendorId = vendorId;
        this.productId = productId;
        this.deviceName = deviceName;
        this.productName = productName;
        this.manufacturerName = manufacturerName;
    }

    public Map<String, Object> toMap() {
        Map<String, Object> result = new HashMap<>();
        result.put("vendorId", vendorId);
        result.put("productId", productId);
        result.put("deviceName", deviceName);
        result.put("productName", productName);
        result.put("manufacturerName", manufacturerName);
        return result;
    }
}
import Foundation
import IOKit.hid

final class HingeSensor {
    private var device: IOHIDDevice?

    func connect() -> Bool {
        disconnect()
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        let match: [String: Any] = [kIOHIDDeviceUsagePageKey: 0x20, kIOHIDDeviceUsageKey: 0x8A]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return false }
        for candidate in devices {
            let isBuiltIn = (IOHIDDeviceGetProperty(candidate, "Built-In" as CFString) as? NSNumber)?.boolValue == true
            guard isBuiltIn else { continue }
            if IOHIDDeviceOpen(candidate, 0) == kIOReturnSuccess {
                device = candidate
                return true
            }
        }
        return false
    }

    func read() -> Double? {
        guard let device else { return nil }
        var bytes = [UInt8](repeating: 0, count: 8)
        var count = bytes.count
        let result = IOHIDDeviceGetReport(device, kIOHIDReportTypeInput, 1, &bytes, &count)
        guard result == kIOReturnSuccess, count >= 3, bytes[0] == 1 else { return nil }
        let angle = Int(bytes[1]) | ((Int(bytes[2]) & 1) << 8)
        guard (0...180).contains(angle) else { return nil }
        return Double(angle)
    }

    func disconnect() {
        if let device {
            IOHIDDeviceClose(device, 0)
        }
        device = nil
    }

    deinit { disconnect() }
}

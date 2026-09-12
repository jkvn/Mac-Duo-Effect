import AppKit

enum Diagnostics {
    static func printReport() {
        let sensor = HingeSensor()
        print("Sensor connected: \(sensor.connect())")
        print("Lid angle: \(sensor.read().map(String.init(describing:)) ?? "unavailable")")
        print("Screen capture permission: \(ScreenPermission.isGranted)")
        print("Built-in display: \(BuiltInDisplay.screen != nil ? "available" : "unavailable")")
    }
}

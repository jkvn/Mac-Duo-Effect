import AppKit

enum BuiltInDisplay {
    static var screen: NSScreen? {
        NSScreen.screens.first { isBuiltIn($0) }
    }

    static func identifier(of screen: NSScreen) -> CGDirectDisplayID? {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        guard let number = screen.deviceDescription[key] as? NSNumber else { return nil }
        return number.uint32Value
    }

    static func isBuiltIn(_ screen: NSScreen) -> Bool {
        guard let identifier = identifier(of: screen) else { return false }
        return CGDisplayIsBuiltin(identifier) != 0
    }
}

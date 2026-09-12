import AppKit
import ScreenCaptureKit

enum ScreenPermission {
    static var isGranted: Bool { CGPreflightScreenCaptureAccess() }

    static func request() -> Bool { CGRequestScreenCaptureAccess() }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }

    static func hasAvailableDisplay() async throws -> Bool {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        return !content.displays.isEmpty
    }
}

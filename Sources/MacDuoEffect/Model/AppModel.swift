import AppKit
import Combine
import CoreImage
#if SWIFT_PACKAGE
import EffectCore
#endif

@MainActor
final class AppModel: ObservableObject {
    @Published var settings: EffectSettings {
        didSet { save(settings) }
    }

    @Published var enabled = false {
        didSet {
            UserDefaults.standard.set(enabled, forKey: DefaultsKey.enabled)
            if !enabled { stopEffect() }
        }
    }

    @Published var angle: Double?
    @Published var permission = ScreenPermission.isGranted
    @Published var status = "Checking sensor…"
    @Published var error: String?
    @Published var loginEnabled = LaunchAtLogin.isEnabled
    @Published var checkingPermission = false

    private let sensor = HingeSensor()
    private let capture = DisplayCapture()
    private let overlay = OverlayWindow()
    private let events = SystemEvents()

    private var timer: Timer?
    private var image: CIImage?
    private var smoothed = 0.0
    private var suspended = false
    private var verifiedCaptureAccess = false
    private var misses = 0
    private var movementAnchor: Double?
    private var lastTick = ProcessInfo.processInfo.systemUptime
    private var lastMovement = ProcessInfo.processInfo.systemUptime
    private var lastNeeded = 0.0
    private var lastProbe = 0.0

    private enum DefaultsKey {
        static let settings = "menuEffectSettings"
        static let enabled = "effectEnabled"
    }

    init() {
        settings = Self.loadSettings()
        capture.onFrame = { [weak self] frame in
            guard let self else { return }
            if self.settings.live || self.image == nil { self.image = frame }
        }
        capture.onError = { [weak self] message in
            guard let self else { return }
            self.verifiedCaptureAccess = false
            self.permission = ScreenPermission.isGranted
            self.error = "Screen capture: \(message)"
        }

        _ = sensor.connect()
        UserDefaults.standard.register(defaults: [DefaultsKey.enabled: true])
        enabled = UserDefaults.standard.bool(forKey: DefaultsKey.enabled)

        observeSystemEvents()
        startTimer()
    }

    func requestPermission() {
        permission = ScreenPermission.request()
        guard !permission else { return }
        error = "Enable Mac Duo Effect in System Settings → Privacy & Security → Screen Recording. "
              + "Relaunch the app if macOS asks."
        ScreenPermission.openSystemSettings()
    }

    func refreshPermission() {
        permission = ScreenPermission.isGranted || verifiedCaptureAccess
        loginEnabled = LaunchAtLogin.isEnabled
    }

    func recheckPermission() {
        guard !checkingPermission else { return }
        checkingPermission = true
        error = nil
        Task {
            defer { checkingPermission = false }
            do {
                verifiedCaptureAccess = try await ScreenPermission.hasAvailableDisplay()
                permission = verifiedCaptureAccess
                if !permission {
                    error = "No display is available. Connect or wake your display and refresh again."
                }
            } catch {
                verifiedCaptureAccess = false
                permission = false
                self.error = "Screen Recording is not available yet. Check the permission in System Settings. "
                           + "If macOS asked you to quit and reopen, restart Mac Duo Effect, then try again."
            }
        }
    }

    func setEnabled(_ value: Bool) {
        refreshPermission()
        error = nil
        lastMovement = ProcessInfo.processInfo.systemUptime
        enabled = value
    }

    func setLogin(_ value: Bool) {
        do {
            try LaunchAtLogin.set(value)
            loginEnabled = LaunchAtLogin.isEnabled
        } catch {
            self.error = "Could not change launch at login: \(error.localizedDescription)"
        }
    }

    func reset() {
        settings = EffectSettings()
        error = nil
    }

    private static func loadSettings() -> EffectSettings {
        guard let data = UserDefaults.standard.data(forKey: DefaultsKey.settings),
              let saved = try? JSONDecoder().decode(EffectSettings.self, from: data) else {
            return EffectSettings()
        }
        return saved.validated()
    }

    private func save(_ settings: EffectSettings) {
        guard let data = try? JSONEncoder().encode(settings.validated()) else { return }
        UserDefaults.standard.set(data, forKey: DefaultsKey.settings)
    }

    private func startTimer() {
        let timer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 0.005
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - lastTick
        lastTick = now
        guard !suspended else { return }

        readSensor(now: now)

        guard let angle else {
            updateStatus("No compatible lid sensor")
            return
        }
        guard enabled else {
            updateStatus("Paused")
            return
        }
        guard permission else {
            stopEffect()
            updateStatus("Waiting for Screen Recording")
            return
        }
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            stopEffect()
            updateStatus("Paused · Reduce Motion is on")
            return
        }
        guard let screen = BuiltInDisplay.screen, let displayID = BuiltInDisplay.identifier(of: screen) else {
            stopEffect()
            updateStatus("Waiting for built-in display")
            return
        }

        render(on: screen, displayID: displayID, angle: angle, now: now, elapsed: elapsed)
    }

    private func readSensor(now: TimeInterval) {
        guard let reading = sensor.read() else {
            misses += 1
            if misses >= 5 {
                angle = nil
                stopEffect()
            }
            if now - lastProbe > 5 {
                _ = sensor.connect()
                lastProbe = now
            }
            return
        }

        misses = 0
        if movementAnchor == nil || abs(reading - movementAnchor!) >= 1 {
            lastMovement = now
            movementAnchor = reading
        }
        if angle != reading { angle = reading }
    }

    private func render(on screen: NSScreen,
                        displayID: CGDirectDisplayID,
                        angle: Double,
                        now: TimeInterval,
                        elapsed: TimeInterval) {
        let timedOut = settings.timeout && now - lastMovement > 1.4
        let target = timedOut ? 0 : max(0, settings.startAngle - angle)
        smoothed = EffectMath.follow(smoothed, target: target, elapsed: elapsed)

        guard target > 0.02 || smoothed > 0.02 else {
            overlay.hide()
            updateStatus(timedOut ? "Ready · lid is still" : "Ready")
            if now - lastNeeded > 1.5 {
                capture.stop()
                image = nil
            }
            return
        }

        lastNeeded = now
        if !capture.isRunning, settings.live || image == nil {
            overlay.prepare(screen: screen)
            Task { await capture.start(displayID: displayID) }
        }

        guard let image else {
            updateStatus("Starting screen capture…")
            return
        }

        overlay.update(image: image, progress: smoothed, settings: settings)
        if !settings.live, capture.isRunning { capture.stop() }
        updateStatus(settings.live ? "Live effect" : "Still-frame effect")
    }

    private func updateStatus(_ text: String) {
        if status != text { status = text }
    }

    private func stopEffect() {
        overlay.hide()
        capture.stop()
        image = nil
        smoothed = 0
    }

    private func observeSystemEvents() {
        events.onSuspend = { [weak self] in
            self?.suspended = true
            self?.stopEffect()
        }
        events.onResume = { [weak self] in
            guard let self else { return }
            self.suspended = false
            self.lastMovement = ProcessInfo.processInfo.systemUptime
            _ = self.sensor.connect()
            self.refreshPermission()
        }
        events.onDisplayChange = { [weak self] in
            self?.stopEffect()
            self?.overlay.close()
        }
        events.onActivate = { [weak self] in
            self?.refreshPermission()
        }
        events.onTerminate = { [weak self] in
            self?.timer?.invalidate()
            self?.stopEffect()
            self?.sensor.disconnect()
        }
        events.start()
    }
}

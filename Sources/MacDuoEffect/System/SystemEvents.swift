import AppKit

final class SystemEvents {
    var onSuspend: (@MainActor () -> Void)?
    var onResume: (@MainActor () -> Void)?
    var onDisplayChange: (@MainActor () -> Void)?
    var onActivate: (@MainActor () -> Void)?
    var onTerminate: (@MainActor () -> Void)?

    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    private static let suspending: [Notification.Name] = [
        NSWorkspace.willSleepNotification,
        NSWorkspace.screensDidSleepNotification,
        NSWorkspace.sessionDidResignActiveNotification
    ]

    private static let resuming: [Notification.Name] = [
        NSWorkspace.didWakeNotification,
        NSWorkspace.screensDidWakeNotification,
        NSWorkspace.sessionDidBecomeActiveNotification
    ]

    func start() {
        stop()
        let workspace = NSWorkspace.shared.notificationCenter
        for name in Self.suspending {
            observe(name, on: workspace) { [weak self] in self?.onSuspend?() }
        }
        for name in Self.resuming {
            observe(name, on: workspace) { [weak self] in self?.onResume?() }
        }
        let center = NotificationCenter.default
        observe(NSApplication.didChangeScreenParametersNotification, on: center) { [weak self] in
            self?.onDisplayChange?()
        }
        observe(NSApplication.didBecomeActiveNotification, on: center) { [weak self] in
            self?.onActivate?()
        }
        observe(NSApplication.willTerminateNotification, on: center) { [weak self] in
            self?.onTerminate?()
        }
    }

    func stop() {
        for observer in observers {
            observer.center.removeObserver(observer.token)
        }
        observers.removeAll()
    }

    private func observe(_ name: Notification.Name,
                         on center: NotificationCenter,
                         handler: @escaping @MainActor () -> Void) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { handler() }
        }
        observers.append((center, token))
    }

    deinit { stop() }
}

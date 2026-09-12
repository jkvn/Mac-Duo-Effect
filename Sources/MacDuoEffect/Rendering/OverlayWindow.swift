import AppKit
import MetalKit
#if SWIFT_PACKAGE
import EffectCore
#endif

@MainActor
final class OverlayWindow {
    private var panel: NSPanel?
    private var metalView: MTKView?
    private var renderer: EffectRenderer?

    func prepare(screen: NSScreen) {
        if panel?.screen == screen, panel?.frame == screen.frame { return }
        close()

        let panel = NSPanel(contentRect: screen.frame,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)
        panel.isOpaque = true
        panel.backgroundColor = .black
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.animationBehavior = .none
        panel.hasShadow = false

        let view = MTKView(frame: CGRect(origin: .zero, size: screen.frame.size))
        guard let renderer = EffectRenderer(view: view) else { return }
        view.autoresizingMask = [.width, .height]
        panel.contentView = view

        self.panel = panel
        self.metalView = view
        self.renderer = renderer
    }

    func update(image: CIImage, progress: Double, settings: EffectSettings) {
        guard let panel, let metalView, let renderer else { return }
        renderer.source = image
        renderer.progress = progress
        renderer.settings = settings
        metalView.draw()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel?.orderOut(nil)
    }

    func close() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
        metalView = nil
        renderer = nil
    }
}

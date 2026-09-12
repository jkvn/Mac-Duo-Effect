import AppKit
import ScreenCaptureKit
import CoreImage

@MainActor
final class DisplayCapture: NSObject, SCStreamOutput, SCStreamDelegate {
    var onFrame: ((CIImage) -> Void)?
    var onError: ((String) -> Void)?

    private var stream: SCStream?
    private var generation = 0
    private var starting = false

    var isRunning: Bool { stream != nil || starting }

    func start(displayID: CGDirectDisplayID) async {
        guard !isRunning else { return }
        generation += 1
        let ticket = generation
        starting = true
        defer {
            if ticket == generation { starting = false }
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard generation == ticket else { return }
            guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
                throw CaptureFailure.displayUnavailable
            }

            let ownApp = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
            let filter = SCContentFilter(display: display, excludingApplications: ownApp, exceptingWindows: [])

            let config = SCStreamConfiguration()
            let scale = min(1, 1920.0 / Double(display.width))
            config.width = Int(Double(display.width) * scale)
            config.height = Int(Double(display.height) * scale)
            config.minimumFrameInterval = CMTime(value: 1, timescale: 60)
            config.queueDepth = 3
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = false
            config.capturesAudio = false

            let candidate = SCStream(filter: filter, configuration: config, delegate: self)
            try candidate.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
            stream = candidate
            try await candidate.startCapture()
            if generation != ticket {
                try? await candidate.stopCapture()
            }
        } catch {
            guard generation == ticket else { return }
            stream = nil
            onError?(error.localizedDescription)
        }
    }

    func stop() {
        generation += 1
        starting = false
        let previous = stream
        stream = nil
        if let previous {
            Task { try? await previous.stopCapture() }
        }
    }

    nonisolated func stream(_ stream: SCStream,
                            didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
                            of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid,
              let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
                  as? [[SCStreamFrameInfo: Any]],
              let status = attachments.first?[.status] as? Int,
              status == SCFrameStatus.complete.rawValue,
              let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        MainActor.assumeIsolated {
            guard self.stream === stream else { return }
            onFrame?(CIImage(cvPixelBuffer: buffer))
        }
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            guard self.stream === stream else { return }
            self.stream = nil
            onError?(error.localizedDescription)
        }
    }

    private enum CaptureFailure: LocalizedError {
        case displayUnavailable

        var errorDescription: String? { "The built-in display is currently unavailable." }
    }
}

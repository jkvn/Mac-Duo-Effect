import Foundation
import CoreImage
#if SWIFT_PACKAGE
import EffectCore
#endif

enum RenderCheck {
    enum Failure: Error {
        case invalidAlpha
        case identicalFrames
        case invalidBrightness
    }

    private static let bounds = CGRect(x: 0, y: 0, width: 960, height: 600)
    private static let stages: [Double] = [0, 30, 60]

    static func run(directory: String) throws {
        let context = CIContext()
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let chart = testChart()
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

        var frames: [[UInt8]] = []
        for degrees in stages {
            let image = EffectRenderer.compose(chart,
                                               bounds: bounds,
                                               closingDegrees: degrees,
                                               settings: EffectSettings())
            let url = URL(fileURLWithPath: directory).appendingPathComponent("effect-\(Int(degrees)).png")
            try context.writePNGRepresentation(of: image, to: url, format: .RGBA8, colorSpace: space)

            var bytes = [UInt8](repeating: 0, count: Int(bounds.width * bounds.height) * 4)
            context.render(image,
                           toBitmap: &bytes,
                           rowBytes: Int(bounds.width) * 4,
                           bounds: bounds,
                           format: .RGBA8,
                           colorSpace: space)
            guard stride(from: 3, to: bytes.count, by: 4).allSatisfy({ bytes[$0] == 255 }) else {
                throw Failure.invalidAlpha
            }
            frames.append(bytes)
        }

        guard frames[0] != frames[1], frames[1] != frames[2] else { throw Failure.identicalFrames }
        let brightness = frames.map(totalBrightness)
        guard brightness[0] > brightness[1], brightness[1] > brightness[2] else { throw Failure.invalidBrightness }
        print("Render check passed: 3 distinct opaque frames; brightness decreases as lid closes.")
    }

    private static func testChart() -> CIImage {
        CIFilter(name: "CICheckerboardGenerator", parameters: [
            "inputColor0": CIColor(red: 0.2, green: 0.8, blue: 0.65),
            "inputColor1": CIColor(red: 0.06, green: 0.16, blue: 0.26),
            "inputWidth": 48
        ])!.outputImage!.cropped(to: bounds)
    }

    private static func totalBrightness(of bytes: [UInt8]) -> Int {
        var total = 0
        for offset in stride(from: 0, to: bytes.count, by: 4) {
            total += Int(bytes[offset]) + Int(bytes[offset + 1]) + Int(bytes[offset + 2])
        }
        return total
    }
}

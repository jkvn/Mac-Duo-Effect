import AppKit
import CoreImage
import MetalKit
#if SWIFT_PACKAGE
import EffectCore
#endif

final class EffectRenderer: NSObject, MTKViewDelegate {
    var source: CIImage?
    var progress: Double = 0
    var settings = EffectSettings()

    private let queue: MTLCommandQueue
    private let context: CIContext
    private let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    init?(view: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else { return nil }
        self.queue = queue
        self.context = CIContext(mtlDevice: device, options: [.cacheIntermediates: false])
        super.init()

        view.device = device
        view.framebufferOnly = false
        view.colorPixelFormat = .bgra8Unorm
        view.isPaused = true
        view.enableSetNeedsDisplay = true
        view.delegate = self
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let source,
              let drawable = view.currentDrawable,
              let command = queue.makeCommandBuffer() else { return }
        let bounds = CGRect(origin: .zero, size: view.drawableSize)
        let image = Self.compose(source, bounds: bounds, closingDegrees: progress, settings: settings)
        context.render(image, to: drawable.texture, commandBuffer: command, bounds: bounds, colorSpace: colorSpace)
        command.present(drawable)
        command.commit()
    }

    static func compose(_ source: CIImage,
                        bounds: CGRect,
                        closingDegrees: Double,
                        settings: EffectSettings) -> CIImage {
        let configuration = settings.validated()
        let closure = closingDegrees.isFinite ? max(0, closingDegrees) : 0
        let progress = min(1, closure / configuration.transitionAngle)
        let width = bounds.width
        let height = bounds.height

        let scaled = source
            .transformed(by: CGAffineTransform(translationX: -source.extent.minX, y: -source.extent.minY))
            .transformed(by: CGAffineTransform(scaleX: width / source.extent.width,
                                               y: height / source.extent.height))
        guard closure > 0.001 else { return scaled.cropped(to: bounds) }

        let blurFloor = CGFloat(configuration.blurSpread)
        let blurMask = gradient(height: height,
                                lower: CIColor(red: blurFloor, green: blurFloor, blue: blurFloor),
                                upper: .white)
        let blurred = scaled.clampedToExtent()
            .applyingFilter("CIMaskedVariableBlur", parameters: [
                "inputMask": blurMask,
                kCIInputRadiusKey: configuration.blurRadius * progress * Double(width / 1728)
            ])
            .cropped(to: bounds)

        let shade = gradient(height: height * configuration.dimmingSpread,
                             lower: .clear,
                             upper: CIColor(red: 0, green: 0, blue: 0, alpha: configuration.dimming * progress))
        let lit = shade.cropped(to: bounds).composited(over: blurred)

        let edge = EffectMath.topEdge(closingDegrees: closure,
                                      lean: configuration.lean,
                                      perspective: configuration.perspective)
        let warped = lit.applyingFilter("CIPerspectiveTransform", parameters: [
            "inputTopLeft": CIVector(x: width * edge.inset, y: height * edge.height),
            "inputTopRight": CIVector(x: width * (1 - edge.inset), y: height * edge.height),
            "inputBottomLeft": CIVector(x: 0, y: 0),
            "inputBottomRight": CIVector(x: width, y: 0)
        ])
        return warped.composited(over: CIImage(color: .black)).cropped(to: bounds)
    }

    private static func gradient(height: CGFloat, lower: CIColor, upper: CIColor) -> CIImage {
        CIFilter(name: "CILinearGradient", parameters: [
            "inputPoint0": CIVector(x: 0, y: 0),
            "inputPoint1": CIVector(x: 0, y: max(1, height)),
            "inputColor0": lower,
            "inputColor1": upper
        ])!.outputImage!
    }
}

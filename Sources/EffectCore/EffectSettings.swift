import Foundation

public struct EffectSettings: Codable, Equatable {
    public var startAngle: Double = 90
    public var transitionAngle: Double = 60
    public var blurRadius: Double = 135
    public var blurSpread: Double = 0
    public var dimming: Double = 1
    public var dimmingSpread: Double = 0.5
    public var lean: Double = 1
    public var perspective: Double = 0
    public var live = true
    public var timeout = false
    public var showAngle = false

    public init() {}

    public func validated() -> Self {
        var result = self
        result.startAngle = Self.clamp(startAngle, 5...130, fallback: 90)
        result.transitionAngle = Self.clamp(transitionAngle, 5...60, fallback: 60)
        result.blurRadius = Self.clamp(blurRadius, 10...160, fallback: 135)
        result.blurSpread = Self.clamp(blurSpread, 0...1, fallback: 0)
        result.dimming = Self.clamp(dimming, 0...1, fallback: 1)
        result.dimmingSpread = Self.clamp(dimmingSpread, 0.2...1, fallback: 0.5)
        result.lean = Self.clamp(lean, 0...3, fallback: 1)
        result.perspective = Self.clamp(perspective, 0...1, fallback: 0)
        return result
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>, fallback: Double) -> Double {
        guard value.isFinite else { return fallback }
        return min(range.upperBound, max(range.lowerBound, value))
    }
}

import Foundation

public enum EffectMath {
    public static func closure(angle: Double, settings: EffectSettings) -> Double {
        guard angle.isFinite else { return 0 }
        let configuration = settings.validated()
        return min(1, max(0, (configuration.startAngle - angle) / configuration.transitionAngle))
    }

    public static func follow(_ current: Double, target: Double, elapsed: Double) -> Double {
        guard current.isFinite, target.isFinite else { return 0 }
        let dt = min(0.1, max(0, elapsed))
        return current + (target - current) * (1 - exp(-dt / 0.055))
    }

    public static func topEdge(closingDegrees: Double,
                               lean: Double,
                               perspective: Double) -> (inset: Double, height: Double) {
        guard closingDegrees.isFinite, lean.isFinite, perspective.isFinite else { return (0, 1) }
        let rotation = min(85, max(0, closingDegrees * lean)) * .pi / 180
        let distance = 6 - 5 * min(1, max(0, perspective))
        let scale = distance / (distance + sin(rotation))
        let inset = (1 - scale) / 2
        let height = 0.5 + (cos(rotation) - 0.5) * scale
        return (inset, height)
    }
}

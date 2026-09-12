import XCTest
@testable import EffectCore

final class EffectMathTests: XCTestCase {
    func testTransitionMatchesUserSelectedAngles() {
        var settings = EffectSettings()
        settings.startAngle = 100
        settings.transitionAngle = 40
        XCTAssertEqual(EffectMath.closure(angle: 100, settings: settings), 0)
        XCTAssertEqual(EffectMath.closure(angle: 80, settings: settings), 0.5)
        XCTAssertEqual(EffectMath.closure(angle: 60, settings: settings), 1)
        XCTAssertEqual(EffectMath.closure(angle: 0, settings: settings), 1)
        XCTAssertEqual(EffectMath.closure(angle: 160, settings: settings), 0)
    }

    func testInvalidSensorDataNeverObscuresDisplay() {
        XCTAssertEqual(EffectMath.closure(angle: .nan, settings: .init()), 0)
        XCTAssertEqual(EffectMath.closure(angle: .infinity, settings: .init()), 0)
    }

    func testPerspectiveKeepsRectangleValidAcrossControlRanges() {
        let identity = EffectMath.topEdge(closingDegrees: 0, lean: 1, perspective: 0.5)
        XCTAssertEqual(identity.inset, 0)
        XCTAssertEqual(identity.height, 1)
        for lean in stride(from: 0.0, through: 3, by: 0.1) {
            for angle in 0...130 {
                for strength in [0.0, 0.5, 1.0] {
                    let edge = EffectMath.topEdge(closingDegrees: Double(angle), lean: lean, perspective: strength)
                    XCTAssertTrue((0..<0.5).contains(edge.inset))
                    XCTAssertTrue((0...1).contains(edge.height))
                }
            }
        }
    }

    func testSmoothingDoesNotDependOnRefreshRateOrOvershoot() {
        func simulate(_ fps: Int) -> Double {
            (0..<fps).reduce(0.0) { value, _ in EffectMath.follow(value, target: 1, elapsed: 1 / Double(fps)) }
        }
        XCTAssertEqual(simulate(30), simulate(120), accuracy: 0.000001)
        XCTAssertLessThanOrEqual(EffectMath.follow(0.4, target: 1, elapsed: 5), 1)
        XCTAssertGreaterThanOrEqual(EffectMath.follow(0.8, target: 0, elapsed: 5), 0)
    }

    func testCorruptPreferencesCannotProduceInvalidFilterInputs() {
        var settings = EffectSettings()
        settings.lean = 100
        settings.blurRadius = -2
        settings.startAngle = .nan
        settings.dimmingSpread = 0
        let safe = settings.validated()
        XCTAssertEqual(safe.lean, 3)
        XCTAssertEqual(safe.blurRadius, 10)
        XCTAssertEqual(safe.startAngle, 90)
        XCTAssertEqual(safe.dimmingSpread, 0.2)
    }
}

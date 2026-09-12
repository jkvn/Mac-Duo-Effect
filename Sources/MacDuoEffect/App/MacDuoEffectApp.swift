import SwiftUI

struct MacDuoEffectApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuPanel(model: model)
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "laptopcomputer")
                if model.settings.showAngle {
                    Text(model.angle.map { "\(Int($0))°" } ?? "—").monospacedDigit()
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}

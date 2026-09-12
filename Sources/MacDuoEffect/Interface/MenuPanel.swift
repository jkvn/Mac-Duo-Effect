import SwiftUI
#if SWIFT_PACKAGE
import EffectCore
#endif

struct MenuPanel: View {
    @ObservedObject var model: AppModel
    @State private var appearanceExpanded = false
    @State private var showingInfo = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if showingInfo {
                InfoPanel()
            } else {
                settings
            }
        }
        .frame(width: 330)
        .onAppear { model.refreshPermission() }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppInfo.name).font(.headline)
                Text(showingInfo ? "About this app" : model.status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if !showingInfo {
                Text(model.angle.map { "\(Int($0))°" } ?? "—")
                    .font(.system(.title3, design: .rounded).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            infoButton
            optionsMenu
        }
        .padding(16)
    }

    private var infoButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { showingInfo.toggle() }
        } label: {
            Image(systemName: showingInfo ? "chevron.backward.circle" : "info.circle")
                .font(.title3)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .help(showingInfo ? "Back to settings" : "About \(AppInfo.name)")
        .accessibilityLabel(showingInfo ? "Back to settings" : "About \(AppInfo.name)")
    }

    private var optionsMenu: some View {
        Menu {
            Button("Reset Settings", action: model.reset)
            Divider()
            Button("Quit \(AppInfo.name)") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
        } label: {
            Image(systemName: "ellipsis.circle").font(.title3)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .foregroundStyle(.secondary)
        .frame(width: 20)
        .help("More options")
        .accessibilityLabel("More options")
    }

    private var settings: some View {
        Form {
            effectSection
            anglesSection
            appearanceSection
            generalSection
            permissionSection
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .controlSize(.small)
        .frame(height: formHeight)
    }

    private var formHeight: CGFloat {
        if appearanceExpanded { return 590 }
        return model.permission && model.error == nil ? 400 : 470
    }

    private var effectSection: some View {
        Section("Effect") {
            Toggle("Depth effect", isOn: Binding(get: { model.enabled }, set: model.setEnabled))
                .toggleStyle(.switch)
                .disabled(!model.permission)
                .help(model.permission
                      ? "Enable or pause the effect."
                      : "The effect stays on and starts as soon as Screen Recording is allowed.")
            Toggle("Live rendering", isOn: $model.settings.live)
                .help("Keep the screen content moving. Turn off to hold the initial frame.")
            Toggle("Stop when still", isOn: $model.settings.timeout)
                .help("Fade out the effect when the lid stops moving.")
        }
    }

    private var anglesSection: some View {
        Section("Angles") {
            SliderRow(title: "Start angle",
                      value: $model.settings.startAngle,
                      range: 5...130,
                      unit: "°")
            SliderRow(title: "Full effect after",
                      value: $model.settings.transitionAngle,
                      range: 5...60,
                      unit: "°")
        }
    }

    private var appearanceSection: some View {
        Section {
            DisclosureGroup("Appearance", isExpanded: $appearanceExpanded) {
                VStack(spacing: 12) {
                    SliderRow(title: "Blur", value: $model.settings.blurRadius, range: 10...160, unit: " pt")
                    SliderRow(title: "Blur spread", value: $model.settings.blurSpread,
                              range: 0...1, unit: "%", multiplier: 100)
                    SliderRow(title: "Dimming", value: $model.settings.dimming,
                              range: 0...1, unit: "%", multiplier: 100)
                    SliderRow(title: "Dimming spread", value: $model.settings.dimmingSpread,
                              range: 0.2...1, unit: "%", multiplier: 100)
                    SliderRow(title: "Lean back", value: $model.settings.lean,
                              range: 0...3, unit: "×", decimals: 1)
                    SliderRow(title: "Perspective", value: $model.settings.perspective,
                              range: 0...1, unit: "%", multiplier: 100)
                }
                .padding(.top, 12)
            }
        }
    }

    private var generalSection: some View {
        Section("General") {
            Toggle("Show angle in menu bar", isOn: $model.settings.showAngle)
            Toggle("Launch at login", isOn: Binding(get: { model.loginEnabled }, set: model.setLogin))
            LabeledContent("Display") {
                Text("Built-in only").foregroundStyle(.secondary)
            }
            .help("External displays are never captured or covered by the effect.")
        }
    }

    private var permissionSection: some View {
        Section("Permission") {
            HStack(spacing: 8) {
                Image(systemName: model.permission ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundStyle(model.permission ? Color.green : Color.orange)
                Text(model.permission ? "Screen Recording allowed" : "Screen Recording needed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button(model.checkingPermission ? "Checking…" : "Refresh", action: model.recheckPermission)
                    .disabled(model.checkingPermission)
                    .accessibilityLabel("Refresh Screen Recording permission")
            }
            if !model.permission {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Screen Recording access is needed for the effect. Frames stay on your Mac and are never saved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Allow Screen Recording", action: model.requestPermission)
                }
            }
            if let error = model.error {
                HStack(alignment: .top) {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button {
                        model.error = nil
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss message")
                }
            }
        }
    }
}

import SwiftUI

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    var multiplier: Double = 1
    var decimals: Int = 0

    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text(formattedValue)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            Slider(value: $value, in: range)
                .accessibilityLabel(title)
        }
    }

    private var formattedValue: String {
        String(format: "%.*f", decimals, value * multiplier) + unit
    }
}

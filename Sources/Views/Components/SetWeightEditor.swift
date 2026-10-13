import SwiftUI
import WatchKit

struct SetWeightEditor: View {
    @Binding var weight: Double
    let unit: WeightUnit
    var accent: Color = IronTheme.ember
    var isBarbell = true
    var title = "Set weight"
    var saveTitle = "Save weight"
    @Environment(\.dismiss) private var dismiss
    @FocusState private var crownFocused: Bool
    @State private var draft: Double = 0
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                IronEyebrow(text: title, color: accent)
                HStack(spacing: 4) {
                    adjustmentButton(-unit.roundTo, symbol: "minus")
                    Text(IronTheme.weight(draft))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .focusable()
                        .focused($crownFocused)
                        .digitalCrownRotation($draft, from: 0, through: 1000, by: unit.roundTo,
                                              sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                    adjustmentButton(unit.roundTo, symbol: "plus")
                }
                Text("\(unit.label) · turn the Crown")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                if isBarbell {
                    NavigationLink(destination: PlateCalculatorView(targetWeight: draft, unit: unit)) {
                        HStack {
                            CompactPlateStackView(targetWeight: draft, unit: unit)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.system(size: 10))
                        }
                        .frame(minHeight: 30)
                        .padding(.horizontal, 8)
                        .modifier(IronCard(accent: accent))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View plates per side")
                }
                Button(saveTitle) {
                    weight = draft
                    WKInterfaceDevice.current().play(.click)
                    dismiss()
                }
                .buttonStyle(IronButtonStyle(accent: accent))
            }
            .padding(.horizontal, 8)
            .containerBackground(IronTheme.canvas.gradient, for: .navigation)
            .onAppear {
                if !loaded {
                    draft = weight
                    loaded = true
                }
                crownFocused = true
            }
        }
    }

    private func adjustmentButton(_ amount: Double, symbol: String) -> some View {
        Button {
            draft = min(1000, max(0, draft + amount))
            WKInterfaceDevice.current().play(.click)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 34, height: 40)
                .background(IronTheme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(amount > 0 ? "Increase weight" : "Decrease weight")
    }
}

import SwiftUI
import WatchKit

struct CountEditor: View {
    @Binding var value: Double
    let title: String
    let range: ClosedRange<Double>
    var saveTitle = "Save"
    @Environment(\.dismiss) private var dismiss
    @FocusState private var crownFocused: Bool
    @State private var draft = 0.0
    @State private var loaded = false

    var body: some View {
        VStack(spacing: 10) {
            IronEyebrow(text: title, color: IronTheme.ember)
            HStack(spacing: 6) {
                adjustment(-1, symbol: "minus")
                Text("\(Int(draft))")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(IronTheme.ember)
                    .frame(maxWidth: .infinity)
                    .focusable()
                    .focused($crownFocused)
                    .digitalCrownRotation($draft, from: range.lowerBound, through: range.upperBound,
                                          by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                adjustment(1, symbol: "plus")
            }
            Text("Turn the Crown or tap + / −")
                .font(.system(size: 11)).foregroundStyle(.secondary)
            Button(saveTitle) { value = draft; dismiss() }
                .buttonStyle(IronButtonStyle())
        }
        .padding(.horizontal, 8)
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .onAppear {
            if !loaded { draft = value; loaded = true }
            crownFocused = true
        }
    }

    private func adjustment(_ amount: Double, symbol: String) -> some View {
        Button {
            draft = min(range.upperBound, max(range.lowerBound, draft + amount))
            WKInterfaceDevice.current().play(.click)
        } label: {
            Image(systemName: symbol)
                .frame(width: 36, height: 44)
                .background(IronTheme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(amount > 0 ? "Increase \(title)" : "Decrease \(title)")
    }
}

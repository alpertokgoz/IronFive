import SwiftUI
import WatchKit

struct AmrapInputView: View {
    @Binding var reps: Int
    let liftName: String
    let weight: Double
    let weightUnit: WeightUnit
    var onDone: () -> Void
    @FocusState private var isFocused: Bool
    @State private var draftReps = 1.0

    var body: some View {
        VStack(spacing: 7) {
            IronEyebrow(text: "AMRAP · \(liftName)", color: IronTheme.ember)
            Text("\(IronTheme.weight(weight)) \(weightUnit.label)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                repButton(-1, symbol: "minus")
                VStack(spacing: 0) {
                    Text("\(Int(draftReps))")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(IronTheme.ember)
                        .focusable()
                        .focused($isFocused)
                        .digitalCrownRotation($draftReps, from: 0, through: 100, by: 1,
                                              sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
                    IronEyebrow(text: "Reps completed")
                }
                .frame(maxWidth: .infinity)
                repButton(1, symbol: "plus")
            }
            Button("Save reps") {
                reps = Int(draftReps)
                WKInterfaceDevice.current().play(.success)
                onDone()
            }
            .buttonStyle(IronButtonStyle())
        }
        .padding(.horizontal, 8)
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .onAppear {
            draftReps = Double(reps)
            isFocused = true
        }
    }

    private func repButton(_ amount: Double, symbol: String) -> some View {
        Button { draftReps = min(100, max(0, draftReps + amount)) } label: {
            Image(systemName: symbol)
                .frame(width: 30, height: 40)
                .background(IronTheme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(amount > 0 ? "One more rep" : "One fewer rep")
    }
}

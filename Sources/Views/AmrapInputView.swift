import SwiftUI

struct AmrapInputView: View {
    @Binding var reps: Int
    let liftName: String
    let weight: Double
    let weightUnit: WeightUnit
    var onDone: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            // Context: what movement + weight this is for
            VStack(spacing: 1) {
                Text(liftName.uppercased())
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.secondary)
                Text("\(String(format: "%.1f", weight)) \(weightUnit.label)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.orange)
            }

            Text("How many reps?")
                .font(.system(size: 14, weight: .black, design: .rounded))

            HStack(spacing: 4) {
                Text("\(reps)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(isFocused ? .black : .accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isFocused ? Color.accentColor : Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .focusable()
                    .focused($isFocused)
                    .digitalCrownRotation($reps.toDouble(), from: 0, through: 50, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)

                Text("REPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }

            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .onAppear {
            isFocused = true
        }
    }
}

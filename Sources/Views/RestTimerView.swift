import SwiftUI

struct RestTimerView: View {
    let timeRemaining: Int
    var liftColor: Color = IronTheme.ember
    var nextSet: String = "Next set"
    var onAdjust: (Int) -> Void
    var onSkip: () -> Void

    @Environment(\.isLuminanceReduced) private var isLuminanceReduced
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var initialTime = 0

    private var progress: Double {
        min(1, max(0, Double(timeRemaining) / Double(max(initialTime, 1))))
    }

    private var accent: Color { timeRemaining <= 10 ? IronTheme.mint : liftColor }

    var body: some View {
        GeometryReader { geometry in
            let diameter = min(112, max(46, geometry.size.height - 108))
            VStack(spacing: 4) {
                IronEyebrow(text: timeRemaining <= 3 ? "Get ready" : "Recover", color: accent)
                ZStack {
                    Circle().stroke(.white.opacity(0.09), lineWidth: isLuminanceReduced ? 2 : 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accent, style: StrokeStyle(lineWidth: isLuminanceReduced ? 2 : 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(reduceMotion ? nil : .linear(duration: 0.5), value: timeRemaining)
                    Text(String(format: "%d:%02d", timeRemaining / 60, timeRemaining % 60))
                        .font(.system(size: diameter > 90 ? 34 : diameter > 60 ? 26 : 20, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .accessibilityLabel("\(timeRemaining) seconds remaining")
                }
                .frame(width: diameter, height: diameter)
                .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
                if !isLuminanceReduced {
                    HStack(spacing: 6) {
                        adjustmentButton(-30, label: "−30s")
                        adjustmentButton(30, label: "+30s")
                    }
                    Button(action: onSkip) {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Next set")
                                Text(nextSet)
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            Spacer(minLength: 3)
                            Image(systemName: "arrow.right")
                        }
                        .padding(.horizontal, 12)
                    }
                    .buttonStyle(IronButtonStyle(accent: accent))
                    .accessibilityLabel("Skip remaining rest. \(nextSet)")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(IronTheme.canvas.ignoresSafeArea())
        }
        .onAppear { initialTime = timeRemaining }
        .onChange(of: timeRemaining) { _, value in initialTime = max(initialTime, value) }
    }

    private func adjustmentButton(_ seconds: Int, label: String) -> some View {
        Button { onAdjust(seconds) } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(IronTheme.surface, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(seconds > 0 ? "Add 30 seconds of rest" : "Remove 30 seconds of rest")
    }
}

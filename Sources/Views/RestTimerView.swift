import SwiftUI
import WatchKit

struct RestTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var isPresented: Bool
    var liftColor: Color = .orange
    var onDismiss: () -> Void

    @State private var initialTime: Int = 0

    private var progress: Double {
        Double(timeRemaining) / Double(max(initialTime, 1))
    }

    private var ringColor: Color {
        if timeRemaining <= 10 { return .red }
        if timeRemaining <= 30 { return .orange }
        return liftColor
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            VStack(spacing: 10) {
                Text("REST")
                    .font(.system(.footnote, design: .rounded, weight: .black))
                    .foregroundColor(liftColor)
                    .kerning(2.0)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(ringColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)

                    VStack(spacing: -4) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(timeRemaining <= 10 ? .red : .primary)
                            .contentTransition(.numericText())
                        Text("SEC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)
                .onAppear {
                    if initialTime == 0 { initialTime = timeRemaining }
                }

                // +30 / -30 row
                HStack(spacing: 8) {
                    Button(action: {
                        timeRemaining = max(5, timeRemaining - 30)
                    }) {
                        Text("-30s")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .frame(width: 46, height: 28)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        timeRemaining += 30
                        initialTime = max(initialTime, timeRemaining)
                    }) {
                        Text("+30s")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .frame(width: 46, height: 28)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    withAnimation {
                        isPresented = false
                        onDismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("SKIP")
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .frame(width: 90, height: 36)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

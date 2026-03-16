import SwiftUI

struct RestTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var isPresented: Bool
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 12) {
                Text("REST")
                    .font(.system(.footnote, design: .rounded, weight: .black))
                    .foregroundColor(.accentColor)
                    .kerning(2.0)

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: Double(timeRemaining) / 90.0)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)

                    VStack(spacing: -4) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                        Text("SEC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

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

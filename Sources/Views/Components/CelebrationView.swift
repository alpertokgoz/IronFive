import SwiftUI

struct CelebrationView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var showText = false

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let symbol: String
        let size: CGFloat
        var opacity: Double = 1.0
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.symbol)
                    .font(.system(size: p.size))
                    .foregroundColor(p.color)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
            VStack(spacing: 4) {
                Text("🏋️").font(.system(size: 30))
                Text("SAVED").font(.system(size: 14, weight: .black, design: .rounded))
            }
        }
        .onAppear {
            spawnConfetti()
            showText = true
        }
    }

    private func spawnConfetti() {
        let symbols = ["💪", "🔥", "✨", "🎉"]
        let colors: [Color] = [.orange, .blue, .green, .purple]
        for i in 0..<12 {
            particles.append(ConfettiParticle(
                x: CGFloat.random(in: 20...160),
                y: -10,
                color: colors.randomElement()!,
                symbol: symbols.randomElement()!,
                size: 12
            ))
            let index = particles.count - 1
            withAnimation(.interpolatingSpring(stiffness: 30, damping: 6).delay(Double(i)*0.1)) {
                particles[index].y = CGFloat.random(in: 40...140)
            }
        }
    }
}

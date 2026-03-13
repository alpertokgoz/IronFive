import SwiftUI

struct ParticleBurstView: View {
    @State private var particles: [Particle] = []

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var speedX: CGFloat
        var speedY: CGFloat
        let color: Color
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 4, height: 4)
                        .scaleEffect(p.scale)
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                for _ in 0..<12 {
                    let angle = Double.random(in: 0..<2 * .pi)
                    let speed = CGFloat.random(in: 10...30)
                    particles.append(Particle(
                        x: center.x,
                        y: center.y,
                        scale: CGFloat.random(in: 0.5...1.0),
                        opacity: 1,
                        speedX: cos(angle) * speed,
                        speedY: sin(angle) * speed,
                        color: [.green, .mint, .white].randomElement()!
                    ))
                }

                withAnimation(.easeOut(duration: 0.6)) {
                    for i in particles.indices {
                        particles[i].x += particles[i].speedX
                        particles[i].y += particles[i].speedY
                        particles[i].scale = 0
                        particles[i].opacity = 0
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

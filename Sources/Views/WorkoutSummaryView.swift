import SwiftUI

struct WorkoutSummaryView: View {
    @ObservedObject var workoutManager: WorkoutManager
    let profile: UserProfile
    let totalWeight: Double
    let showCelebration: Bool
    let amrapStep: WorkoutStep?
    let bestE1RM: Double
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow.gradient)
                Text(showCelebration ? "NEW PR!" : "WORKOUT SAVED")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(showCelebration ? .yellow : .white)
            }
            .padding(.top, 4)
            .padding(.bottom, 6)

            // Hero Stat: Volume
            VStack(alignment: .leading, spacing: 0) {
                Text("TOTAL VOLUME")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundColor(.accentColor)
                    .opacity(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(totalWeight))")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Text(profile.weightUnit.label.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor.opacity(0.1))
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 3)
                        .cornerRadius(1.5)
                        .padding(.vertical, 8)
                        .padding(.leading, 0)
                }
            )
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            // Health Stats Row
            HStack(spacing: 6) {
                CompactStatBox(
                    label: "KCAL",
                    value: workoutManager.activeEnergy > 0 ? "\(Int(workoutManager.activeEnergy))" : "—",
                    icon: "flame.fill",
                    color: .orange
                )
                CompactStatBox(
                    label: "BPM",
                    value: workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "—",
                    icon: "heart.fill",
                    color: .red
                )
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)

            // Finish Button
            Button(action: onFinish) {
                Text("FINISH")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 4)
            .padding(.bottom, 2)
        }
    }

}

struct CompactStatBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 11))
            VStack(alignment: .leading, spacing: -1) {
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                Text(label)
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

struct SummaryStatRow: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
                .frame(width: 20)

            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Text(unit)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

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

    let prDelta: Double?

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

                if let delta = prDelta, delta > 0 {
                    VStack(spacing: 0) {
                        Text("NEW PR!")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("+\(String(format: "%.1f", delta)) E1RM")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 2)
                }
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

import SwiftUI

struct SummaryTab: View {
    @ObservedObject var workoutManager: WorkoutManager
    let profile: UserProfile
    let totalWeight: Double
    let showCelebration: Bool
    let amrapStep: WorkoutStep?
    let bestE1RM: Double
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            if showCelebration {
                let amrapE1RM = amrapStep?.workoutSet.estimated1RM ?? 0
                let delta = (amrapE1RM > bestE1RM && bestE1RM > 0) ? (amrapE1RM - bestE1RM) : 0
                CelebrationView(prDelta: delta > 0 ? delta : nil)
                    .frame(height: 90)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.yellow.gradient)

                    Text("GREAT JOB!")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                }

                if let amrap = amrapStep {
                    VStack(spacing: 0) {
                        Text("SESSION BEST")
                            .font(.system(size: 6, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(amrap.workoutSet.actualReps)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.orange)
                            Text("REPS @ \(String(format: "%.1f", amrap.workoutSet.weight))\(profile.weightUnit.label)")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.1)))
                }

                // 2x2 Stats Grid
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        CompactStatBox(label: "KCAL", value: workoutManager.activeEnergy > 0 ? "\(Int(workoutManager.activeEnergy))" : "—", icon: "flame.fill", color: .orange)
                        CompactStatBox(label: "BPM", value: workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "—", icon: "heart.fill", color: .red)
                    }
                    HStack(spacing: 2) {
                        CompactStatBox(label: profile.weightUnit.label.uppercased(), value: "\(Int(totalWeight))", icon: "dumbbell.fill", color: .blue)
                        CompactStatBox(label: "TIME", value: workoutManager.elapsedTimeString, icon: "timer", color: .purple)
                    }
                }
                .padding(.horizontal, 2)

                Button(action: onFinish) {
                    Text("FINISH")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .padding(.top, 0)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

}

struct CompactStatBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 10))
            VStack(alignment: .leading, spacing: -2) {
                Text(value)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                Text(label)
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.06))
        .cornerRadius(6)
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

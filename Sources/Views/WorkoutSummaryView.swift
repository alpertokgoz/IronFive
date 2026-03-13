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
        ScrollView {
            VStack(spacing: 12) {
                if showCelebration {
                    CelebrationView()
                        .frame(height: 160)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.yellow.gradient)

                        Text("GREAT JOB!")
                            .font(.system(size: 16, weight: .black, design: .rounded))

                        Text("Cycle \(profile.currentCycle), Week \(profile.currentWeek)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)

                    VStack(spacing: 6) {
                        if let amrap = amrapStep {
                            VStack(spacing: 2) {
                                Text("AMRAP RESULT")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundColor(.orange)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(amrap.workoutSet.actualReps)")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(.orange)
                                    Text("REPS @ \(String(format: "%.1f", amrap.workoutSet.weight))\(profile.weightUnit.label)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                }

                                let currentE1RM = amrap.workoutSet.estimated1RM
                                if currentE1RM > 0 {
                                    HStack(spacing: 4) {
                                        Text("E1RM: \(String(format: "%.1f", currentE1RM))")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundColor(.yellow)

                                        if currentE1RM > bestE1RM && bestE1RM > 0 {
                                            Text("PR! +\(String(format: "%.1f", currentE1RM - bestE1RM))")
                                                .font(.system(size: 8, weight: .black))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.green)
                                                .cornerRadius(2)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
                            .padding(.bottom, 4)
                        }

                        SummaryStatRow(label: "ENERGY", value: "\(Int(workoutManager.activeEnergy))", unit: "kcal", icon: "flame.fill", color: .orange)
                        SummaryStatRow(label: "HEART RATE", value: "\(Int(workoutManager.heartRate))", unit: "bpm", icon: "heart.fill", color: .red)
                        SummaryStatRow(label: "TOTAL LIFTED", value: "\(Int(totalWeight))", unit: profile.weightUnit.label, icon: "dumbbell.fill", color: .blue)
                        SummaryStatRow(label: "TIME", value: workoutManager.elapsedTimeString, unit: "", icon: "timer", color: .purple)
                    }
                    .padding(.horizontal, 4)

                    Button(action: onFinish) {
                        Text("FINISH")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding(.horizontal)
        }
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

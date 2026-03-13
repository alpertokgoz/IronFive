import SwiftUI

struct SummaryTab: View {
    @ObservedObject var workoutManager: WorkoutManager
    let profile: UserProfile
    let totalWeight: Double
    let showCelebration: Bool
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
                    .padding(.top, 4)
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

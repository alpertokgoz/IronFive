import SwiftUI

struct WorkoutSummaryView: View {
    let workoutManager: WorkoutManager
    let profile: UserProfile
    let totalWeight: Double
    let showCelebration: Bool
    var completedSets: Int = 0
    var totalSets: Int = 0
    var personalBestReps: Int = 0
    var personalBestWeight: Double = 0
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: showCelebration ? "trophy.fill" : completedSets == totalSets ? "checkmark.circle.fill" : "circle.lefthalf.filled")
                        .foregroundStyle(IronTheme.mint)
                    Text(showCelebration ? "New personal best" : completedSets == totalSets ? "Strong work." : "Session so far")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text(showCelebration && personalBestReps > 0
                     ? "\(personalBestReps) × \(IronTheme.weight(personalBestWeight)) \(profile.weightUnit.label) · Personal best"
                     : "\(completedSets) of \(totalSets) sets logged")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                VStack(spacing: 0) {
                    Text(workoutManager.elapsedTimeString)
                        .font(.system(size: geometry.size.height < 175 ? 30 : 40, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    IronEyebrow(text: "Training time")
                }
                HStack(spacing: 10) {
                    IronMetric(title: "Volume", value: IronTheme.weight(totalWeight), unit: profile.weightUnit.label, accent: profile.weightUnit == .kg ? IronTheme.mint : IronTheme.ember)
                    IronMetric(title: "Energy", value: workoutManager.activeEnergy > 0 ? "\(Int(workoutManager.activeEnergy))" : "—", unit: "kcal")
                }
                .padding(.horizontal, 6)
                Spacer(minLength: 0)
                Button(action: onFinish) {
                    Label(showCelebration ? "Saving…" : "Save workout", systemImage: "checkmark")
                }
                .buttonStyle(IronButtonStyle())
                .disabled(showCelebration)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { appeared = true }
            }
        }
    }
}

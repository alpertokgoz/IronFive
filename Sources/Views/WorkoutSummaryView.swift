import SwiftUI

struct WorkoutSummaryView: View {
    @ObservedObject var workoutManager: WorkoutManager
    let profile: UserProfile
    let totalWeight: Double
    let showCelebration: Bool
    let onFinish: () -> Void

    @State private var animateEmoji = false

    var body: some View {
        VStack(spacing: 0) {
            celebrationHeader()
            durationHero()
            statsRow()

            Spacer(minLength: 0)

            finishButton()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.black.gradient, for: .navigation)
        .onAppear {
            withAnimation(
                .interpolatingSpring(stiffness: 120, damping: 8)
                .delay(0.2)
            ) {
                animateEmoji = true
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func celebrationHeader() -> some View {
        VStack(spacing: -1) {
            Text(showCelebration ? "🏆" : "💪")
                .font(.system(size: 22))
                .scaleEffect(animateEmoji ? 1.0 : 0.3)
                .opacity(animateEmoji ? 1.0 : 0.0)

            Text(showCelebration ? "NEW PR!" : "GREAT WORK!")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(
                    showCelebration
                        ? AnyShapeStyle(.yellow.gradient)
                        : AnyShapeStyle(.white)
                )
        }
        .padding(.bottom, 2)
        .padding(.top, 4) // Add a little top padding so it doesn't hit the status bar
    }

    // MARK: - Duration Hero

    @ViewBuilder
    private func durationHero() -> some View {
        VStack(spacing: -2) {
            Text(workoutManager.elapsedTimeString)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .monospacedDigit()
            Text("DURATION")
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    // MARK: - Stats Row

    @ViewBuilder
    private func statsRow() -> some View {
        HStack(spacing: 6) {
            CompactStatBox(
                label: "KCAL",
                value: workoutManager.activeEnergy > 0
                    ? "\(Int(workoutManager.activeEnergy))" : "—",
                icon: "flame.fill",
                color: .orange
            )
            CompactStatBox(
                label: profile.weightUnit.label.uppercased(),
                value: "\(Int(totalWeight))",
                icon: "dumbbell.fill",
                color: .blue
            )
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Finish Button

    @ViewBuilder
    private func finishButton() -> some View {
        Button(action: onFinish) {
            Label("FINISH", systemImage: "checkmark")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .padding(.horizontal, 4)
        .padding(.bottom, 0)
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
                .font(.system(size: 10))
            VStack(alignment: .leading, spacing: -1) {
                Text(value)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                Text(label)
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }
}

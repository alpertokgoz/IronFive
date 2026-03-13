import SwiftUI

struct WorkoutStepView: View {
    let lift: MainLift
    @Binding var step: WorkoutStep
    let allSteps: [WorkoutStep]
    @Binding var selectedTab: Int
    let nextTab: Int
    let workoutSessions: [WorkoutSession]
    var onRestStart: () -> Void
    var onPlateCalc: (Double) -> Void

    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack(spacing: 2) {
            // Moved progress and skip above the main card to prevent clipping
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    let currentPhaseSteps = allSteps.filter { $0.title == step.title }
                    let currentIdx = currentPhaseSteps.firstIndex(where: { $0.id == step.id }) ?? 0

                    Text("\(currentIdx + 1)/\(currentPhaseSteps.count) SET")
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))

                    HStack(spacing: 3) {
                        ForEach(0..<currentPhaseSteps.count, id: \.self) { i in
                            let s = currentPhaseSteps[i]
                            let isCurrent = (s.id == step.id)
                            let isCompleted = s.workoutSet.isCompleted

                            Capsule()
                                .fill(isCurrent ? .white : (isCompleted ? .green : .white.opacity(0.15)))
                                .frame(width: isCurrent ? 10 : 5, height: 2.5)
                                .animation(.spring(), value: isCurrent)
                        }
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation { selectedTab = nextTab }
                }) {
                    Text("SKIP")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Spacer(minLength: 0)

            // PR Goal Badge
            if step.isAMRAP {
                if let prReps = calculateRepsToBeatPR() {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                        Text("GOAL: \(prReps) REPS")
                    }
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(4)
                    .padding(.bottom, 2)
                }
            } else if let pct = step.percentage {
                Text("\(pct)%")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(lift.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lift.color.opacity(0.15))
                    .cornerRadius(4)
                    .padding(.bottom, 2)
            }

            SetRowView(
                workoutSet: $step.workoutSet,
                isAMRAP: step.isAMRAP,
                lift: lift,
                prGoal: step.isAMRAP ? calculateRepsToBeatPR() : nil,
                onComplete: onRestStart,
                onPlateCalc: { onPlateCalc(step.workoutSet.weight) }
            )
                .padding(.horizontal, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(step.isAMRAP ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
                        .padding(.horizontal, 4)
                )
        }
        .padding(.bottom, 2)
    }

    private func calculateRepsToBeatPR() -> Int? {
        let liftSessions = workoutSessions.filter { $0.mainLift == lift && $0.isCompleted }
        let currentBestE1RM = liftSessions.map { $0.estimated1RM }.max() ?? 0

        if currentBestE1RM == 0 { return nil }

        let weight = step.workoutSet.weight
        if weight == 0 { return nil }

        // Epley: e1RM = W * (1 + 0.0333 * R)
        // R = (e1RM / W - 1) / 0.0333
        let neededReps = (currentBestE1RM / weight - 1) / 0.0333
        let target = Int(ceil(neededReps))
        return max(target, 1)
    }
}

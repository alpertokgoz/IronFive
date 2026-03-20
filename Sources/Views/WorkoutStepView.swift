import SwiftUI

struct WorkoutStepView: View {
    let lift: MainLift
    @Binding var step: WorkoutStep
    let allSteps: [WorkoutStep]
    @Binding var selectedTab: Int
    let nextTab: Int
    let workoutSessions: [WorkoutSession]
    let weightUnit: WeightUnit
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

                    Text("\(currentIdx + 1)/\(currentPhaseSteps.count)")
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

                Image(systemName: "chevron.right.2")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Spacer(minLength: 0)

            // Last Performance / PR Goal Badge
            if step.isAMRAP {
                if let last = getLastAmrapPerformance() {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("LAST: \(last.reps) × \(Int(last.weight))\(weightUnit.label)")
                    }
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(4)
                    .padding(.bottom, 2)
                }
            }

            SetRowView(
                workoutSet: $step.workoutSet,
                isAMRAP: step.isAMRAP,
                lift: lift,
                prGoal: nil, // We show last performance above instead
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
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -50 {
                        WKInterfaceDevice.current().play(.directionUp)
                        withAnimation { selectedTab = nextTab }
                    }
                }
        )
    }

    private func getLastAmrapPerformance() -> (reps: Int, weight: Double)? {
        let lastSession = workoutSessions.first { $0.mainLift == lift && $0.isCompleted }
        guard let last = lastSession, last.amrapReps > 0 else { return nil }
        return (last.amrapReps, last.amrapWeight)
    }

    // Keeping calculateRepsToBeatPR for internal logic if needed later, but removing from UI
    private func calculateRepsToBeatPR() -> Int? {
        let liftSessions = workoutSessions.filter { $0.mainLift == lift && $0.isCompleted }
        let currentBestE1RM = liftSessions.map { $0.estimated1RM }.max() ?? 0

        if currentBestE1RM == 0 { return nil }

        let weight = step.workoutSet.weight
        if weight == 0 { return nil }

        let neededReps = (currentBestE1RM / weight - 1) / 0.0333
        let target = Int(ceil(neededReps))
        return max(target, 1)
    }
}

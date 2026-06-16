import SwiftUI

struct WorkoutStepView: View {
    let lift: MainLift
    @Binding var step: WorkoutStep
    let allSteps: [WorkoutStep]
    @Binding var selectedTab: Int
    let nextTab: Int
    let workoutSessions: [WorkoutSession]
    let weightUnit: WeightUnit
    var isAutopilotEnabled: Bool = false
    var onRestStart: () -> Void
    var onPlateCalc: (Double) -> Void
    var onSave: () -> Void

    @Environment(WorkoutManager.self) var workoutManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    var body: some View {
        VStack(spacing: 2) {
            if step.isAMRAP, let lastPerformance = getLastAmrapPerformance() {
                Text("LAST: \(lastPerformance.reps) × \(Int(lastPerformance.weight)) \(weightUnit.label)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 2)
            }
            SetRowView(
                workoutSet: $step.workoutSet,
                isAMRAP: step.isAMRAP,
                lift: lift,
                weightUnit: weightUnit,
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
                .opacity(isLuminanceReduced ? 0.6 : 1.0)
                .onChange(of: step.workoutSet.isCompleted) { _, _ in
                    onSave()
                    if step.workoutSet.isCompleted && isAutopilotEnabled {
                        onRestStart()
                    }
                }
                .onChange(of: step.workoutSet.actualReps) { _, _ in
                    onSave()
                }
                .onChange(of: step.workoutSet.weight) { _, _ in
                    onSave()
                }
        }
        .padding(.bottom, 2)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    if value.translation.width < -50 {
                        WKInterfaceDevice.current().play(.directionUp)
                        withAnimation { selectedTab = nextTab }
                        onSave()
                    } else if value.translation.width > 50 && selectedTab > 0 {
                        WKInterfaceDevice.current().play(.directionDown)
                        withAnimation { selectedTab -= 1 }
                        onSave()
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

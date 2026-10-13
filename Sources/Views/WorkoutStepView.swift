import SwiftUI
import WatchKit

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

    var body: some View {
            VStack(spacing: 4) {
                if step.isAMRAP {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right").foregroundStyle(lift.color)
                        Text(lastPerformance)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                }
                SetRowView(
                    workoutSet: $step.workoutSet, isAMRAP: step.isAMRAP,
                    lift: lift, weightUnit: weightUnit, prGoal: nil,
                    compact: true,
                    onComplete: {
                        onSave()
                        if isAutopilotEnabled && !step.isAMRAP { onRestStart() }
                    },
                    onPlateCalc: { onPlateCalc(step.workoutSet.weight) },
                    onRest: onRestStart,
                    onNext: {
                        WKInterfaceDevice.current().play(.directionUp)
                        withAnimation { selectedTab = min(nextTab, allSteps.count) }
                    }
                )
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .onChange(of: step.workoutSet) { _, _ in onSave() }
    }

    private var lastPerformance: String {
        guard let last = workoutSessions.first(where: { $0.mainLift == lift && $0.isCompleted && $0.amrapReps > 0 }) else {
            return "AMRAP · as many good reps as possible"
        }
        return "Last time \(last.amrapReps) × \(IronTheme.weight(last.amrapWeight)) \(weightUnit.label)"
    }
}

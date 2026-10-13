import SwiftUI
import WatchKit

struct SetRowView: View {
    @Binding var workoutSet: WorkoutSet
    let isAMRAP: Bool
    let lift: MainLift
    let weightUnit: WeightUnit
    let prGoal: Int?
    var compact = false
    var onComplete: () -> Void
    var onPlateCalc: () -> Void
    var onRest: () -> Void
    var onNext: () -> Void

    @State private var showAmrapSheet = false
    @State private var showWeightEditor = false
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        VStack(spacing: compact ? 4 : 7) {
            Button { showWeightEditor = true } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(workoutSet.weight == 0 ? (workoutSet.type == .accessory ? "—" : "BW") : IronTheme.weight(workoutSet.weight))
                            .font(.system(size: compact ? 36 : 46, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        HStack(spacing: 4) {
                            Text(workoutSet.weight == 0 ? (workoutSet.type == .accessory ? "No added weight" : "Bodyweight") : weightUnit.label)
                            Image(systemName: "pencil").font(.system(size: 8))
                        }
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(workoutSet.isCompleted ? "\(workoutSet.completedReps)" : workoutSet.reps)
                            .font(.system(size: compact ? 26 : 32, weight: .semibold, design: .rounded))
                            .foregroundStyle(workoutSet.isCompleted ? IronTheme.mint : lift.color)
                        IronEyebrow(text: "Reps")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Weight, \(IronTheme.weight(workoutSet.weight)) \(weightUnit.label). Tap to edit.")

            if !workoutSet.isCompleted && workoutSet.type != .accessory && workoutSet.weight > weightUnit.barWeight {
                HStack(spacing: 5) {
                    CompactPlateStackView(targetWeight: workoutSet.weight, unit: weightUnit)
                    Spacer(minLength: 0)
                    Text("/ side").font(.system(size: 9)).foregroundStyle(.secondary)
                }
                .frame(height: 18)
                .accessibilityElement(children: .combine)
            }

            if !isLuminanceReduced {
                if workoutSet.isCompleted {
                    HStack(spacing: 6) {
                        Button(action: onRest) { Label("Rest", systemImage: "timer") }
                            .buttonStyle(IronButtonStyle(secondary: true))
                        Button(action: onNext) { Label("Next", systemImage: "arrow.right") }
                            .buttonStyle(IronButtonStyle(accent: lift.color))
                    }
                } else {
                    Button(action: handleCompletion) {
                        Label(isAMRAP ? "Log your reps" : "Log set", systemImage: "checkmark")
                    }
                    .buttonStyle(IronButtonStyle(accent: lift.color))
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .sheet(isPresented: $showAmrapSheet) {
            AmrapInputView(reps: $workoutSet.actualReps, liftName: lift.name,
                           weight: workoutSet.weight, weightUnit: weightUnit) {
                showAmrapSheet = false
                markCompleted()
            }
        }
        .sheet(isPresented: $showWeightEditor) {
            SetWeightEditor(weight: $workoutSet.weight, unit: weightUnit, accent: lift.color,
                            isBarbell: workoutSet.type != .accessory)
        }
        .accessibilityAction(named: "Undo set") {
            if workoutSet.isCompleted { undoCompletion() }
        }
    }

    private func handleCompletion() {
        if isAMRAP {
            if workoutSet.actualReps == 0 {
                workoutSet.actualReps = Int(workoutSet.reps.replacingOccurrences(of: "+", with: "")) ?? 1
            }
            showAmrapSheet = true
        } else {
            markCompleted()
        }
    }

    private func markCompleted() {
        WKInterfaceDevice.current().play(.directionUp)
        workoutSet.isCompleted = true
        onComplete()
    }

    private func undoCompletion() {
        workoutSet.isCompleted = false
        WKInterfaceDevice.current().play(.directionDown)
    }
}

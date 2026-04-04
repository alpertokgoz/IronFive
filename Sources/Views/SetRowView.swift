import SwiftUI

struct SetRowView: View {
    @Binding var workoutSet: WorkoutSet
    let isAMRAP: Bool
    let lift: MainLift
    let weightUnit: WeightUnit
    let prGoal: Int?
    var onComplete: () -> Void
    var onPlateCalc: () -> Void

    @FocusState private var isRepFieldFocused: Bool
    @State private var scale: CGFloat = 1.0
    @State private var showParticles = false
    @State private var showAmrapSheet = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: onPlateCalc) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        if workoutSet.weight > 0 {
                            Text("\(String(format: "%.1f", workoutSet.weight))")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                            Text(weightUnit.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        } else {
                            Text("BW")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundStyle(workoutSet.isCompleted ? .secondary : .primary)
                }
                .buttonStyle(.plain)
                .disabled(workoutSet.weight == 0)

                if isAMRAP {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(workoutSet.reps)
                                .foregroundColor(.orange)
                            Text("REPS")
                                .foregroundColor(.secondary)
                        }
                        .font(.system(size: 14, weight: .black, design: .rounded))

                        if workoutSet.isCompleted {
                            Text("DONE: \(workoutSet.actualReps)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(workoutSet.reps)")
                            .foregroundColor(.orange)
                        Text("REPS")
                            .foregroundColor(.secondary)
                    }
                    .font(.system(size: 14, weight: .black, design: .rounded))
                }

            }

            Spacer()

            Button(action: {
                handleCompletion()
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .background(Circle().fill(Color.white.opacity(0.05)))

                    Circle()
                        .fill(isAMRAP ? Color.orange : Color.green)
                        .scaleEffect(workoutSet.isCompleted ? 1.0 : 0.001)
                        .opacity(workoutSet.isCompleted ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: workoutSet.isCompleted)

                    if workoutSet.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.black)
                            .transition(.scale.combined(with: .opacity))
                    }

                    if showParticles {
                        ParticleBurstView()
                    }
                }
                .frame(width: 36, height: 36)
                .scaleEffect(scale)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(lift.color.opacity(0.1))
        )
        .overlay(alignment: .trailing) {
            if !workoutSet.isCompleted {
                Text("TAP")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.trailing, 18)
            }
        }
        .sheet(isPresented: $showAmrapSheet) {
            AmrapInputView(
                reps: $workoutSet.actualReps,
                liftName: lift.name,
                weight: workoutSet.weight,
                weightUnit: weightUnit
            ) {
                showAmrapSheet = false
                if workoutSet.actualReps == 0 {
                    workoutSet.actualReps = Int(workoutSet.reps.replacingOccurrences(of: "+", with: "")) ?? 0
                }
                markCompleted()
            }
        }
    }

    private func handleCompletion() {
        if !workoutSet.isCompleted {
            if isAMRAP {
                showAmrapSheet = true
            } else {
                markCompleted()
            }
        } else {
            WKInterfaceDevice.current().play(.directionDown)
            withAnimation(.spring()) {
                workoutSet.isCompleted = false
                showParticles = false
            }
        }
    }

    private func markCompleted() {
        if let goal = prGoal, workoutSet.actualReps >= goal {
            WKInterfaceDevice.current().play(.notification)
        } else {
            WKInterfaceDevice.current().play(.success)
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 0.9
            workoutSet.isCompleted = true
            showParticles = true
            onComplete()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { scale = 1.0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showParticles = false
        }
    }
}

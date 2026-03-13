import SwiftUI

struct WorkoutStepView: View {
    let lift: MainLift
    @Binding var step: WorkoutStep
    let allSteps: [WorkoutStep]
    @Binding var selectedTab: Int
    let nextTab: Int
    var onRestStart: () -> Void
    var onPlateCalc: (Double) -> Void

    @EnvironmentObject var workoutManager: WorkoutManager
    // Note: Query might need to be passed or handled differently if moved out
    // For now, let's see if we can keep it as is or if we need to pass the PR reps
    let prRepsToBeat: Int?

    var body: some View {
        VStack(spacing: 2) {
            Spacer(minLength: 0)

            if let icon = step.liftIcon {
                Image(systemName: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .fontWeight(.black)
                    .foregroundStyle(lift.color.gradient)
                    .padding(.bottom, 2)
            }

            // PR Goal Badge
            if step.isAMRAP {
                if let prReps = prRepsToBeat {
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
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .padding(.bottom, 2)
            }

            SetRowView(workoutSet: $step.workoutSet, isAMRAP: step.isAMRAP, onComplete: onRestStart, onPlateCalc: { onPlateCalc(step.workoutSet.weight) })
                .padding(.horizontal, 4)

            Spacer(minLength: 0)

            // Unified Progress Component and Skip Button
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
            .padding(.bottom, 15) // Reclaim safe area space
            .padding(.horizontal, 2)
        }
    }
}

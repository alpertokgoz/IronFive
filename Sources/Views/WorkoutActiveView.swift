import SwiftUI
import SwiftData
import UserNotifications

struct WorkoutActiveView: View {
    let lift: MainLift
    let profile: UserProfile
    let accessories: [AccessoryExercise]

    @Environment(\.modelContext) var modelContext
    @Environment(WorkoutManager.self) var workoutManager
    @Environment(\.dismiss) var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) var workoutSessions: [WorkoutSession]

    @State var selectedTab = 0
    @State var steps: [WorkoutStep] = []

    // Rest Timer State
    @State var showRestTimer = false
    @State var restTimeRemaining = 90
    @State var timer: Timer?
    @State var lastTimerTick: Date = Date()

    // Plate Calculator State
    @State var selectedWeightForCalc: Double?

    // Finish State
    @State var showFinishConfirmation = false
    @State var showCelebration = false
    @State var showCycleSummary = false
    @State var finalAmrapReps = 0
    @State var finalAmrapWeight = 0.0

    // Phase Transition State
    @State var showPhaseTransition = false
    @State var currentPhaseTitle = ""

    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    var body: some View {
        VStack(spacing: 0) {
            if selectedTab < steps.count {
                headerView()
            }

            contentView()
            .tabViewStyle(.page(indexDisplayMode: .never))

            if selectedTab < steps.count && !isLuminanceReduced {
                // Real-time Stats Footer - Hidden on Summary Tab to avoid redundancy
                HStack {
                    HStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(heartRateColor(for: workoutManager.heartRate), lineWidth: 1.2)
                                .frame(width: 14, height: 14)
                            Image(systemName: "heart.fill")
                                .foregroundColor(heartRateColor(for: workoutManager.heartRate))
                                .font(.system(size: 7))
                        }
                        Text(workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "—")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Text("BPM")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .foregroundColor(.purple)
                            .font(.system(size: 10))
                        Text(workoutManager.elapsedTimeString)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 2)
                .background(Color.black.opacity(0.3))
            }
        }
        .containerBackground(lift.color.gradient, for: .navigation)
        .onAppear {
            setupWorkout()
            workoutManager.startWorkout()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        .overlay {
            if showRestTimer {
                RestTimerView(timeRemaining: $restTimeRemaining, isPresented: $showRestTimer, liftColor: lift.color) {
                    advanceTab()
                }
            }
            if showPhaseTransition {
                ZStack {
                    Color.black.opacity(0.85).ignoresSafeArea()
                    VStack {
                        Text("UP NEXT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(currentPhaseTitle.uppercased())
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(lift.color)
                    }
                }
                .transition(.opacity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showFinishConfirmation = true }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .sheet(item: Binding(
            get: { selectedWeightForCalc.map { WeightIdentifiable(weight: $0) } },
            set: { selectedWeightForCalc = $0?.weight }
        )) { item in
            PlateCalculatorView(targetWeight: item.weight, unit: profile.weightUnit)
        }
        .fullScreenCover(isPresented: $showCycleSummary) {
            NavigationStack {
                CycleSummaryView(
                    profile: profile,
                    lastLift: lift,
                    amrapReps: finalAmrapReps,
                    amrapWeight: finalAmrapWeight,
                    onComplete: {
                        dismiss()
                    }
                )
            }
        }
        .animation(.spring(), value: showRestTimer)
        .alert("Finish Workout?", isPresented: $showFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save & Exit") {
                triggerCelebration()
            }
        } message: {
            Text("Your session will be saved.")
        }
    }

    private func heartRateColor(for rate: Double) -> Color {
        guard rate > 0 else { return .secondary }
        let maxHR = Double(220 - profile.age)
        let percent = rate / maxHR

        if percent < 0.60 {
            return .blue
        } else if percent < 0.70 {
            return .green
        } else if percent < 0.80 {
            return .yellow
        } else if percent < 0.90 {
            return .orange
        } else {
            return .red
        }
    }
}

#Preview {
    WorkoutActiveView(lift: .squat, profile: UserProfile(), accessories: [])
        .environment(WorkoutManager())
}

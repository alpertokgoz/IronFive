import SwiftUI
import SwiftData
import UserNotifications

struct WorkoutActiveView: View {
    let lift: MainLift
    let profile: UserProfile
    let accessories: [AccessoryExercise]
    var initialStepIndex: Int?
    var initialStepCompleted: Bool?
    var initialDialog: String?

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
    @State var restCountdown = RestCountdown()
    @State var didSetupWorkout = false
    @State var didFinishWorkout = false
    @State var workoutError: String?
    @Environment(\.scenePhase) var scenePhase

    // Plate Calculator State
    @State var selectedWeightForCalc: Double?

    // Finish State
    @State var showFinishConfirmation = false
    @State var showWorkoutActions = false
    @State var showCelebration = false
    @State var showCycleSummary = false
    @State var finalAmrapReps = 0
    @State var finalAmrapWeight = 0.0

    // Phase Transition State
    @State var showPhaseTransition = false
    @State var currentPhaseTitle = ""

    @Environment(\.isLuminanceReduced) var isLuminanceReduced

    var body: some View {
        contentView()
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .onAppear {
            if !didSetupWorkout {
                setupWorkout()
                if let index = initialStepIndex {
                    selectedTab = min(max(0, index), steps.count)
                    if let completed = initialStepCompleted, steps.indices.contains(selectedTab) {
                        steps[selectedTab].workoutSet.isCompleted = completed
                    }
                }
                showWorkoutActions = initialDialog == "actions"
                showFinishConfirmation = initialDialog == "finish"
                didSetupWorkout = true
            }
            if !steps.isEmpty && !didFinishWorkout {
                workoutManager.startOrResumeWorkout()
                resumeRestTimer()
            }
            if !DesignPreview.isEnabled {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
            saveActiveSession()
        }
        .onChange(of: selectedTab) { _, _ in saveActiveSession() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { resumeRestTimer() }
        }
        .overlay {
            if showRestTimer {
                RestTimerView(
                    timeRemaining: restTimeRemaining,
                    liftColor: lift.color,
                    nextSet: nextRestSet,
                    onAdjust: adjustRestTimer,
                    onSkip: completeRestTimer
                )
            }
            if showPhaseTransition && !showRestTimer {
                VStack {
                    IronEyebrow(text: "\(currentPhaseTitle) ready", color: lift.color)
                        .padding(8)
                        .background(.black.opacity(0.9), in: Capsule())
                    Spacer()
                }
                .allowsHitTesting(false)
            }
        }

        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showWorkoutActions = true } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("Workout actions")
            }
        }
        .confirmationDialog("Workout actions", isPresented: $showWorkoutActions, titleVisibility: .visible) {
            Button("Finish & save") { showFinishConfirmation = true }
            Button("Pause & exit") {
                saveActiveSession()
                workoutManager.pauseWorkout()
                dismiss()
            }
            .disabled(workoutManager.isPreparing)
            if steps.indices.contains(selectedTab) && steps[selectedTab].workoutSet.isCompleted {
                Button("Undo current set") {
                    stopRestTimer()
                    steps[selectedTab].workoutSet.isCompleted = false
                    saveActiveSession()
                }
            }
            Button("Keep training", role: .cancel) { }
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
        .alert("Workout Error", isPresented: Binding(
            get: { workoutError != nil || workoutManager.workoutError != nil },
            set: { if !$0 { workoutError = nil; workoutManager.workoutError = nil } }
        )) {
            Button("OK") { workoutError = nil; workoutManager.workoutError = nil }
        } message: {
            Text(workoutError ?? workoutManager.workoutError ?? "Please try again.")
        }
        .animation(.spring(), value: showRestTimer)
        .navigationTitle(lift.shortName)
        .alert("Save workout?", isPresented: $showFinishConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save & Exit") {
                triggerCelebration()
            }
        } message: {
            Text(completedStepsCount() == steps.count ? "Your completed workout will be added to history." : "Save logged sets? Your training week will not advance.")
        }
    }

    func heartRateColor(for rate: Double) -> Color {
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

import SwiftUI
import SwiftData
import UserNotifications

struct WorkoutActiveView: View {
    let lift: MainLift
    let profile: UserProfile
    let accessories: [AccessoryExercise]

    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) var workoutSessions: [WorkoutSession]

    @State var selectedTab = 0
    @State var steps: [WorkoutStep] = []

    // Rest Timer State
    @State var showRestTimer = false
    @State var restTimeRemaining = 90
    @State var timer: Timer?

    // Plate Calculator State
    @State var selectedWeightForCalc: Double?

    // Finish State
    @State var showFinishConfirmation = false
    @State var showCelebration = false
    @State var showCycleSummary = false
    @State var finalAmrapReps = 0
    @State var finalAmrapWeight = 0.0

    var body: some View {
        VStack(spacing: 0) {
            headerView()

            contentView()
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Real-time Stats Footer
            HStack {
                HStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 10))
                    Text("\(Int(workoutManager.heartRate))")
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
                RestTimerView(timeRemaining: $restTimeRemaining, isPresented: $showRestTimer) {
                    advanceTab()
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
    }
}

#Preview {
    WorkoutActiveView(lift: .squat, profile: UserProfile(), accessories: [])
        .environmentObject(WorkoutManager())
}

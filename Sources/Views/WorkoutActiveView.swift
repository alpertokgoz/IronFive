import SwiftUI
import SwiftData
import UserNotifications

struct WorkoutActiveView: View {
    let lift: MainLift
    let profile: UserProfile
    let accessories: [AccessoryExercise]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]

    @State private var selectedTab = 0
    @State private var steps: [WorkoutStep] = []

    // Rest Timer State
    @State private var showRestTimer = false
    @State private var restTimeRemaining = 90
    @State private var timer: Timer?
    
    // Plate Calculator State
    @State private var selectedWeightForCalc: Double?
    
    // Finish State
    @State private var showFinishConfirmation = false
    @State private var showCelebration = false
    @State private var showCycleSummary = false
    @State private var finalAmrapReps = 0
    @State private var finalAmrapWeight = 0.0


    var body: some View {
        VStack(spacing: 0) {
            // Header: Title & Progress
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("CYCLE \(profile.currentCycle)")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        Text(weekName(for: profile.currentWeek).uppercased())
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .foregroundColor(.accentColor)
                    }
                    
                    Spacer()
                    
                    if selectedTab < steps.count {
                        let step = steps[selectedTab]
                        HStack(spacing: 4) {
                            if let icon = step.liftIcon {
                                Image(systemName: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 14, height: 14)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(lift.color.gradient)
                            }
                            Text(step.title.uppercased())
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    } else {
                        Text("COMPLETED")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 2)

                // Overall Workout Progress Bar
                ProgressView(value: Double(completedStepsCount), total: Double(steps.count))
                    .progressViewStyle(.linear)
                    .tint(.green)
                    .background(Color.white.opacity(0.15))
                    .frame(height: 2)
                    .clipShape(Capsule())
                    .padding(.horizontal, 4)
            }
            .padding(.bottom, 2)
            .background(Color.black.opacity(0.4))

            TabView(selection: $selectedTab) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    WorkoutStepView(
                        lift: lift,
                        step: $steps[index],
                        allSteps: steps,
                        selectedTab: $selectedTab,
                        nextTab: index + 1,
                        onRestStart: startRestTimer,
                        onPlateCalc: { weight in selectedWeightForCalc = weight },
                        prRepsToBeat: calculateRepsToBeatPR(for: steps[index])
                    )
                    .tag(index)
                }

                // Finish Tab
                SummaryTab(
                    workoutManager: workoutManager,
                    profile: profile,
                    totalWeight: totalWeightLifted,
                    showCelebration: showCelebration,
                    onFinish: { showFinishConfirmation = true }
                )
                .tag(steps.count)
                .alert("Finish Workout?", isPresented: $showFinishConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Finish", role: .destructive) {
                        triggerCelebration()
                    }
                } message: {
                    Text("This will save your session and advance your program.")
                }
            }
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
            .padding(.vertical, 4)
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

    private var completedStepsCount: Int {
        steps.filter { $0.workoutSet.isCompleted }.count
    }

    private var totalWeightLifted: Double {
        steps.map { $0.workoutSet }
            .filter { $0.isCompleted }
            .reduce(0) { $0 + ($1.weight * Double($1.completedReps)) }
    }

    private func setupWorkout() {
        let sets = WorkoutCalculator.generateWorkout(for: lift, profile: profile, accessories: accessories)
        var newSteps: [WorkoutStep] = []

        newSteps.append(contentsOf: createWarmupSteps(from: sets.warmup))
        newSteps.append(contentsOf: createMainSteps(from: sets.main))
        newSteps.append(contentsOf: createSupplementalSteps(from: sets.supplemental))
        newSteps.append(contentsOf: createAccessorySteps(from: sets.accessorySets))

        self.steps = newSteps
    }

    private func createWarmupSteps(from sets: [WorkoutSet]) -> [WorkoutStep] {
        let warmupPercentages = [40, 50, 60]
        return sets.enumerated().map { index, set in
            WorkoutStep(title: "Warmup", liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: sets.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: index < warmupPercentages.count ? warmupPercentages[index] : nil)
        }
    }

    private func createMainSteps(from sets: [WorkoutSet]) -> [WorkoutStep] {
        let week = profile.currentWeek
        var mainPercentages: [Int] = []
        switch week {
        case 1: mainPercentages = [65, 75, 85]
        case 2: mainPercentages = [70, 80, 90]
        case 3: mainPercentages = [75, 85, 95]
        default: mainPercentages = [40, 50, 60]
        }

        return sets.enumerated().map { index, set in
            let isAmrap = set.reps.contains("+")
            return WorkoutStep(title: "Main", liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: sets.count, setNumberInPhase: index + 1, isAMRAP: isAmrap, percentage: index < mainPercentages.count ? mainPercentages[index] : nil)
        }
    }

    private func createSupplementalSteps(from sets: [WorkoutSet]) -> [WorkoutStep] {
        let week = profile.currentWeek
        var supplementalPercentage: Int = 0
        switch profile.selectedTemplate {
        case .bbb: supplementalPercentage = 50
        case .ssl:
            switch week {
            case 1: supplementalPercentage = 75
            case 2: supplementalPercentage = 80
            case 3: supplementalPercentage = 85
            default: supplementalPercentage = 0
            }
        default:
            switch week {
            case 1: supplementalPercentage = 65
            case 2: supplementalPercentage = 70
            case 3: supplementalPercentage = 75
            default: supplementalPercentage = 0
            }
        }

        return sets.enumerated().map { index, set in
            WorkoutStep(title: profile.selectedTemplate.shortName, liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: sets.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: supplementalPercentage > 0 ? supplementalPercentage : nil)
        }
    }

    private func createAccessorySteps(from sets: [WorkoutSet]) -> [WorkoutStep] {
        var steps: [WorkoutStep] = []
        let groupedAccessories = Dictionary(grouping: sets, by: { $0.exerciseName })
        for accessory in accessories where accessory.relatedLift == lift {
            if let accSets = groupedAccessories[accessory.name] {
                for (index, set) in accSets.enumerated() {
                    steps.append(WorkoutStep(title: accessory.name, liftIcon: nil, workoutSet: set, totalSetsInPhase: accSets.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: nil))
                }
            }
        }
        return steps
    }
    
    private func weekName(for week: Int) -> String {
        switch week {
        case 1: return "5's Week"
        case 2: return "3's Week"
        case 3: return "5/3/1 Week"
        case 4: return "Deload"
        default: return "Training"
        }
    }

    private func weekAbbreviation(for week: Int) -> String {
        switch week {
        case 1: return "5's"
        case 2: return "3's"
        case 3: return "5/3/1"
        case 4: return "Deload"
        default: return ""
        }
    }

    private func startRestTimer() {
        showRestTimer = true
        restTimeRemaining = 90
        WKInterfaceDevice.current().play(.start)

        let content = UNMutableNotificationContent()
        content.title = "Rest Over"
        content.body = "Back to the bar!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 90, repeats: false)
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
                if restTimeRemaining <= 3 {
                    WKInterfaceDevice.current().play(.directionUp)
                }
            } else {
                showRestTimer = false
                timer?.invalidate()
                WKInterfaceDevice.current().play(.success)
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
                advanceTab()
            }
        }
    }
    
    private func advanceTab() {
        if selectedTab < steps.count {
            WKInterfaceDevice.current().play(.directionUp)
            withAnimation(.spring()) {
                selectedTab += 1
            }
        }
    }

    private func triggerCelebration() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCelebration = true
        }
        WKInterfaceDevice.current().play(.notification)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            finishWorkout()
        }
    }

    private func finishWorkout() {
        workoutManager.endWorkout()

        let amrapStep = steps.last { $0.title == "Main" && $0.workoutSet.reps.contains("+") && $0.workoutSet.isCompleted }
        let actualReps = amrapStep?.workoutSet.actualReps ?? 0
        let weight = amrapStep?.workoutSet.weight ?? 0

        let session = WorkoutSession(
            mainLift: lift,
            week: profile.currentWeek,
            cycle: profile.currentCycle,
            isCompleted: true,
            amrapReps: actualReps,
            amrapWeight: weight
        )
        modelContext.insert(session)

        let maxWeek = profile.usesFourWeekCycle ? 4 : 3
        if lift == .ohp && profile.currentWeek == maxWeek {
            finalAmrapReps = actualReps
            finalAmrapWeight = weight
            showCycleSummary = true
            try? modelContext.save()
            return
        }
        
        if lift == .ohp {
            if profile.currentWeek < maxWeek {
                profile.currentWeek += 1
            } else {
                profile.currentWeek = 1
                profile.currentCycle += 1
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Subviews & Helpers

struct WeightIdentifiable: Identifiable {
    let id = UUID()
    let weight: Double
}

extension WorkoutActiveView {
    private func calculateRepsToBeatPR(for step: WorkoutStep) -> Int? {
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

private extension Binding where Value == Int {
    func toDouble() -> Binding<Double> {
        return Binding<Double>(
            get: { Double(self.wrappedValue) },
            set: { self.wrappedValue = Int($0) }
        )
    }
}

extension WorkoutSet {
    var completedReps: Int {
        if actualReps > 0 { return actualReps }
        return Int(reps.replacingOccurrences(of: "+", with: "")) ?? 0
    }
}

#Preview {
    WorkoutActiveView(lift: .squat, profile: UserProfile(), accessories: [])
        .environmentObject(WorkoutManager())
}

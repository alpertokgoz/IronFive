import SwiftUI
import SwiftData
import UserNotifications
import WatchKit

extension WorkoutActiveView {
    func completedStepsCount() -> Int {
        steps.filter { $0.workoutSet.isCompleted }.count
    }

    var totalWeightLifted: Double {
        steps.map { $0.workoutSet }
            .filter { $0.isCompleted }
            .reduce(0) { $0 + ($1.weight * Double($1.completedReps)) }
    }

    func setupWorkout() {
        if let session = fetchActiveSession(),
           let progress = try? WorkoutProgress.decode(session.stepsData) {
            self.steps = progress.steps
            self.selectedTab = progress.restoredIndex(session.currentStepIndex)
            self.restCountdown = progress.restCountdown
            return
        }

        if fetchActiveSession() != nil {
            workoutError = "Your saved workout could not be read. Its data has been preserved."
            return
        }

        let sets = WorkoutCalculator.generateWorkout(for: lift, profile: profile, accessories: accessories)
        let week = profile.currentWeek

        var newSteps: [WorkoutStep] = []
        addWarmupSteps(to: &newSteps, from: sets.warmup)
        addMainSteps(to: &newSteps, from: sets.main, week: week)
        addSupplementalSteps(to: &newSteps, from: sets.supplemental, week: week)
        addAccessorySteps(to: &newSteps, from: sets.accessorySets)

        self.steps = newSteps
        saveActiveSession()
    }

    func saveActiveSession() {
        guard !steps.isEmpty, !didFinishWorkout else { return }
        if let data = try? JSONEncoder().encode(WorkoutProgress(steps: steps, restCountdown: restCountdown)) {
            if let existing = fetchActiveSession() {
                existing.stepsData = data
                existing.currentStepIndex = selectedTab
            } else {
                let newSession = ActiveWorkoutSession(mainLift: lift, steps: steps, currentStepIndex: selectedTab)
                modelContext.insert(newSession)
            }
            do {
                try modelContext.save()
            } catch {
                workoutError = "Could not save your workout progress. Please try again."
            }
        }
    }

    func fetchActiveSession() -> ActiveWorkoutSession? {
        let liftVal = lift.rawValue
        let descriptor = FetchDescriptor<ActiveWorkoutSession>(predicate: #Predicate { $0.mainLiftValue == liftVal })
        return try? modelContext.fetch(descriptor).first
    }

    private func addWarmupSteps(to steps: inout [WorkoutStep], from workoutSets: [WorkoutSet]) {
        let percentages = [40, 50, 60]
        for (index, set) in workoutSets.enumerated() {
            steps.append(WorkoutStep(title: "Warmup", liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: workoutSets.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: index < percentages.count ? percentages[index] : nil))
        }
    }

    private func addMainSteps(to steps: inout [WorkoutStep], from workoutSets: [WorkoutSet], week: Int) {
        let percentages: [Int]
        switch week {
        case 1: percentages = [65, 75, 85]
        case 2: percentages = [70, 80, 90]
        case 3: percentages = [75, 85, 95]
        default: percentages = [40, 50, 60]
        }

        for (index, set) in workoutSets.enumerated() {
            let isAmrap = set.reps.contains("+")
            steps.append(WorkoutStep(title: "Main", liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: workoutSets.count, setNumberInPhase: index + 1, isAMRAP: isAmrap, percentage: index < percentages.count ? percentages[index] : nil))
        }
    }

    private func addSupplementalSteps(to steps: inout [WorkoutStep], from workoutSets: [WorkoutSet], week: Int) {
        var percentage: Int = 0
        switch profile.selectedTemplate {
        case .bbb: percentage = 50
        case .ssl:
            let levels = [1: 75, 2: 80, 3: 85]
            percentage = levels[week] ?? 0
        default:
            let levels = [1: 65, 2: 70, 3: 75]
            percentage = levels[week] ?? 0
        }

        for (index, set) in workoutSets.enumerated() {
            steps.append(WorkoutStep(title: profile.selectedTemplate.shortName, liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: workoutSets.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: percentage > 0 ? percentage : nil))
        }
    }

    private func addAccessorySteps(to steps: inout [WorkoutStep], from workoutSets: [WorkoutSet]) {
        let grouped = Dictionary(grouping: workoutSets, by: { $0.exerciseName })
        for accessory in accessories where accessory.relatedLift == lift {
            if let accSets = grouped[accessory.name] {
                for (index, set) in accSets.enumerated() {
                    steps.append(WorkoutStep(title: accessory.name, liftIcon: nil, workoutSet: set, totalSetsInPhase: accSets.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: nil))
                }
            }
        }
    }

    func weekName(for week: Int) -> String {
        switch week {
        case 1: return "5's Week"
        case 2: return "3's Week"
        case 3: return "5/3/1 Week"
        case 4: return "Deload"
        default: return "Training"
        }
    }

    func weekAbbreviation(for week: Int) -> String {
        switch week {
        case 1: return "5's"
        case 2: return "3's"
        case 3: return "5/3/1"
        case 4: return "Deload"
        default: return ""
        }
    }

    func advanceTab() {
        if selectedTab < steps.count {
            let currentStep = steps[selectedTab]
            let nextIndex = selectedTab + 1

            if nextIndex < steps.count {
                let nextStep = steps[nextIndex]
                if nextStep.title != currentStep.title {
                    WKInterfaceDevice.current().play(.success)
                    currentPhaseTitle = nextStep.title
                    withAnimation { showPhaseTransition = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        withAnimation { showPhaseTransition = false }
                    }
                } else {
                    WKInterfaceDevice.current().play(.directionUp)
                }
            } else {
                WKInterfaceDevice.current().play(.notification)
            }

            withAnimation(.spring()) {
                selectedTab += 1
                saveActiveSession()
            }
        }
    }

    func triggerCelebration() {
        guard !didFinishWorkout else { return }
        guard !workoutManager.isPreparing else {
            workoutError = "Apple Health is still preparing your workout. Please try again in a moment."
            return
        }
        let amrapStep = steps.last { $0.title == "Main" && $0.workoutSet.reps.contains("+") && $0.workoutSet.isCompleted }
        let actualReps = amrapStep?.workoutSet.actualReps ?? 0
        let weight = amrapStep?.workoutSet.weight ?? 0

        let newE1RM = weight * (1 + 0.0333 * Double(actualReps))
        let liftSessions = workoutSessions.filter { $0.mainLift == lift && $0.isCompleted }
        let allTimeBest = liftSessions.map { $0.estimated1RM }.max() ?? 0

        let isPR = newE1RM > allTimeBest && actualReps > 0

        if isPR {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showCelebration = true
            }
            WKInterfaceDevice.current().play(.notification)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                finishWorkout()
            }
        } else {
            finishWorkout()
        }
    }

    func finishWorkout() {
        guard !didFinishWorkout else { return }
        stopRestTimer()
        if let activeSession = fetchActiveSession() {
            modelContext.delete(activeSession)
        }
        let maxWeek = profile.usesFourWeekCycle ? 4 : 3

        let amrapStep = steps.last { $0.title == "Main" && $0.workoutSet.reps.contains("+") && $0.workoutSet.isCompleted }
        let actualReps = amrapStep?.workoutSet.actualReps ?? 0
        let weight = amrapStep?.workoutSet.weight ?? 0

        let session = WorkoutSession(
            mainLift: lift,
            week: profile.currentWeek,
            cycle: profile.currentCycle,
            isCompleted: WorkoutProgress(steps: steps).isComplete,
            amrapReps: actualReps,
            amrapWeight: weight
        )
        modelContext.insert(session)

        if session.isCompleted && areAllLiftsCompletedThisWeek() {
            if profile.currentWeek == maxWeek {
                finalAmrapReps = actualReps
                finalAmrapWeight = weight
                showCycleSummary = true
            } else {
                profile.currentWeek += 1
            }
        }

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            showCycleSummary = false
            workoutError = "Could not save your workout. Your active session is still available. Please try again."
            return
        }
        didFinishWorkout = true
        workoutManager.endWorkout()

        if !showCycleSummary {
            dismiss()
        }
    }

    func areAllLiftsCompletedThisWeek() -> Bool {
        let currentLifts = Set(workoutSessions.filter {
            $0.week == profile.currentWeek &&
            $0.cycle == profile.currentCycle &&
            $0.isCompleted
        }.map { $0.mainLift })

        // Include the current lift since it's about to be saved
        var allLifts = currentLifts
        allLifts.insert(lift)

        return allLifts.count >= 4
    }

    func contentView() -> some View {
        GeometryReader { pageGeometry in
            TabView(selection: $selectedTab) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    VStack(spacing: 0) {
                        headerView(for: step)
                        WorkoutStepView(
                            lift: lift,
                            step: $steps[index],
                            allSteps: steps,
                            selectedTab: $selectedTab,
                            nextTab: index + 1,
                            workoutSessions: workoutSessions,
                            weightUnit: profile.weightUnit,
                            isAutopilotEnabled: profile.isAutopilotEnabled,
                            onRestStart: startRestTimer,
                            onPlateCalc: { weight in selectedWeightForCalc = weight },
                            onSave: { saveActiveSession() }
                        )
                        if !isLuminanceReduced { metricsFooter() }
                    }
                    .frame(width: pageGeometry.size.width, height: pageGeometry.size.height)
                    .tag(index)
                }

                WorkoutSummaryView(
                    workoutManager: workoutManager,
                    profile: profile,
                    totalWeight: totalWeightLifted,
                    showCelebration: showCelebration,
                    completedSets: completedStepsCount(),
                    totalSets: steps.count,
                    personalBestReps: steps.last { $0.isAMRAP && $0.workoutSet.isCompleted }?.workoutSet.actualReps ?? 0,
                    personalBestWeight: steps.last { $0.isAMRAP && $0.workoutSet.isCompleted }?.workoutSet.weight ?? 0,
                    onFinish: { showFinishConfirmation = true }
                )

                .frame(width: pageGeometry.size.width, height: pageGeometry.size.height)
                .tag(steps.count)
            }
            .frame(width: pageGeometry.size.width, height: pageGeometry.size.height)
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    func headerView(for step: WorkoutStep) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(step.title == "Warmup" ? "Warm-up" : step.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(lift.color)
                    .lineLimit(1)
                Spacer(minLength: 3)
                Text("Set \(step.setNumberInPhase) of \(step.totalSetsInPhase)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geometry in
                Capsule().fill(lift.color.opacity(0.25))
                    .overlay(alignment: .leading) {
                        Capsule().fill(lift.color)
                            .frame(width: geometry.size.width * Double(completedStepsCount()) / Double(max(1, steps.count)))
                    }
            }
                .frame(height: 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Workout progress")
                .accessibilityValue("\(completedStepsCount()) of \(steps.count) sets complete")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
    }

    private func isStandardPhase(_ title: String) -> Bool {
        let standard = ["Warmup", "Main", profile.selectedTemplate.shortName]
        return standard.contains(title)
    }
}

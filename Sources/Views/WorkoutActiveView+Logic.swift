import SwiftUI
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
        let sets = WorkoutCalculator.generateWorkout(for: lift, profile: profile, accessories: accessories)
        let week = profile.currentWeek

        var newSteps: [WorkoutStep] = []
        addWarmupSteps(to: &newSteps, from: sets.warmup)
        addMainSteps(to: &newSteps, from: sets.main, week: week)
        addSupplementalSteps(to: &newSteps, from: sets.supplemental, week: week)
        addAccessorySteps(to: &newSteps, from: sets.accessorySets)

        self.steps = newSteps
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

    func startRestTimer() {
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

    func advanceTab() {
        if selectedTab < steps.count {
            WKInterfaceDevice.current().play(.directionUp)
            withAnimation(.spring()) {
                selectedTab += 1
            }
        }
    }

    func triggerCelebration() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCelebration = true
        }
        WKInterfaceDevice.current().play(.notification)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            finishWorkout()
        }
    }

    func finishWorkout() {
        workoutManager.endWorkout()
        let maxWeek = profile.usesFourWeekCycle ? 4 : 3

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

        if areAllLiftsCompletedThisWeek() {
            if profile.currentWeek == maxWeek {
                finalAmrapReps = actualReps
                finalAmrapWeight = weight
                showCycleSummary = true
            } else {
                profile.currentWeek += 1
            }
        }

        try? modelContext.save()

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
        TabView(selection: $selectedTab) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                WorkoutStepView(
                    lift: lift,
                    step: $steps[index],
                    allSteps: steps,
                    selectedTab: $selectedTab,
                    nextTab: index + 1,
                    workoutSessions: workoutSessions,
                    weightUnit: profile.weightUnit,
                    onRestStart: startRestTimer,
                    onPlateCalc: { weight in selectedWeightForCalc = weight }
                )
                .tag(index)
            }

            // Finish Tab
            let currentAmrapStep = steps.last { $0.isAMRAP && $0.workoutSet.isCompleted }
            let previousSessions = workoutSessions.filter { $0.mainLift == lift && $0.isCompleted }
            let personalBestE1RM = previousSessions.map { $0.estimated1RM }.max() ?? 0

            WorkoutSummaryView(
                workoutManager: workoutManager,
                profile: profile,
                totalWeight: totalWeightLifted,
                showCelebration: showCelebration,
                amrapStep: currentAmrapStep,
                bestE1RM: personalBestE1RM,
                onFinish: { showFinishConfirmation = true }
            )
            .tag(steps.count)
        }
    }

    func headerView() -> some View {
        VStack(spacing: 0) {
            // Primary Title Row: Lift Icon + Name
            HStack(alignment: .center, spacing: 4) {
                if steps.indices.contains(selectedTab) {
                    let step = steps[selectedTab]
                    let isAccessory = !isStandardPhase(step.title)

                    if let icon = step.liftIcon {
                        Image(systemName: icon)
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(lift.color.gradient)
                    }

                    Text(isAccessory ? step.title.uppercased() : lift.name.uppercased())
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else {
                    Text(lift.name.uppercased())
                        .font(.system(size: 12, weight: .black, design: .rounded))
                }
            }
            .padding(.top, 2)

            // Secondary Stat Row: Cycle + Phase/Day + Progress Bar
            HStack(alignment: .center, spacing: 6) {
                let isAcc = steps.indices.contains(selectedTab) && !isStandardPhase(steps[selectedTab].title)
                let stepTitle = steps.indices.contains(selectedTab) ? steps[selectedTab].title.uppercased() : ""
                let subtitle = isAcc ? "C\(profile.currentCycle): \(weekAbbreviation(for: profile.currentWeek).uppercased()) - \(lift.name.uppercased()) DAY" : "C\(profile.currentCycle): \(weekAbbreviation(for: profile.currentWeek).uppercased()) - \(stepTitle)"

                Text(subtitle)
                    .font(.system(size: 7, weight: .black, design: .rounded))
                    .foregroundColor(.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 3)

                    let progress = !steps.isEmpty ? Double(completedStepsCount()) / Double(steps.count) : 0
                    Capsule()
                        .fill(Color.green.gradient)
                        .frame(width: max(0, 70 * progress), height: 3)
                }
                .frame(width: 70)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 2)
            .background(Color.black.opacity(0.6))
        }
    }

    private func isStandardPhase(_ title: String) -> Bool {
        let standard = ["Warmup", "Main", profile.selectedTemplate.shortName]
        return standard.contains(title)
    }
}

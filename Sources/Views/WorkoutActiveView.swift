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

    struct WorkoutStep: Identifiable {
        let id = UUID()
        let title: String
        let liftIcon: String?
        var workoutSet: WorkoutSet
        let totalSetsInPhase: Int
        let setNumberInPhase: Int
        let isAMRAP: Bool
        let percentage: Int?
    }

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
                            Text("\(lift.shortName) · \(step.title.uppercased())")
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
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)
                    
                    let progress = steps.count > 0 ? Double(completedStepsCount) / Double(steps.count) : 0
                    Capsule()
                        .fill(Color.green.gradient)
                        .frame(width: max(0, (WKInterfaceDevice.current().screenBounds.width - 8) * progress), height: 6)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 6, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
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
                        workoutSessions: workoutSessions,
                        onRestStart: startRestTimer,
                        onPlateCalc: { weight in selectedWeightForCalc = weight }
                    )
                    .tag(index)
                }

                // Finish Tab
                let currentAmrapStep = steps.last { $0.isAMRAP && $0.workoutSet.isCompleted }
                let previousSessions = workoutSessions.filter { $0.mainLift == lift && $0.isCompleted }
                let personalBestE1RM = previousSessions.map { $0.estimated1RM }.max() ?? 0
                
                SummaryTab(
                    workoutManager: workoutManager,
                    profile: profile,
                    totalWeight: totalWeightLifted,
                    showCelebration: showCelebration,
                    amrapStep: currentAmrapStep,
                    bestE1RM: personalBestE1RM,
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
        let week = profile.currentWeek
        
        var newSteps: [WorkoutStep] = []
        
        // 1. Warmup
        let warmupPercentages = [40, 50, 60]
        for (index, set) in sets.warmup.enumerated() {
            newSteps.append(WorkoutStep(title: "Warmup", liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: sets.warmup.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: index < warmupPercentages.count ? warmupPercentages[index] : nil))
        }
        
        // 2. Main
        var mainPercentages: [Int] = []
        switch week {
        case 1: mainPercentages = [65, 75, 85]
        case 2: mainPercentages = [70, 80, 90]
        case 3: mainPercentages = [75, 85, 95]
        default: mainPercentages = [40, 50, 60]
        }
        
        for (index, set) in sets.main.enumerated() {
            let isAmrap = set.reps.contains("+")
            newSteps.append(WorkoutStep(title: "Main", liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: sets.main.count, setNumberInPhase: index + 1, isAMRAP: isAmrap, percentage: index < mainPercentages.count ? mainPercentages[index] : nil))
        }
        
        // 3. Supplemental
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
        default: // FSL, BBS, Widow
            switch week {
            case 1: supplementalPercentage = 65
            case 2: supplementalPercentage = 70
            case 3: supplementalPercentage = 75
            default: supplementalPercentage = 0
            }
        }
        
        for (index, set) in sets.supplemental.enumerated() {
            newSteps.append(WorkoutStep(title: profile.selectedTemplate.shortName, liftIcon: lift.symbolName, workoutSet: set, totalSetsInPhase: sets.supplemental.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: supplementalPercentage > 0 ? supplementalPercentage : nil))
        }
        
        // 4. Accessories
        let groupedAccessories = Dictionary(grouping: sets.accessorySets, by: { $0.exerciseName })
        for accessory in accessories where accessory.relatedLift == lift {
            if let accSets = groupedAccessories[accessory.name] {
                for (index, set) in accSets.enumerated() {
                    newSteps.append(WorkoutStep(title: accessory.name, liftIcon: nil, workoutSet: set, totalSetsInPhase: accSets.count, setNumberInPhase: index + 1, isAMRAP: false, percentage: nil))
                }
            }
        }
        
        self.steps = newSteps
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

struct SummaryTab: View {
    @ObservedObject var workoutManager: WorkoutManager
    let profile: UserProfile
    let totalWeight: Double
    let showCelebration: Bool
    let amrapStep: WorkoutActiveView.WorkoutStep?
    let bestE1RM: Double
    let onFinish: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if showCelebration {
                    CelebrationView()
                        .frame(height: 160)
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.yellow.gradient)
                        
                        Text("GREAT JOB!")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        
                        Text("Cycle \(profile.currentCycle), Week \(profile.currentWeek)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                    
                    VStack(spacing: 6) {
                        if let amrap = amrapStep {
                            VStack(spacing: 2) {
                                Text("AMRAP RESULT")
                                    .font(.system(size: 8, weight: .black, design: .rounded))
                                    .foregroundColor(.orange)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(amrap.workoutSet.actualReps)")
                                        .font(.system(size: 28, weight: .black, design: .rounded))
                                        .foregroundColor(.orange)
                                    Text("REPS @ \(String(format: "%.1f", amrap.workoutSet.weight))\(profile.weightUnit.label)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                
                                let currentE1RM = amrap.workoutSet.estimated1RM
                                if currentE1RM > 0 {
                                    HStack(spacing: 4) {
                                        Text("E1RM: \(String(format: "%.1f", currentE1RM))")
                                            .font(.system(size: 10, weight: .black))
                                            .foregroundColor(.yellow)
                                        
                                        if currentE1RM > bestE1RM && bestE1RM > 0 {
                                            Text("PR! +\(String(format: "%.1f", currentE1RM - bestE1RM))")
                                                .font(.system(size: 8, weight: .black))
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.green)
                                                .cornerRadius(2)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.1)))
                            .padding(.bottom, 4)
                        }

                        SummaryStatRow(label: "ENERGY", value: "\(Int(workoutManager.activeEnergy))", unit: "kcal", icon: "flame.fill", color: .orange)
                        SummaryStatRow(label: "HEART RATE", value: "\(Int(workoutManager.heartRate))", unit: "bpm", icon: "heart.fill", color: .red)
                        SummaryStatRow(label: "TOTAL LIFTED", value: "\(Int(totalWeight))", unit: profile.weightUnit.label, icon: "dumbbell.fill", color: .blue)
                        SummaryStatRow(label: "TIME", value: workoutManager.elapsedTimeString, unit: "", icon: "timer", color: .purple)
                    }
                    .padding(.horizontal, 4)

                    Button(action: onFinish) {
                        Text("FINISH")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SummaryStatRow: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 12))
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                Text(unit)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CelebrationView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var showText = false

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let symbol: String
        let size: CGFloat
        var opacity: Double = 1.0
    }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Text(p.symbol)
                    .font(.system(size: p.size))
                    .foregroundColor(p.color)
                    .position(x: p.x, y: p.y)
                    .opacity(p.opacity)
            }
            VStack(spacing: 4) {
                Text("🏋️").font(.system(size: 30))
                Text("SAVED").font(.system(size: 14, weight: .black, design: .rounded))
            }
        }
        .onAppear {
            spawnConfetti()
            showText = true
        }
    }

    private func spawnConfetti() {
        let symbols = ["💪", "🔥", "✨", "🎉"]
        let colors: [Color] = [.orange, .blue, .green, .purple]
        for i in 0..<12 {
            particles.append(ConfettiParticle(
                x: CGFloat.random(in: 20...160),
                y: -10,
                color: colors.randomElement()!,
                symbol: symbols.randomElement()!,
                size: 12
            ))
            let index = particles.count - 1
            withAnimation(.interpolatingSpring(stiffness: 30, damping: 6).delay(Double(i)*0.1)) {
                particles[index].y = CGFloat.random(in: 40...140)
            }
        }
    }
}

struct WorkoutStepView: View {
    let lift: MainLift
    @Binding var step: WorkoutActiveView.WorkoutStep
    let allSteps: [WorkoutActiveView.WorkoutStep]
    @Binding var selectedTab: Int
    let nextTab: Int
    let workoutSessions: [WorkoutSession]
    var onRestStart: () -> Void
    var onPlateCalc: (Double) -> Void

    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack(spacing: 2) {
            // Moved progress and skip above the main card to prevent clipping
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
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Spacer(minLength: 0)
            
            // PR Goal Badge
            if step.isAMRAP {
                if let prReps = calculateRepsToBeatPR() {
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
                    .foregroundColor(lift.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(lift.color.opacity(0.15))
                    .cornerRadius(4)
                    .padding(.bottom, 2)
            }

            SetRowView(
                workoutSet: $step.workoutSet,
                isAMRAP: step.isAMRAP,
                lift: lift,
                prGoal: step.isAMRAP ? calculateRepsToBeatPR() : nil,
                onComplete: onRestStart,
                onPlateCalc: { onPlateCalc(step.workoutSet.weight) }
            )
                .padding(.horizontal, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(step.isAMRAP ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
                        .padding(.horizontal, 4)
                )
        }
        .padding(.bottom, 2)
    }

    private func calculateRepsToBeatPR() -> Int? {
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

struct ParticleBurstView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var speedX: CGFloat
        var speedY: CGFloat
        let color: Color
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    Circle()
                        .fill(p.color)
                        .frame(width: 4, height: 4)
                        .scaleEffect(p.scale)
                        .opacity(p.opacity)
                        .position(x: p.x, y: p.y)
                }
            }
            .onAppear {
                let center = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                for _ in 0..<12 {
                    let angle = Double.random(in: 0..<2 * .pi)
                    let speed = CGFloat.random(in: 10...30)
                    particles.append(Particle(
                        x: center.x,
                        y: center.y,
                        scale: CGFloat.random(in: 0.5...1.0),
                        opacity: 1,
                        speedX: cos(angle) * speed,
                        speedY: sin(angle) * speed,
                        color: [.green, .mint, .white].randomElement()!
                    ))
                }
                
                withAnimation(.easeOut(duration: 0.6)) {
                    for i in particles.indices {
                        particles[i].x += particles[i].speedX
                        particles[i].y += particles[i].speedY
                        particles[i].scale = 0
                        particles[i].opacity = 0
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SetRowView: View {
    @Binding var workoutSet: WorkoutSet
    let isAMRAP: Bool
    let lift: MainLift
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
                        Text("\(String(format: "%.1f", workoutSet.weight))")
                            .font(.system(size: 26, weight: .black, design: .rounded))
                        Text("kg")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundStyle(workoutSet.isCompleted ? .secondary : .primary)
                }
                .buttonStyle(.plain)
                
                if isAMRAP {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("AMRAP")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                        
                        if workoutSet.isCompleted {
                            Text("\(workoutSet.actualReps) REPS")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("\(workoutSet.reps) REPS")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()

            Button(action: {
                handleCompletion()
            }) {
                ZStack {
                    // 1. Background Track
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 4)
                        .background(Circle().fill(Color.white.opacity(0.05)))
                    
                    // 2. Filling Animation
                    Circle()
                        .fill(isAMRAP ? Color.orange : Color.green)
                        .scaleEffect(workoutSet.isCompleted ? 1.0 : 0.001)
                        .opacity(workoutSet.isCompleted ? 1.0 : 0.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: workoutSet.isCompleted)
                    
                    // 3. Checkmark
                    if workoutSet.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.black)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // 4. Particles
                    if showParticles {
                        ParticleBurstView()
                    }
                }
                .frame(width: 44, height: 44)
                .scaleEffect(scale)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(lift.color.opacity(0.1))
                
                if isAMRAP && !workoutSet.isCompleted {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 2)
                }
            }
        )
        .overlay(alignment: .trailing) {
            if !workoutSet.isCompleted {
                Text("TAP")
                    .font(.system(size: 6, weight: .black))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.trailing, 22)
            }
        }
        .sheet(isPresented: $showAmrapSheet) {
            AmrapInputView(reps: $workoutSet.actualReps) {
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

struct AmrapInputView: View {
    @Binding var reps: Int
    var onDone: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text("How many reps?")
                .font(.system(size: 14, weight: .black, design: .rounded))
            
            HStack(spacing: 4) {
                Text("\(reps)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(isFocused ? .black : .accentColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isFocused ? Color.accentColor : Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .focusable()
                    .focused($isFocused)
                    .digitalCrownRotation($reps.toDouble(), from: 0, through: 50, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                
                Text("REPS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            Button("Done") {
                onDone()
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .onAppear {
            isFocused = true
        }
    }
}

struct RestTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var isPresented: Bool
    var onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack(spacing: 12) {
                Text("REST")
                    .font(.system(.footnote, design: .rounded, weight: .black))
                    .foregroundColor(.accentColor)
                    .kerning(2.0)
                
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: Double(timeRemaining) / 90.0)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)
                    
                    VStack(spacing: -4) {
                        Text("\(timeRemaining)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                        Text("SEC")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                Button(action: {
                    withAnimation {
                        isPresented = false
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
                        onDismiss()
                    }
                }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("SKIP")
                    }
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .frame(width: 90, height: 36)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
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

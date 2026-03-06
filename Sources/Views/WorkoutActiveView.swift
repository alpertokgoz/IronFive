import SwiftUI
import SwiftData

struct WorkoutActiveView: View {
    let lift: MainLift
    let profile: UserProfile
    let accessories: [AccessoryExercise]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab = 0
    @State private var warmupSets: [WorkoutSet] = []
    @State private var mainSets: [WorkoutSet] = []
    @State private var fslSets: [WorkoutSet] = []
    @State private var accessorySets: [WorkoutSet] = []

    // Rest Timer State
    @State private var showRestTimer = false
    @State private var restTimeRemaining = 90
    @State private var timer: Timer?
    
    // Plate Calculator State
    @State private var selectedWeightForCalc: Double?
    
    // Finish State
    @State private var showFinishConfirmation = false
    @State private var showCelebration = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Warmup
            WorkoutPhaseView(title: "Warmup", sets: $warmupSets, selectedTab: $selectedTab, currentTab: 0, nextTab: 1, onRestStart: startRestTimer, onPlateCalc: { weight in selectedWeightForCalc = weight })
                .tabItem { Text("Warmup") }
                .tag(0)

            // 5/3/1 Main Work
            WorkoutPhaseView(title: "Main Lift", sets: $mainSets, selectedTab: $selectedTab, currentTab: 1, nextTab: 2, onRestStart: startRestTimer, onPlateCalc: { weight in selectedWeightForCalc = weight })
                .tabItem { Text("Main") }
                .tag(1)

            // Supplemental
            WorkoutPhaseView(title: profile.selectedTemplate.shortName, sets: $fslSets, selectedTab: $selectedTab, currentTab: 2, nextTab: 3, onRestStart: startRestTimer, onPlateCalc: { weight in selectedWeightForCalc = weight })
                .tabItem { Text(profile.selectedTemplate.shortName) }
                .tag(2)

            // Accessories
            WorkoutPhaseView(title: "Accessories", sets: $accessorySets, selectedTab: $selectedTab, currentTab: 3, nextTab: 4, onRestStart: startRestTimer, onPlateCalc: { _ in })
                .tabItem { Text("Accessories") }
                .tag(3)

            // Finish
            VStack(spacing: 12) {
                if showCelebration {
                    CelebrationView()
                } else {
                    Spacer()
                    
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.yellow.gradient)
                    
                    Text("Great Job!")
                        .font(.system(.title2, design: .rounded, weight: .black))
                    
                    if workoutManager.running {
                        Text(workoutManager.elapsedTimeString)
                            .font(.system(.caption, design: .rounded, weight: .bold))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Finish Workout") {
                        showFinishConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .accessibilityLabel("Finish and save this workout")
                }
            }
            .padding()
            .tabItem { Text("Finish") }
            .tag(4)
            .alert("Finish Workout?", isPresented: $showFinishConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Finish", role: .destructive) {
                    triggerCelebration()
                }
            } message: {
                Text("This will save your session and advance your program.")
            }
        }
        .tabViewStyle(.page)
        .navigationTitle(lift.name)
        .navigationBarTitleDisplayMode(.inline)
        .containerBackground(lift.color.gradient, for: .navigation)
        .onAppear {
            let sets = WorkoutCalculator.generateWorkout(for: lift, profile: profile, accessories: accessories)
            warmupSets = sets.warmup
            mainSets = sets.main
            fslSets = sets.fsl
            accessorySets = sets.accessorySets
            workoutManager.startWorkout()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .overlay {
            if showRestTimer {
                RestTimerView(timeRemaining: $restTimeRemaining, isPresented: $showRestTimer)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .sheet(item: Binding(
            get: { selectedWeightForCalc.map { WeightIdentifiable(weight: $0) } },
            set: { selectedWeightForCalc = $0?.weight }
        )) { item in
            PlateCalculatorView(targetWeight: item.weight, unit: profile.weightUnit)
        }
        .animation(.spring(), value: showRestTimer)
    }
    
    struct WeightIdentifiable: Identifiable {
        let id = UUID()
        let weight: Double
    }

    private func startRestTimer() {
        showRestTimer = true
        restTimeRemaining = 90
        WKInterfaceDevice.current().play(.start)

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
                if restTimeRemaining == 3 || restTimeRemaining == 2 || restTimeRemaining == 1 {
                    WKInterfaceDevice.current().play(.directionUp)
                }
            } else {
                showRestTimer = false
                timer?.invalidate()
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    private func triggerCelebration() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCelebration = true
        }
        WKInterfaceDevice.current().play(.notification)
        
        // Auto-save and dismiss after celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            finishWorkout()
        }
    }

    private func finishWorkout() {
        workoutManager.endWorkout()

        let amrapSet = mainSets.last { $0.reps.contains("+") && $0.isCompleted }
        let actualReps = amrapSet?.actualReps ?? 0
        let weight = amrapSet?.weight ?? 0

        let session = WorkoutSession(
            mainLift: lift,
            week: profile.currentWeek,
            cycle: profile.currentCycle,
            isCompleted: true,
            amrapReps: actualReps,
            amrapWeight: weight
        )
        modelContext.insert(session)

        let isFourWeek = profile.usesFourWeekCycle
        let maxWeek = isFourWeek ? 4 : 3

        if lift == .ohp {
            if profile.currentWeek < maxWeek {
                profile.currentWeek += 1
            } else {
                profile.currentWeek = 1
                profile.currentCycle += 1
                profile.squatTM += profile.weightUnit.lowerIncrement
                profile.deadliftTM += profile.weightUnit.lowerIncrement
                profile.benchTM += profile.weightUnit.upperIncrement
                profile.ohpTM += profile.weightUnit.upperIncrement
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save workout: \(error.localizedDescription)")
        }
        dismiss()
    }
}

// MARK: - Celebration View
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

            VStack(spacing: 8) {
                Text("🏋️")
                    .font(.system(size: 44))
                    .scaleEffect(showText ? 1.0 : 0.3)

                Text("CRUSHED IT!")
                    .font(.system(.title3, design: .rounded, weight: .black))
                    .foregroundColor(.white)
                    .scaleEffect(showText ? 1.0 : 0.5)
                    .opacity(showText ? 1.0 : 0.0)

                Text("Saving workout...")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .foregroundColor(.secondary)
                    .opacity(showText ? 1.0 : 0.0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            spawnConfetti()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                showText = true
            }
        }
    }

    private func spawnConfetti() {
        let symbols = ["⭐️", "💪", "🔥", "✨", "🎉", "💥"]
        let colors: [Color] = [.orange, .blue, .green, .purple, .yellow, .red]

        for i in 0..<18 {
            let startX = CGFloat.random(in: 20...170)
            let startY: CGFloat = -10
            let endY = CGFloat.random(in: 40...180)

            let particle = ConfettiParticle(
                x: startX,
                y: startY,
                color: colors[i % colors.count],
                symbol: symbols[i % symbols.count],
                size: CGFloat.random(in: 10...18)
            )
            particles.append(particle)

            let index = particles.count - 1
            withAnimation(.interpolatingSpring(stiffness: 30, damping: 6).delay(Double(i) * 0.05)) {
                particles[index].y = endY
            }
            withAnimation(.easeOut(duration: 0.5).delay(1.8 + Double(i) * 0.02)) {
                particles[index].opacity = 0
            }
        }
    }
}

// MARK: - Workout Phase View
struct WorkoutPhaseView: View {
    let title: String
    @Binding var sets: [WorkoutSet]
    @Binding var selectedTab: Int
    let currentTab: Int
    let nextTab: Int
    var onRestStart: () -> Void
    var onPlateCalc: (Double) -> Void

    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        VStack {
            Text(title)
                .font(.system(.title2, design: .rounded, weight: .black))
                .padding(.bottom, 4)

            if workoutManager.running {
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill").foregroundStyle(.red)
                        Text(String(format: "%.0f", workoutManager.heartRate))
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "timer").foregroundStyle(.secondary)
                        Text(workoutManager.elapsedTimeString)
                    }
                }
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(.secondary)
                .padding(.bottom, 4)
                .accessibilityLabel("Heart rate: \(Int(workoutManager.heartRate)) BPM. Duration: \(workoutManager.elapsedTimeString)")
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach($sets) { $workoutSet in
                        SetRowView(workoutSet: $workoutSet, onComplete: onRestStart, onPlateCalc: { onPlateCalc(workoutSet.weight) })
                    }
                }
            }

            Spacer()

            HStack(spacing: 20) {
                Button("Skip Phase") {
                    withAnimation {
                        // Mark all uncompleted sets as not happening, then move on.
                        // For the purpose of the UI, skipping just moves past them.
                        selectedTab = nextTab
                    }
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
                .accessibilityLabel("Skip this phase")
                
                Button("Next") {
                    withAnimation {
                        selectedTab = nextTab
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel("Go to next phase")
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

// MARK: - Set Row View
struct SetRowView: View {
    @Binding var workoutSet: WorkoutSet
    var onComplete: () -> Void
    var onPlateCalc: () -> Void
    
    @FocusState private var isRepFieldFocused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if workoutSet.type == .accessory {
                    Text(workoutSet.reps)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(workoutSet.isCompleted ? .secondary : .primary)
                } else {
                    Button(action: onPlateCalc) {
                        Text("\(String(format: "%.1f", workoutSet.weight))")
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .foregroundStyle(workoutSet.isCompleted ? .secondary : .primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(String(format: "%.1f", workoutSet.weight)). Tap for plate calculator.")
                    
                    if workoutSet.reps.contains("+") {
                        HStack(spacing: 6) {
                            Text("REPS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                            
                            Text("\(workoutSet.actualReps)")
                                .font(.system(.title3, design: .rounded, weight: .black))
                                .foregroundStyle(isRepFieldFocused ? .black : .accentColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(isRepFieldFocused ? Color.accentColor : Color.white.opacity(0.1))
                                .clipShape(Capsule())
                                .focusable()
                                .focused($isRepFieldFocused)
                                .digitalCrownRotation($workoutSet.actualReps.toDouble(), from: 0, through: 50, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                                .accessibilityLabel("AMRAP reps: \(workoutSet.actualReps). Use Digital Crown to adjust.")
                        }
                    } else {
                        Text("\(workoutSet.reps) Reps")
                            .font(.system(.subheadline, design: .rounded, weight: .bold))
                            .foregroundColor(workoutSet.isCompleted ? .secondary.opacity(0.5) : .secondary)
                    }
                }
            }
            Spacer()

            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    if !workoutSet.isCompleted {
                        if workoutSet.reps.contains("+") && workoutSet.actualReps == 0 {
                            let target = Int(workoutSet.reps.replacingOccurrences(of: "+", with: "")) ?? 0
                            workoutSet.actualReps = target
                        }
                        WKInterfaceDevice.current().play(.success)
                        onComplete()
                    } else {
                        WKInterfaceDevice.current().play(.click)
                    }
                    workoutSet.isCompleted.toggle()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(workoutSet.isCompleted ? Color.green : Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)
                        .shadow(color: workoutSet.isCompleted ? Color.green.opacity(0.4) : .clear, radius: 4, x: 0, y: 2)
                    
                    Image(systemName: workoutSet.isCompleted ? "checkmark" : "circle")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(workoutSet.isCompleted ? .black : .white.opacity(0.5))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(workoutSet.isCompleted ? "Mark set as not done" : "Mark set as done")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Material.thinMaterial)
        .cornerRadius(20)
        .opacity(workoutSet.isCompleted ? 0.6 : 1.0)
    }
}

// MARK: - Helpers
extension Binding where Value == Int {
    func toDouble() -> Binding<Double> {
        return Binding<Double>(
            get: { Double(self.wrappedValue) },
            set: { self.wrappedValue = Int($0) }
        )
    }
}

// MARK: - Rest Timer View
struct RestTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("REST")
                .font(.system(.footnote, design: .rounded, weight: .black))
                .foregroundColor(.secondary)
                .kerning(2.0)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: Double(timeRemaining) / 90.0)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: timeRemaining)
                
                Text("\(timeRemaining)")
                    .font(.system(size: 50, weight: .black, design: .rounded))
                    .contentTransition(.numericText())
                    .animation(.snappy, value: timeRemaining)
            }
            .frame(width: 120, height: 120)
            .accessibilityLabel("Rest timer: \(timeRemaining) seconds remaining")

            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                Text("SKIP")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 100, height: 40)
                    .background(Capsule().fill(Color.white.opacity(0.2)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip rest timer")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.85))
        .background(Material.ultraThin)
        .ignoresSafeArea()
    }
}

#Preview {
    WorkoutActiveView(lift: .squat, profile: UserProfile(), accessories: [])
        .environmentObject(WorkoutManager())
}

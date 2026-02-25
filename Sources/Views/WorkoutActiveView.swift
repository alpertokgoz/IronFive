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

            // FSL Supplemental
            WorkoutPhaseView(title: "FSL", sets: $fslSets, selectedTab: $selectedTab, currentTab: 2, nextTab: 3, onRestStart: startRestTimer, onPlateCalc: { weight in selectedWeightForCalc = weight })
                .tabItem { Text("FSL") }
                .tag(2)

            // Accessories
            WorkoutPhaseView(title: "Accessories", sets: $accessorySets, selectedTab: $selectedTab, currentTab: 3, nextTab: 4, onRestStart: startRestTimer, onPlateCalc: { _ in })
                .tabItem { Text("Accessories") }
                .tag(3)

            // Finish
            VStack {
                Text("Great Job!")
                    .font(.title)
                    .fontWeight(.bold)

                Spacer()

                Button("Finish Workout") {
                    workoutManager.endWorkout()

                    // Find the AMRAP set if it exists and was completed
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

                    if lift == .ohp {
                        if profile.currentWeek < 4 {
                            profile.currentWeek += 1
                        } else {
                            profile.currentWeek = 1
                            profile.currentCycle += 1
                            profile.squat1RM += 10
                            profile.deadlift1RM += 10
                            profile.bench1RM += 5
                            profile.ohp1RM += 5
                        }
                    }

                    try? modelContext.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
            .tabItem { Text("Finish") }
            .tag(4)
        }
        .tabViewStyle(.page)
        .navigationTitle(lift.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let sets = WorkoutCalculator.generateWorkout(for: lift, profile: profile, accessories: accessories)
            warmupSets = sets.warmup
            mainSets = sets.main
            fslSets = sets.fsl
            accessorySets = sets.accessorySets
            workoutManager.startWorkout()
        }
        .overlay {
            if showRestTimer {
                RestTimerView(timeRemaining: $restTimeRemaining, isPresented: $showRestTimer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(item: Binding(
            get: { selectedWeightForCalc.map { WeightIdentifiable(weight: $0) } },
            set: { selectedWeightForCalc = $0?.weight }
        )) { item in
            PlateCalculatorView(targetWeight: item.weight)
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

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                showRestTimer = false
                timer?.invalidate()
                WKInterfaceDevice.current().play(.success)
            }
        }
    }
}

// Extracting Phase View for Reusability
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
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 8)

            if workoutManager.running && currentTab == 0 { // Show only on first page to save space
                HStack {
                    Image(systemName: "heart.fill").foregroundStyle(.red)
                    Text(String(format: "%.0f BPM", workoutManager.heartRate))
                }
                .font(.caption)
                .padding(.bottom, 4)
            }

            ScrollView {
                VStack(spacing: 8) {
                    ForEach($sets) { $workoutSet in
                        SetRowView(workoutSet: $workoutSet, onComplete: onRestStart, onPlateCalc: { onPlateCalc(workoutSet.weight) })
                    }
                }
            }

            Spacer()

            Button("Next") {
                withAnimation {
                    selectedTab = nextTab
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .padding()
    }
}

struct SetRowView: View {
    @Binding var workoutSet: WorkoutSet
    var onComplete: () -> Void
    var onPlateCalc: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Button(action: onPlateCalc) {
                    Text("\(String(format: "%.1f", workoutSet.weight)) lbs")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                
                if workoutSet.reps.contains("+") {
                    HStack {
                        Text("Actual:")
                        TextField("Reps", value: $workoutSet.actualReps, format: .number)
                            .multilineTextAlignment(.center)
                            .frame(width: 44)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                    .font(.subheadline)
                } else {
                    Text("\(workoutSet.reps) Reps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()

            Button(action: {
                // If checking it off, trigger the timer
                if !workoutSet.isCompleted {
                    // Set default actual reps for AMRAP if not set
                    if workoutSet.reps.contains("+") && workoutSet.actualReps == 0 {
                        let target = Int(workoutSet.reps.replacingOccurrences(of: "+", with: "")) ?? 0
                        workoutSet.actualReps = target
                    }
                    onComplete()
                }
                workoutSet.isCompleted.toggle()
            }) {
                Image(systemName: workoutSet.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(workoutSet.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RestTimerView: View {
    @Binding var timeRemaining: Int
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            Text("Rest")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: Double(timeRemaining) / 90.0)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: timeRemaining)
                
                Text("\(timeRemaining)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
            }
            .frame(width: 100, height: 100)
            .padding()

            Button("Skip") {
                isPresented = false
            }
            .buttonStyle(.bordered)
            .tint(.red)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.95))
        .cornerRadius(20)
        .ignoresSafeArea()
    }
}

#Preview {
    WorkoutActiveView(lift: .squat, profile: UserProfile(), accessories: [])
        .environmentObject(WorkoutManager())
}

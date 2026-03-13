import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var userProfiles: [UserProfile]
    @Query private var accessories: [AccessoryExercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var showOnboarding = false
    @State private var showLiftPicker = false
    @State private var overrideLift: MainLift?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 6) {
                if let profile = userProfiles.first {
                    let nextLift = overrideLift ?? determineNextLift()
                    
                    // Header with Cycle Info
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("CYCLE \(profile.currentCycle)")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.accentColor)
                            Text(weekDescription(for: profile.currentWeek).uppercased())
                                .font(.system(size: 14, weight: .black, design: .rounded))
                        }
                        Spacer()
                        
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 12, weight: .bold))
                                .padding(8)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 2)
                    
                    // Weekly Progress Dots
                    HStack(spacing: 8) {
                        ForEach(MainLift.allCases, id: \.self) { lift in
                            let completed = isLiftCompletedThisWeek(lift, week: profile.currentWeek, cycle: profile.currentCycle)
                            ZStack {
                                Circle()
                                    .fill(completed ? lift.color : Color.clear)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(completed ? lift.color : Color.white.opacity(0.2), lineWidth: 1.5)
                                    )
                                Image(systemName: lift.symbolName)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(completed ? .white : .secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Color.white.opacity(0.05)))
                    
                    Spacer(minLength: 0)
                    
                    // Main Glanceable Card
                    VStack(spacing: 0) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(nextLift.color.opacity(0.1))
                            
                            VStack(spacing: 2) {
                                Image(systemName: nextLift.symbolName)
                                    .font(.system(size: 30, weight: .black))
                                    .foregroundStyle(nextLift.color.gradient)
                                
                                Text(nextLift.name.uppercased())
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                
                                let tm = getTM(for: nextLift, profile: profile)
                                Text("TM: \(String(format: "%.1f", tm))\(profile.weightUnit.label)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(height: 80)
                        
                        NavigationLink(destination: WorkoutActiveView(lift: nextLift, profile: profile, accessories: accessories)) {
                            HStack {
                                Text("START WORKOUT")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                Spacer()
                                Image(systemName: "play.fill")
                                    .font(.system(size: 10))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(nextLift.color.gradient)
                            .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                    
                    Spacer(minLength: 0)
                    
                    // Quick Stats
                    HStack(spacing: 8) {
                        let bestE1RM = workoutSessions.filter { $0.mainLift == nextLift && $0.isCompleted }.map { $0.estimated1RM }.max() ?? 0
                        if bestE1RM > 0 {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("BEST E1RM")
                                    .font(.system(size: 7, weight: .black))
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", bestE1RM))")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                        }
                        
                        Spacer()
                        
                        Button(action: { showLiftPicker = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                Text("OTHER")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 24)
                    
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange.gradient)
                        
                        Text("IronFive")
                            .font(.system(.title3, design: .rounded, weight: .black))
                        
                        Button("Get Started") {
                            showOnboarding = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
            }
        }
        .containerBackground(Color.black.gradient, for: .navigation)
        .confirmationDialog("Change Lift", isPresented: $showLiftPicker, titleVisibility: .visible) {
            ForEach(MainLift.allCases, id: \.self) { lift in
                Button {
                    overrideLift = lift
                } label: {
                    HStack {
                        Image(systemName: lift.symbolName)
                        Text(lift.name)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            workoutManager.requestAuthorization()
            if userProfiles.isEmpty {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .onChange(of: workoutSessions.count) { oldValue, newValue in
            overrideLift = nil
        }
    }

    private var welcomeMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    private func weekDescription(for week: Int) -> String {
        switch week {
        case 1: return "5's Week"
        case 2: return "3's Week"
        case 3: return "5/3/1 Week"
        case 4: return "Deload"
        default: return "Training"
        }
    }

    private func determineNextLift() -> MainLift {
        guard let lastSession = workoutSessions.first else {
            return .squat
        }
        switch lastSession.mainLift {
        case .squat: return .bench
        case .bench: return .deadlift
        case .deadlift: return .ohp
        case .ohp: return .squat
        }
    }

    private func isLiftCompletedThisWeek(_ lift: MainLift, week: Int, cycle: Int) -> Bool {
        workoutSessions.contains { $0.mainLift == lift && $0.week == week && $0.cycle == cycle && $0.isCompleted }
    }

    private func getTM(for lift: MainLift, profile: UserProfile) -> Double {
        switch lift {
        case .squat: return profile.squatTM
        case .bench: return profile.benchTM
        case .deadlift: return profile.deadliftTM
        case .ohp: return profile.ohpTM
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    DashboardView()
}

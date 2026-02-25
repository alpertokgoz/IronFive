import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var userProfiles: [UserProfile]
    @Query private var accessories: [AccessoryExercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if let profile = userProfiles.first {
                    let nextLift = determineNextLift()
                    
                    // Main Glanceable Card
                    VStack(spacing: 4) {
                        Text("Cycle \(profile.currentCycle) • Week \(profile.currentWeek)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        Text(nextLift.name)
                            .font(.title2)
                            .fontWeight(.black)
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 8)
                    
                    // Action Button
                    NavigationLink(destination: WorkoutActiveView(lift: nextLift, profile: profile, accessories: accessories)) {
                        VStack {
                            Image(systemName: "play.fill")
                                .font(.title3)
                            Text("Start")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .frame(height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // Secondary Actions
                    HStack(spacing: 8) {
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .buttonStyle(.bordered)
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("IronFive")
                        .font(.headline)
                    Text("Setup 1RMs to start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    NavigationLink("Settings", destination: SettingsView())
                }
            }
            .padding(.horizontal)
            .containerBackground(Color.accentColor.gradient, for: .navigation)
        }
        .onAppear {
            if userProfiles.isEmpty {
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
            }

            workoutManager.requestAuthorization()
        }
    }

    private func determineNextLift() -> MainLift {
        guard let lastSession = workoutSessions.first else {
            return .squat
        }

        // Progression order: Squat -> Bench -> Deadlift -> OHP -> (Repeat)
        switch lastSession.mainLift {
        case .squat: return .bench
        case .bench: return .deadlift
        case .deadlift: return .ohp
        case .ohp: return .squat
        }
    }
}

#Preview {
    DashboardView()
}

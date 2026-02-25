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
            VStack(spacing: 16) {
                if let profile = userProfiles.first {
                    VStack(spacing: 4) {
                        Text("Cycle \(profile.currentCycle) • Week \(profile.currentWeek)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        
                        Text("Next Lift")
                            .font(.subheadline)
                    }

                    let nextLift = determineNextLift()
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.gradient)
                            .frame(height: 100)
                        
                        VStack {
                            Text(nextLift.name)
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal)

                    NavigationLink(destination: WorkoutActiveView(lift: nextLift, profile: profile, accessories: accessories)) {
                        Text("Start Workout")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .foregroundColor(.accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.top)
                } else {
                    Text("Welcome to IronFive!")
                        .font(.headline)
                    Text("Please set up your 1RMs in Settings to begin.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 20) {
                    NavigationLink(destination: HistoryView()) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gear")
                    }
                }
                .padding(.top)
            }
            .padding()
            .navigationTitle("IronFive")
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

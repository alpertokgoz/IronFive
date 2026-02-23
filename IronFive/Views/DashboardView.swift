import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var userProfiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let profile = userProfiles.first {
                    Text("Cycle \(profile.currentCycle) - Week \(profile.currentWeek)")
                        .font(.headline)
                    
                    Text("Today's Lift:")
                        .font(.subheadline)
                    
                    Text(determineNextLift(profile: profile).name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.tint)
                    
                    NavigationLink(destination: WorkoutActiveView(lift: determineNextLift(profile: profile))) {
                        Text("Start Workout")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                } else {
                    Text("Welcome to IronFive!")
                        .font(.headline)
                    Text("Please set up your 1RMs in Settings to begin.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
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
    
    private func determineNextLift(profile: UserProfile) -> MainLift {
        return .squat
    }
}

#Preview {
    DashboardView()
}

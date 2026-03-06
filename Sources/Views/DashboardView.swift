import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var userProfiles: [UserProfile]
    @Query private var accessories: [AccessoryExercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if let profile = userProfiles.first {
                    let nextLift = determineNextLift()
                    
                    // Main Glanceable Card
                    VStack(spacing: 6) {
                        Text("Cycle \(profile.currentCycle) • Week \(profile.currentWeek)")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundStyle(.white.opacity(0.8))
                            .textCase(.uppercase)
                            .kerning(1.2)
                        
                        Text(nextLift.name)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.top, 12)
                    
                    // Action Button (Large, prominent)
                    NavigationLink(destination: WorkoutActiveView(lift: nextLift, profile: profile, accessories: accessories)) {
                        HStack {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.title2)
                            Text("START")
                                .font(.system(.title3, design: .rounded, weight: .black))
                        }
                        .frame(maxWidth: .infinity, minHeight: 64)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(liftColor(nextLift).gradient)
                            .shadow(color: liftColor(nextLift).opacity(0.4), radius: 8, x: 0, y: 4)
                    )
                    
                    // Secondary Actions
                    HStack(spacing: 12) {
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(white: 0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color(white: 0.2))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, 8)
                    
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.orange.gradient)
                        
                        Text("IronFive")
                            .font(.system(.title3, design: .rounded, weight: .black))
                        
                        Text("Set your 1RMs to begin your journey.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        NavigationLink("Setup Now", destination: SettingsView())
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }
                    .padding()
                }
            }
            .padding(.horizontal)
            .containerBackground(Color.black.gradient, for: .navigation)
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

    private func liftColor(_ lift: MainLift) -> Color {
        switch lift {
        case .squat: return .orange
        case .bench: return .blue
        case .deadlift: return .green
        case .ohp: return .purple
        }
    }
}

#Preview {
    DashboardView()
}

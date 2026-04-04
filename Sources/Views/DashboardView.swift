import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var userProfiles: [UserProfile]
    @Query private var accessories: [AccessoryExercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) var workoutManager
    @State private var sessionService: WorkoutSessionService?
    @State private var showOnboarding = false
    @State private var showLiftPicker = false
    @State private var overrideLift: MainLift?
    @State private var showSkipDeloadConfirmation = false

    private var workoutSessionService: WorkoutSessionService {
        if let service = sessionService {
            return service
        }
        let service = WorkoutSessionService(modelContext: modelContext)
        DispatchQueue.main.async {
            sessionService = service
        }
        return service
    }

    var body: some View {
        NavigationView {
            Group {
                if let profile = userProfiles.first {
                    let nextLift = overrideLift ?? workoutSessionService.determineNextLift(profile: profile, sessions: workoutSessions)
                    TabView {
                        // MARK: Page 1 — Action
                        actionPage(profile: profile, nextLift: nextLift)
                            .tag(0)

                        // MARK: Page 2 — Session Preview & Stats
                        previewPage(profile: profile, nextLift: nextLift)
                            .tag(1)
                    }
                    .tabViewStyle(.page)
                } else {
                    EmptyStateView(showOnboarding: $showOnboarding)
                }
            }
        }
        .containerBackground(Color.black.gradient, for: .navigation)
        .confirmationDialog("Change Lift", isPresented: $showLiftPicker, titleVisibility: .visible) {
            ForEach(MainLift.allCases, id: \.self) { lift in
                Button { overrideLift = lift } label: {
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
        .onChange(of: workoutSessions.count) { _, _ in
            overrideLift = nil
        }
        .alert("Skip Deload?", isPresented: $showSkipDeloadConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Skip & Progress") {
                if let profile = userProfiles.first {
                    workoutSessionService.advanceCycle(profile: profile)
                }
            }
        } message: {
            Text("This will apply TM progression and start the next cycle.")
        }
    }

    // MARK: - Page Views

    @ViewBuilder
    private func actionPage(profile: UserProfile, nextLift: MainLift) -> some View {
        VStack(spacing: 3) {
            DashboardHeader(profile: profile)

            WeeklyProgressDots(profile: profile, workoutSessions: workoutSessions, activeLift: nextLift)
                .padding(.vertical, 1)

            MainGlanceableCard(
                nextLift: nextLift,
                profile: profile,
                showSkipDeloadConfirmation: $showSkipDeloadConfirmation,
                accessories: accessories
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.top, 0)
    }

    @ViewBuilder
    private func previewPage(profile: UserProfile, nextLift: MainLift) -> some View {
        VStack(spacing: 4) {
            // Mini lift header - Simplified now that nav is on Page 1
            HStack(spacing: 6) {
                Image(systemName: nextLift.symbolName)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(nextLift.color.gradient)
                Text(nextLift.name.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                Spacer()
            }
            .padding(.horizontal, 4)

            WorkoutPreviewCard(
                profile: profile,
                nextLift: nextLift,
                accessories: accessories
            )

            QuickStatsView(
                profile: profile,
                nextLift: nextLift,
                workoutSessions: workoutSessions,
                showLiftPicker: $showLiftPicker
            )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.top, 6)
    }
}

#Preview {
    DashboardView()
}

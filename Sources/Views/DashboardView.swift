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
    @State private var showSkipDeloadConfirmation = false

    var body: some View {
        NavigationView {
            Group {
                if let profile = userProfiles.first {
                    let nextLift = overrideLift ?? determineNextLift()
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
                    advanceCycle(profile: profile)
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

            WeeklyProgressDots(profile: profile, workoutSessions: workoutSessions)
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
        .padding(.top, 8)
    }

    // MARK: - Logic

    private func advanceCycle(profile: UserProfile) {
        profile.currentCycle += 1
        profile.currentWeek = 1
        let increment = profile.weightUnit == .lbs ? 5.0 : 2.5
        profile.squatTM += increment * 2
        profile.benchTM += increment
        profile.deadliftTM += increment * 2
        profile.ohpTM += increment
        try? modelContext.save()
    }

    private func determineNextLift() -> MainLift {
        if let profile = userProfiles.first {
            for lift in MainLift.allCases where !isLiftCompletedThisWeek(lift, week: profile.currentWeek, cycle: profile.currentCycle, sessions: workoutSessions) {
                return lift
            }
        }
        guard let lastSession = workoutSessions.first else { return .squat }
        switch lastSession.mainLift {
        case .squat: return .bench
        case .bench: return .deadlift
        case .deadlift: return .ohp
        case .ohp: return .squat
        }
    }

    private func isLiftCompletedThisWeek(_ lift: MainLift, week: Int, cycle: Int, sessions: [WorkoutSession]) -> Bool {
        sessions.contains { $0.mainLift == lift && $0.week == week && $0.cycle == cycle && $0.isCompleted }
    }
}

#Preview {
    DashboardView()
}

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var userProfiles: [UserProfile]
    @Query private var accessories: [AccessoryExercise]
    @Query(sort: \ActiveWorkoutSession.startTime, order: .reverse) private var activeSessions: [ActiveWorkoutSession]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @Environment(WorkoutManager.self) var workoutManager
    @State private var sessionService: WorkoutSessionService?
    @State private var showOnboarding = false
    @State private var showLiftPicker = false
    @State private var overrideLift: MainLift?
    @State private var workoutLift: MainLift?
    @State private var selectedPage = 0

    init(initialPage: Int = 0) {
        _selectedPage = State(initialValue: initialPage)
    }
    @State private var showSkipDeloadConfirmation = false

    private var workoutSessionService: WorkoutSessionService {
        if let service = sessionService {
            return service
        }
        return WorkoutSessionService(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let profile = userProfiles.first {
                    let nextLift = activeSessions.first?.mainLift ?? overrideLift ?? workoutSessionService.determineNextLift(profile: profile, sessions: workoutSessions)
                    TabView(selection: $selectedPage) {
                        // MARK: Page 1 — Action
                        actionPage(profile: profile, nextLift: nextLift)
                            .tag(0)

                        // MARK: Page 2 — Session Preview & Stats
                        previewPage(profile: profile, nextLift: nextLift)
                            .tag(1)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .automatic))
                } else {
                    EmptyStateView(showOnboarding: $showOnboarding)
                }
            }
            .navigationDestination(item: $workoutLift) { lift in
                if let profile = userProfiles.first {
                    WorkoutActiveView(lift: lift, profile: profile, accessories: accessories)
                }
            }
        }
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
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
            if sessionService == nil {
                sessionService = WorkoutSessionService(modelContext: modelContext)
            }
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
        .alert("Apple Health Error", isPresented: Binding(
            get: { workoutManager.workoutError != nil },
            set: { if !$0 { workoutManager.workoutError = nil } }
        )) {
            Button("OK") { workoutManager.workoutError = nil }
        } message: {
            Text(workoutManager.workoutError ?? "Please try again.")
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
        GeometryReader { geometry in
            let compact = geometry.size.height < 185
            VStack(spacing: compact ? 4 : 6) {
                DashboardHeader(profile: profile, compact: compact)
                WeeklyProgressDots(profile: profile, workoutSessions: workoutSessions, activeLift: nextLift)
                MainGlanceableCard(
                    nextLift: nextLift, profile: profile,
                    isResuming: activeSessions.contains { $0.mainLift == nextLift },
                    compact: compact, onStart: { workoutLift = nextLift }
                )
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
        }
    }

    @ViewBuilder
    private func previewPage(profile: UserProfile, nextLift: MainLift) -> some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 185
            VStack(spacing: compact ? 4 : 6) {
                HStack {
                    IronEyebrow(text: "Today's plan", color: nextLift.color)
                    Spacer(minLength: 0)
                    if profile.currentWeek == 4 {
                        Button { showSkipDeloadConfirmation = true } label: {
                            Image(systemName: "forward.end").frame(width: 30, height: 24)
                        }
                        .buttonStyle(.plain)
                        .disabled(!activeSessions.isEmpty)
                        .accessibilityLabel("Skip deload week")
                    }
                }
                WorkoutPreviewCard(profile: profile, nextLift: nextLift, accessories: accessories, compact: compact)
                QuickStatsView(profile: profile, nextLift: nextLift, workoutSessions: workoutSessions,
                               showLiftPicker: $showLiftPicker, compact: compact, canChangeLift: activeSessions.isEmpty)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
        }
    }

}

#Preview {
    DashboardView()
}

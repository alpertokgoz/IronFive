import SwiftUI
import SwiftData
import Observation

enum DesignPreview {
    static var isEnabled: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--design-preview")
        #else
        false
        #endif
    }

    #if DEBUG
    static func seed(_ container: ModelContainer) {
        let context = ModelContext(container)
        let profile = UserProfile(squatTM: 140, benchTM: 90, deadliftTM: 180, ohpTM: 55,
                                  currentCycle: 3, currentWeek: 2, weightUnit: .kg, isAutopilotEnabled: true)
        context.insert(profile)
        for lift in MainLift.allCases {
            for exercise in profile.selectedTemplate.defaultAccessories(for: lift) { context.insert(exercise) }
        }
        for lift in MainLift.allCases {
            for offset in 1...6 {
                let weight = WorkoutCalculator.getTM(for: lift, from: profile) * (0.76 + Double(6 - offset) * 0.018)
                let session = WorkoutSession(date: Date().addingTimeInterval(Double(-offset * 7 * 86400)),
                                             mainLift: lift, week: (offset % 3) + 1, cycle: max(1, 2 - offset / 3),
                                             isCompleted: true, amrapReps: 7, amrapWeight: weight)
                context.insert(session)
            }
        }
        let generated = WorkoutCalculator.generateWorkout(for: .squat, profile: profile, accessories: [])
        let sets = generated.warmup + generated.main + generated.supplemental
        let steps = sets.enumerated().map { index, set in
            var workoutSet = set
            workoutSet.isCompleted = index < 4
            return WorkoutStep(title: set.type == .warmup ? "Warmup" : set.type == .main ? "Main" : "FSL",
                               liftIcon: MainLift.squat.symbolName, workoutSet: workoutSet,
                               totalSetsInPhase: set.type == .supplemental ? 5 : 3,
                               setNumberInPhase: set.type == .warmup ? index + 1 : set.type == .main ? index - 2 : index - 5,
                               isAMRAP: set.reps.contains("+"), percentage: nil)
        }
        context.insert(ActiveWorkoutSession(mainLift: .squat, steps: steps, currentStepIndex: 4))
        try? context.save()
        WorkoutManager.shared.heartRate = 124
        WorkoutManager.shared.activeEnergy = 86
        WorkoutManager.shared.elapsedTimeString = "32:14"
    }
    #endif
}

#if DEBUG
@objc(IFTVisualAudit)
@Observable
final class DesignAudit: NSObject {
    static let shared = DesignAudit()
    var screen: String?
    @objc static func show(_ screen: String) { shared.screen = screen }
}

struct DesignPreviewLaunchView: View {
    @Query private var profiles: [UserProfile]
    @Environment(WorkoutManager.self) private var manager
    @State private var restSeconds = 124
    @State private var reps = 8
    @State private var weight = 120.0
    @State private var audit = DesignAudit.shared
    @Query private var accessories: [AccessoryExercise]

    private var screen: String {
        if let selected = audit.screen { return selected }
        return ProcessInfo.processInfo.arguments.first { $0.hasPrefix("--design-screen=") }?
            .replacingOccurrences(of: "--design-screen=", with: "") ?? "gallery"
    }

    var body: some View {
        if let profile = profiles.first {
            screenView(profile)
                .id(screen)
        }
    }

    @ViewBuilder
    private func screenView(_ profile: UserProfile) -> some View {
        if screen.hasPrefix("onboarding-") {
            OnboardingView(initialStep: Int(screen.replacingOccurrences(of: "onboarding-", with: "")) ?? 0)
        } else if screen.hasPrefix("workout-") {
            workoutView(profile)
        } else if let additional = additionalView(profile) {
            additional
        } else {
            basicView(profile)
        }
    }

    @ViewBuilder
    private func basicView(_ profile: UserProfile) -> some View {
            switch screen {
            case "dashboard": DashboardView()
            case "workout":
                NavigationStack { WorkoutActiveView(lift: .squat, profile: profile, accessories: []) }
            case "rest":
                NavigationStack {
                    RestTimerView(timeRemaining: restSeconds, nextSet: "120 kg × 3",
                                  onAdjust: { restSeconds = max(5, restSeconds + $0) }, onSkip: { restSeconds = 0 })
                }
            case "summary":
                NavigationStack {
                    WorkoutSummaryView(workoutManager: manager, profile: profile, totalWeight: 8_420,
                                       showCelebration: false, completedSets: 18, totalSets: 18, onFinish: {})
                }
            case "history": NavigationStack { HistoryView() }
            case "settings": NavigationStack { SettingsView() }
            case "onboarding": OnboardingView()
            case "weight": SetWeightEditor(weight: $weight, unit: .kg)
            case "amrap": AmrapInputView(reps: $reps, liftName: "Squat", weight: 126, weightUnit: .kg, onDone: {})
            default: DesignPreviewGallery()
            }
    }
}

extension DesignPreviewLaunchView {
    private func workoutView(_ profile: UserProfile) -> some View {
        let indices = ["workout-warmup": 0, "workout-main": 4, "workout-amrap": 5,
                       "workout-logged": 4, "workout-supplemental": 6,
                       "workout-actions": 4, "workout-finish": 4]
        return NavigationStack {
            WorkoutActiveView(lift: .squat, profile: profile, accessories: [],
                              initialStepIndex: indices[screen] ?? 4,
                              initialStepCompleted: screen == "workout-logged" ? true : nil,
                              initialDialog: screen == "workout-actions" ? "actions" : screen == "workout-finish" ? "finish" : nil)
        }
    }

    private func additionalView(_ profile: UserProfile) -> AnyView? {
        let views: [String: () -> AnyView] = [
            "plan": { AnyView(DashboardView(initialPage: 1)) },
            "settings-program": { AnyView(NavigationStack { SettingsView(initialSection: "program") }) },
            "settings-autopilot": { AnyView(NavigationStack { SettingsView(initialSection: "autopilot") }) },
            "settings-assistance": { AnyView(NavigationStack { SettingsView(initialSection: "assistance") }) },
            "tm": { AnyView(TMEditorSheet(lift: .squat, value: $weight, unit: .kg)) },
            "assistance": { AnyView(NavigationStack { AccessorySettingsView() }) },
            "assistance-prescription": { AnyView(AddAccessoryView(editingAccessory: accessories.first, initialSection: "prescription")) },
            "age": { AnyView(CountEditor(value: $weight, title: "Age", range: 10...100, saveTitle: "Save age")) },
            "cycle-program": { AnyView(NavigationStack { CycleSummaryView(profile: profile, lastLift: .ohp, amrapReps: 8, amrapWeight: 50, onComplete: {}, initialPage: 1) }) },
            "assistance-add": { AnyView(AddAccessoryView()) },
            "assistance-edit": { AnyView(AddAccessoryView(editingAccessory: accessories.first)) },
            "plates": { AnyView(NavigationStack { PlateCalculatorView(targetWeight: 122.5, unit: .kg) }) },
            "cycle": { AnyView(NavigationStack { CycleSummaryView(profile: profile, lastLift: .ohp, amrapReps: 8, amrapWeight: 50, onComplete: {}) }) },
            "empty": { AnyView(NavigationStack { EmptyStateView(showOnboarding: .constant(false)) }) },
            "summary-partial": { AnyView(NavigationStack {
                WorkoutSummaryView(workoutManager: manager, profile: profile, totalWeight: 4_200,
                                   showCelebration: false, completedSets: 7, totalSets: 18, onFinish: {})
            }) },
            "summary-pr": { AnyView(NavigationStack {
                WorkoutSummaryView(workoutManager: manager, profile: profile, totalWeight: 8_420,
                                   showCelebration: true, completedSets: 18, totalSets: 18,
                                   personalBestReps: 8, personalBestWeight: 126, onFinish: {})
            }) }
        ]
        return views[screen]?()
    }
}

struct DesignPreviewGallery: View {
    @Query private var profiles: [UserProfile]
    @State private var restSeconds = 124
    @Environment(WorkoutManager.self) private var manager
    @State private var previewReps = 8

    var body: some View {
        NavigationStack {
            List {
                if let profile = profiles.first {
                    NavigationLink("Dashboard") { DashboardView() }
                    NavigationLink("Active set") { WorkoutActiveView(lift: .squat, profile: profile, accessories: []) }
                    NavigationLink("Rest timer") {
                        RestTimerView(timeRemaining: restSeconds, nextSet: "120 kg × 3",
                                      onAdjust: { restSeconds = max(5, restSeconds + $0) }, onSkip: { restSeconds = 0 })
                    }
                    NavigationLink("Workout summary") {
                        WorkoutSummaryView(workoutManager: manager, profile: profile, totalWeight: 8_420,
                                           showCelebration: false, completedSets: 18, totalSets: 18, onFinish: {})
                    }
                    NavigationLink("AMRAP input") {
                        AmrapInputView(reps: $previewReps, liftName: "Squat", weight: 126, weightUnit: .kg, onDone: {})
                    }
                    NavigationLink("Progress history") { HistoryView() }
                    NavigationLink("Settings") { SettingsView() }
                    NavigationLink("Onboarding") { OnboardingView() }
                    NavigationLink("Plate loading") { PlateCalculatorView(targetWeight: 120, unit: .kg) }
                }
            }
            .navigationTitle("Design preview")
            .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        }
    }
}
#endif

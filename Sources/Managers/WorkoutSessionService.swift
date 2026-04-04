import Foundation
import SwiftData
import Observation

@Observable
class WorkoutSessionService {
    var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func determineNextLift(profile: UserProfile, sessions: [WorkoutSession]) -> MainLift {
        for lift in MainLift.allCases where !isLiftCompletedThisWeek(lift, week: profile.currentWeek, cycle: profile.currentCycle, sessions: sessions) {
            return lift
        }
        guard let lastSession = sessions.first else { return .squat }
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

    func advanceCycle(profile: UserProfile) {
        profile.currentCycle += 1
        profile.currentWeek = 1
        let increment = profile.weightUnit == .lbs ? 5.0 : 2.5
        profile.squatTM += increment * 2
        profile.benchTM += increment
        profile.deadliftTM += increment * 2
        profile.ohpTM += increment
        try? modelContext.save()
    }
}

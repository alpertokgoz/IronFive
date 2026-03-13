import Foundation

struct WorkoutStep: Identifiable {
    let id = UUID()
    let title: String
    let liftIcon: String?
    var workoutSet: WorkoutSet
    let totalSetsInPhase: Int
    let setNumberInPhase: Int
    let isAMRAP: Bool
    let percentage: Int?
}

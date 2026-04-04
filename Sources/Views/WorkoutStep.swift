import Foundation

struct WorkoutStep: Identifiable, Codable {
    let id: UUID
    let title: String
    let liftIcon: String?
    var workoutSet: WorkoutSet
    let totalSetsInPhase: Int
    let setNumberInPhase: Int
    let isAMRAP: Bool
    let percentage: Int?

    init(title: String, liftIcon: String?, workoutSet: WorkoutSet, totalSetsInPhase: Int, setNumberInPhase: Int, isAMRAP: Bool, percentage: Int?) {
        self.id = UUID()
        self.title = title
        self.liftIcon = liftIcon
        self.workoutSet = workoutSet
        self.totalSetsInPhase = totalSetsInPhase
        self.setNumberInPhase = setNumberInPhase
        self.isAMRAP = isAMRAP
        self.percentage = percentage
    }
}

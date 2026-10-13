import Foundation

struct WorkoutSet: Identifiable, Hashable, Codable {
    let id: UUID
    var weight: Double
    let reps: String
    let type: SetType
    var actualReps: Int // Logged reps for AMRAP
    var isCompleted: Bool = false
    var exerciseName: String // e.g. "Squat", "Leg Press"

    enum SetType: String, Codable {
        case warmup
        case main
        case supplemental // FSL
        case accessory
    }

    init(weight: Double, reps: String, type: SetType, exerciseName: String, actualReps: Int = 0, isCompleted: Bool = false) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.type = type
        self.exerciseName = exerciseName
        self.actualReps = actualReps
        self.isCompleted = isCompleted
    }

    var estimated1RM: Double {
        guard actualReps > 0 else { return 0 }
        return weight * (1.0 + (Double(actualReps) * 0.0333))
    }

    var completedReps: Int {
        if actualReps > 0 { return actualReps }
        if reps.contains("+") { return 0 }
        return Int(reps) ?? 0
    }
}

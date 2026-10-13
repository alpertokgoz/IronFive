import Foundation

struct WorkoutProgress: Codable {
    var steps: [WorkoutStep]
    var restCountdown: RestCountdown

    var isComplete: Bool {
        !steps.isEmpty && steps.allSatisfy { $0.workoutSet.isCompleted }
    }

    init(steps: [WorkoutStep], restCountdown: RestCountdown = RestCountdown()) {
        self.steps = steps
        self.restCountdown = restCountdown
    }

    static func decode(_ data: Data) throws -> WorkoutProgress {
        let decoder = JSONDecoder()
        if let progress = try? decoder.decode(WorkoutProgress.self, from: data) {
            return progress
        }
        // Existing installations stored the steps as a plain JSON array.
        return WorkoutProgress(steps: try decoder.decode([WorkoutStep].self, from: data))
    }

    func restoredIndex(_ index: Int) -> Int {
        min(max(0, index), steps.count)
    }
}

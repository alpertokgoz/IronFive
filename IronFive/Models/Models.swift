import Foundation
import SwiftData

@Model
final class UserProfile {
    var squat1RM: Double
    var bench1RM: Double
    var deadlift1RM: Double
    var ohp1RM: Double
    var trainingMaxPercentage: Double

    var currentCycle: Int
    var currentWeek: Int // 1 (5s), 2 (3s), 3 (5/3/1), 4 (Deload)

    init(squat1RM: Double = 0, bench1RM: Double = 0, deadlift1RM: Double = 0, ohp1RM: Double = 0, trainingMaxPercentage: Double = 0.90, currentCycle: Int = 1, currentWeek: Int = 1) {
        self.squat1RM = squat1RM
        self.bench1RM = bench1RM
        self.deadlift1RM = deadlift1RM
        self.ohp1RM = ohp1RM
        self.trainingMaxPercentage = trainingMaxPercentage
        self.currentCycle = currentCycle
        self.currentWeek = currentWeek
    }
}

enum MainLift: Int, Codable, CaseIterable {
    case squat = 0
    case bench = 1
    case deadlift = 2
    case ohp = 3

    var name: String {
        switch self {
        case .squat: return "Squat"
        case .bench: return "Bench Press"
        case .deadlift: return "Deadlift"
        case .ohp: return "Overhead Press"
        }
    }
}

@Model
final class AccessoryExercise {
    var name: String
    var targetSets: Int
    var targetReps: Int
    var relatedLiftValue: Int // Raw value for MainLift enum

    var relatedLift: MainLift {
        get { MainLift(rawValue: relatedLiftValue) ?? .squat }
        set { relatedLiftValue = newValue.rawValue }
    }

    init(name: String, targetSets: Int, targetReps: Int, relatedLift: MainLift) {
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.relatedLiftValue = relatedLift.rawValue
    }
}

@Model
final class WorkoutSession {
    var date: Date
    var mainLiftValue: Int
    var week: Int
    var cycle: Int
    var isCompleted: Bool

    var mainLift: MainLift {
        get { MainLift(rawValue: mainLiftValue) ?? .squat }
        set { mainLiftValue = newValue.rawValue }
    }

    init(date: Date = Date(), mainLift: MainLift, week: Int, cycle: Int, isCompleted: Bool = false) {
        self.date = date
        self.mainLiftValue = mainLift.rawValue
        self.week = week
        self.cycle = cycle
        self.isCompleted = isCompleted
    }
}

import Foundation
import SwiftUI
import SwiftData

@Model
final class UserProfile {
    var squatTM: Double = 0
    var benchTM: Double = 0
    var deadliftTM: Double = 0
    var ohpTM: Double = 0

    var currentCycle: Int = 1
    var currentWeek: Int = 1 // 1 (5s), 2 (3s), 3 (5/3/1), 4 (Deload)
    var selectedTemplateValue: Int = 0 // Raw value for SupplementalTemplate
    var weightUnitValue: Int = 0 // Raw value for WeightUnit
    var usesFourWeekCycle: Bool = false

    var selectedTemplate: SupplementalTemplate {
        get { SupplementalTemplate(rawValue: selectedTemplateValue) ?? .fsl }
        set { selectedTemplateValue = newValue.rawValue }
    }

    var weightUnit: WeightUnit {
        get { WeightUnit(rawValue: weightUnitValue) ?? .lbs }
        set { weightUnitValue = newValue.rawValue }
    }

    init(squatTM: Double = 0, benchTM: Double = 0, deadliftTM: Double = 0, ohpTM: Double = 0, currentCycle: Int = 1, currentWeek: Int = 1, selectedTemplate: SupplementalTemplate = .fsl, weightUnit: WeightUnit = .lbs) {
        self.squatTM = squatTM
        self.benchTM = benchTM
        self.deadliftTM = deadliftTM
        self.ohpTM = ohpTM
        self.currentCycle = currentCycle
        self.currentWeek = currentWeek
        self.selectedTemplateValue = selectedTemplate.rawValue
        self.weightUnitValue = weightUnit.rawValue
        self.usesFourWeekCycle = usesFourWeekCycle
    }
}

enum WeightUnit: Int, Codable, CaseIterable {
    case lbs = 0
    case kg = 1

    var label: String {
        switch self {
        case .lbs: return "lbs"
        case .kg: return "kg"
        }
    }

    var barWeight: Double {
        switch self {
        case .lbs: return 45.0
        case .kg: return 20.0
        }
    }

    var roundTo: Double {
        switch self {
        case .lbs: return 5.0
        case .kg: return 2.5
        }
    }

    var upperIncrement: Double {
        switch self {
        case .lbs: return 5.0
        case .kg: return 2.5
        }
    }

    var lowerIncrement: Double {
        switch self {
        case .lbs: return 10.0
        case .kg: return 5.0
        }
    }
}

enum SupplementalTemplate: Int, Codable, CaseIterable {
    case fsl = 0
    case bbb = 1
    case ssl = 2
    case bbs = 3
    case widowmaker = 4

    var name: String {
        switch self {
        case .fsl: return "FSL (First Set Last)"
        case .bbb: return "BBB (Boring But Big)"
        case .ssl: return "SSL (Second Set Last)"
        case .bbs: return "BBS (Boring But Strong)"
        case .widowmaker: return "Widowmaker"
        }
    }
    
    var shortName: String {
        switch self {
        case .fsl: return "FSL"
        case .bbb: return "BBB"
        case .ssl: return "SSL"
        case .bbs: return "BBS"
        case .widowmaker: return "Widow"
        }
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

    var color: Color {
        switch self {
        case .squat: return .orange
        case .bench: return .blue
        case .deadlift: return .green
        case .ohp: return .purple
        }
    }

    var isUpperBody: Bool {
        switch self {
        case .bench, .ohp: return true
        default: return false
        }
    }

    var symbolName: String {
        switch self {
        case .squat: return "figure.squat"
        case .bench: return "figure.bench.press"
        case .deadlift: return "figure.deadlift"
        case .ohp: return "figure.arms.up"
        }
    }
}

extension SupplementalTemplate {
    func defaultAccessories(for lift: MainLift) -> [AccessoryExercise] {
        switch self {
        case .bbb:
            switch lift {
            case .squat: return [AccessoryExercise(name: "Leg Curls", targetSets: 5, targetReps: 10, weight: 0, relatedLift: .squat)]
            case .bench: return [AccessoryExercise(name: "DB Rows", targetSets: 5, targetReps: 10, weight: 0, relatedLift: .bench)]
            case .deadlift: return [AccessoryExercise(name: "Hanging Leg Raises", targetSets: 5, targetReps: 10, weight: 0, relatedLift: .deadlift)]
            case .ohp: return [AccessoryExercise(name: "Pull-ups", targetSets: 5, targetReps: 10, weight: 0, relatedLift: .ohp)]
            }
        default:
            switch lift {
            case .squat: 
                return [
                    AccessoryExercise(name: "Leg Press", targetSets: 3, targetReps: 10, weight: 0, relatedLift: .squat),
                    AccessoryExercise(name: "Ab Wheel", targetSets: 3, targetReps: 15, weight: 0, relatedLift: .squat)
                ]
            case .bench:
                return [
                    AccessoryExercise(name: "Dumbbell Rows", targetSets: 3, targetReps: 10, weight: 0, relatedLift: .bench),
                    AccessoryExercise(name: "Tricep Pushdowns", targetSets: 3, targetReps: 12, weight: 0, relatedLift: .bench)
                ]
            case .deadlift:
                return [
                    AccessoryExercise(name: "Good Mornings", targetSets: 3, targetReps: 10, weight: 0, relatedLift: .deadlift),
                    AccessoryExercise(name: "Hammer Curls", targetSets: 3, targetReps: 12, weight: 0, relatedLift: .deadlift)
                ]
            case .ohp:
                return [
                    AccessoryExercise(name: "Chin-ups", targetSets: 3, targetReps: 8, weight: 0, relatedLift: .ohp),
                    AccessoryExercise(name: "Dips", targetSets: 3, targetReps: 10, weight: 0, relatedLift: .ohp)
                ]
            }
        }
    }
}

@Model
final class AccessoryExercise: Identifiable {
    var name: String = ""
    var targetSets: Int = 3
    var targetReps: Int = 10
    var weight: Double = 0
    var relatedLiftValue: Int = 0 

    var relatedLift: MainLift {
        get { MainLift(rawValue: relatedLiftValue) ?? .squat }
        set { relatedLiftValue = newValue.rawValue }
    }

    init(name: String, targetSets: Int, targetReps: Int, weight: Double = 0, relatedLift: MainLift) {
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.weight = weight
        self.relatedLiftValue = relatedLift.rawValue
    }
}

@Model
final class WorkoutSession {
    var date: Date = Date()
    var mainLiftValue: Int = 0
    var week: Int = 1
    var cycle: Int = 1
    var isCompleted: Bool = false
    var amrapReps: Int = 0
    var amrapWeight: Double = 0

    var mainLift: MainLift {
        get { MainLift(rawValue: mainLiftValue) ?? .squat }
        set { mainLiftValue = newValue.rawValue }
    }

    init(date: Date = Date(), mainLift: MainLift, week: Int, cycle: Int, isCompleted: Bool = false, amrapReps: Int = 0, amrapWeight: Double = 0) {
        self.date = date
        self.mainLiftValue = mainLift.rawValue
        self.week = week
        self.cycle = cycle
        self.isCompleted = isCompleted
        self.amrapReps = amrapReps
        self.amrapWeight = amrapWeight
    }
    
    var estimated1RM: Double {
        guard amrapReps > 0 else { return 0 }
        return amrapWeight * (1.0 + (Double(amrapReps) * 0.0333))
    }
}

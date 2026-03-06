import Foundation
import SwiftUI
import SwiftData

@Model
final class UserProfile {
    var squatTM: Double
    var benchTM: Double
    var deadliftTM: Double
    var ohpTM: Double

    var currentCycle: Int
    var currentWeek: Int // 1 (5s), 2 (3s), 3 (5/3/1), 4 (Deload)
    var selectedTemplateValue: Int // Raw value for SupplementalTemplate
    var weightUnitValue: Int // Raw value for WeightUnit
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

    /// Rounding increment for plate math
    var roundTo: Double {
        switch self {
        case .lbs: return 5.0
        case .kg: return 2.5
        }
    }

    /// Default TM progression per cycle
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
    
    // New fields for AMRAP tracking
    var amrapReps: Int
    var amrapWeight: Double

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
        // Epley Formula: Weight * (1 + 0.0333 * Reps)
        return amrapWeight * (1.0 + (Double(amrapReps) * 0.0333))
    }
}

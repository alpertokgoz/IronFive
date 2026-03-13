import Foundation
import SwiftData

struct WorkoutSet: Identifiable, Hashable {
    let id = UUID()
    let weight: Double
    let reps: String
    let type: SetType
    var actualReps: Int // Logged reps for AMRAP
    var isCompleted: Bool = false
    var exerciseName: String // e.g. "Squat", "Leg Press"

    enum SetType {
        case warmup
        case main
        case supplemental // FSL
        case accessory
    }

    init(weight: Double, reps: String, type: SetType, exerciseName: String, actualReps: Int = 0, isCompleted: Bool = false) {
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
        return Int(reps.replacingOccurrences(of: "+", with: "")) ?? 0
    }
}

struct WorkoutCalculator {

    static func getTM(for lift: MainLift, from profile: UserProfile) -> Double {
        switch lift {
        case .squat: return profile.squatTM
        case .bench: return profile.benchTM
        case .deadlift: return profile.deadliftTM
        case .ohp: return profile.ohpTM
        }
    }

    struct WorkoutGenerationContext {
        let tm: Double
        let week: Int
        let round: Double
        let liftName: String
        let profile: UserProfile
        let fslPercentage: Double
    }

    static func generateWorkout(for lift: MainLift, profile: UserProfile, accessories: [AccessoryExercise]) -> (warmup: [WorkoutSet], main: [WorkoutSet], supplemental: [WorkoutSet], accessorySets: [WorkoutSet]) {
        let tm = getTM(for: lift, from: profile)
        let week = profile.currentWeek
        let round = profile.weightUnit.roundTo
        let liftName = lift.name

        let warmup = generateWarmupSets(tm: tm, round: round, liftName: liftName)
        let mainData = generateMainSets(tm: tm, week: week, round: round, liftName: liftName)

        let context = WorkoutGenerationContext(
            tm: tm,
            week: week,
            round: round,
            liftName: liftName,
            profile: profile,
            fslPercentage: mainData.fslPercentage
        )
        let supplemental = generateSupplementalSets(context: context)

        var accessorySets: [WorkoutSet] = []
        for accessory in accessories where accessory.relatedLift == lift {
            for _ in 0..<accessory.targetSets {
                accessorySets.append(WorkoutSet(weight: accessory.weight, reps: "\(accessory.targetReps)", type: .accessory, exerciseName: accessory.name))
            }
        }

        return (warmup, mainData.sets, supplemental, accessorySets)
    }

    private static func generateWarmupSets(tm: Double, round: Double, liftName: String) -> [WorkoutSet] {
        return [
            WorkoutSet(weight: calculatedWeight(tm * 0.40, roundTo: round), reps: "5", type: .warmup, exerciseName: liftName),
            WorkoutSet(weight: calculatedWeight(tm * 0.50, roundTo: round), reps: "5", type: .warmup, exerciseName: liftName),
            WorkoutSet(weight: calculatedWeight(tm * 0.60, roundTo: round), reps: "3", type: .warmup, exerciseName: liftName)
        ]
    }

    private static func generateMainSets(tm: Double, week: Int, round: Double, liftName: String) -> (sets: [WorkoutSet], fslPercentage: Double) {
        let fslPercentage: Double
        let setDetails: [(percentage: Double, reps: String)]

        switch week {
        case 1:
            fslPercentage = 0.65
            setDetails = [(0.65, "5"), (0.75, "5"), (0.85, "5+")]
        case 2:
            fslPercentage = 0.70
            setDetails = [(0.70, "3"), (0.80, "3"), (0.90, "3+")]
        case 3:
            fslPercentage = 0.75
            setDetails = [(0.75, "5"), (0.85, "3"), (0.95, "1+")]
        case 4:
            fslPercentage = 0.40
            setDetails = [(0.40, "5"), (0.50, "5"), (0.60, "5")]
        default:
            return ([WorkoutSet(weight: calculatedWeight(tm * 0.65, roundTo: round), reps: "5", type: .main, exerciseName: liftName)], 0.65)
        }

        let sets = setDetails.map { detail in
            WorkoutSet(weight: calculatedWeight(tm * detail.percentage, roundTo: round), reps: detail.reps, type: .main, exerciseName: liftName)
        }
        return (sets, fslPercentage)
    }

    private static func generateSupplementalSets(context: WorkoutGenerationContext) -> [WorkoutSet] {
        guard context.week != 4 else { return [] }

        let targetWeight: Double
        let targetReps: String
        let setCounts: Int
        let supplementalName = "\(context.liftName) (\(context.profile.selectedTemplate.shortName))"

        switch context.profile.selectedTemplate {
        case .fsl:
            targetWeight = calculatedWeight(context.tm * context.fslPercentage, roundTo: context.round)
            targetReps = "5"
            setCounts = 5
        case .bbb:
            targetWeight = calculatedWeight(context.tm * 0.50, roundTo: context.round)
            targetReps = "10"
            setCounts = 5
        case .ssl:
            let sslPercentages: [Int: Double] = [1: 0.75, 2: 0.80, 3: 0.85]
            targetWeight = calculatedWeight(context.tm * (sslPercentages[context.week] ?? context.fslPercentage), roundTo: context.round)
            targetReps = "5"
            setCounts = 5
        case .bbs:
            targetWeight = calculatedWeight(context.tm * context.fslPercentage, roundTo: context.round)
            targetReps = "5"
            setCounts = 10
        case .widowmaker:
            targetWeight = calculatedWeight(context.tm * context.fslPercentage, roundTo: context.round)
            targetReps = "20"
            setCounts = 1
        }

        return (0..<setCounts).map { _ in
            WorkoutSet(weight: targetWeight, reps: targetReps, type: .supplemental, exerciseName: supplementalName)
        }
    }

    // Round to nearest increment (5 lbs or 2.5 kg)
    static func calculatedWeight(_ exactWeight: Double, roundTo: Double = 5.0) -> Double {
        return (exactWeight / roundTo).rounded() * roundTo
    }

    // Epley Formula for Est. 1RM (Weight * (1 + 0.0333 * Reps))
    static func calculateEstimated1RM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + (Double(reps) * 0.0333))
    }

    // Logic for suggesting TM increases based on AMRAP performance relative to current TM
    static func calculateSuggestedIncrease(lift: MainLift, currentTM: Double, amrapWeight: Double, amrapReps: Int, unit: WeightUnit) -> Double {
        let est1RM = calculateEstimated1RM(weight: amrapWeight, reps: amrapReps)
        let standardIncrease = lift.isUpperBody ? unit.upperIncrement : unit.lowerIncrement

        // If they are vastly outperforming (estimated 1RM is 10%+ over TM), suggest a double jump
        if est1RM > currentTM * 1.15 {
            return standardIncrease * 2
        } else if est1RM > currentTM * 1.05 {
            return standardIncrease
        } else if est1RM >= currentTM {
            return standardIncrease
        } else {
            // Suggest staying flat if performance was lower than expected
            return 0
        }
    }
}

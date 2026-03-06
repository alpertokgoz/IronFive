import Foundation

struct WorkoutSet: Identifiable, Hashable {
    let id = UUID()
    let weight: Double
    let reps: String
    let type: SetType
    var actualReps: Int // Logged reps for AMRAP
    var isCompleted: Bool = false

    enum SetType {
        case warmup
        case main
        case supplemental // FSL
        case accessory
    }

    init(weight: Double, reps: String, type: SetType, actualReps: Int = 0, isCompleted: Bool = false) {
        self.weight = weight
        self.reps = reps
        self.type = type
        self.actualReps = actualReps
        self.isCompleted = isCompleted
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

    static func generateWorkout(for lift: MainLift, profile: UserProfile, accessories: [AccessoryExercise]) -> (warmup: [WorkoutSet], main: [WorkoutSet], supplemental: [WorkoutSet], accessorySets: [WorkoutSet]) {
        let tm = getTM(for: lift, from: profile)
        let week = profile.currentWeek
        let round = profile.weightUnit.roundTo

        let warmup = [
            WorkoutSet(weight: calculatedWeight(tm * 0.40, roundTo: round), reps: "5", type: .warmup),
            WorkoutSet(weight: calculatedWeight(tm * 0.50, roundTo: round), reps: "5", type: .warmup),
            WorkoutSet(weight: calculatedWeight(tm * 0.60, roundTo: round), reps: "3", type: .warmup)
        ]

        var main: [WorkoutSet] = []
        var fslPercentage: Double = 0.65

        switch week {
        case 1: // 5s week
            fslPercentage = 0.65
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.65, roundTo: round), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.75, roundTo: round), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.85, roundTo: round), reps: "5+", type: .main)
            ]
        case 2: // 3s week
            fslPercentage = 0.70
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.70, roundTo: round), reps: "3", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.80, roundTo: round), reps: "3", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.90, roundTo: round), reps: "3+", type: .main)
            ]
        case 3: // 5/3/1 week
            fslPercentage = 0.75
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.75, roundTo: round), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.85, roundTo: round), reps: "3", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.95, roundTo: round), reps: "1+", type: .main)
            ]
        case 4: // Deload week
            fslPercentage = 0.40
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.40, roundTo: round), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.50, roundTo: round), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.60, roundTo: round), reps: "5", type: .main)
            ]
        default:
            fslPercentage = 0.65
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.65, roundTo: round), reps: "5", type: .main)
            ]
        }

        let fslWeight: Double = calculatedWeight(tm * fslPercentage, roundTo: round)
        var sslWeight: Double = 0
        
        // Calculate SSL weight (from main set 2)
        switch week {
        case 1: sslWeight = calculatedWeight(tm * 0.75, roundTo: round)
        case 2: sslWeight = calculatedWeight(tm * 0.80, roundTo: round)
        case 3: sslWeight = calculatedWeight(tm * 0.85, roundTo: round)
        default: sslWeight = fslWeight
        }

        var supplemental: [WorkoutSet] = []
        if week != 4 { // typically no supplemental on deload
            switch profile.selectedTemplate {
            case .fsl:
                for _ in 0..<5 {
                    supplemental.append(WorkoutSet(weight: fslWeight, reps: "5", type: .supplemental))
                }
            case .bbb:
                for _ in 0..<5 {
                    supplemental.append(WorkoutSet(weight: calculatedWeight(tm * 0.50, roundTo: round), reps: "10", type: .supplemental))
                }
            case .ssl:
                for _ in 0..<5 {
                    supplemental.append(WorkoutSet(weight: sslWeight, reps: "5", type: .supplemental))
                }
            case .bbs:
                for _ in 0..<10 {
                    supplemental.append(WorkoutSet(weight: fslWeight, reps: "5", type: .supplemental))
                }
            case .widowmaker:
                supplemental.append(WorkoutSet(weight: fslWeight, reps: "20", type: .supplemental))
            }
        }

        var accessorySets: [WorkoutSet] = []
        for accessory in accessories where accessory.relatedLift == lift {
            for _ in 0..<accessory.targetSets {
                accessorySets.append(WorkoutSet(weight: accessory.weight, reps: "\(accessory.targetReps) (\(accessory.name))", type: .accessory))
            }
        }

        return (warmup, main, supplemental, accessorySets)
    }

    // Round to nearest increment (5 lbs or 2.5 kg)
    static func calculatedWeight(_ exactWeight: Double, roundTo: Double = 5.0) -> Double {
        return Swift.round(exactWeight / roundTo) * roundTo
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

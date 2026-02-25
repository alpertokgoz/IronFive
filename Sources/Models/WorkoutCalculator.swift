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

    static func get1RM(for lift: MainLift, from profile: UserProfile) -> Double {
        switch lift {
        case .squat: return profile.squat1RM
        case .bench: return profile.bench1RM
        case .deadlift: return profile.deadlift1RM
        case .ohp: return profile.ohp1RM
        }
    }

    static func generateWorkout(for lift: MainLift, profile: UserProfile, accessories: [AccessoryExercise]) -> (warmup: [WorkoutSet], main: [WorkoutSet], supplemental: [WorkoutSet], accessorySets: [WorkoutSet]) {
        let oneRepMax = get1RM(for: lift, from: profile)
        let tm = oneRepMax * profile.trainingMaxPercentage
        let week = profile.currentWeek

        let warmup = [
            WorkoutSet(weight: calculatedWeight(tm * 0.40), reps: "5", type: .warmup),
            WorkoutSet(weight: calculatedWeight(tm * 0.50), reps: "5", type: .warmup),
            WorkoutSet(weight: calculatedWeight(tm * 0.60), reps: "3", type: .warmup)
        ]

        var main: [WorkoutSet] = []
        var fslPercentage: Double = 0.65

        switch week {
        case 1: // 5s week
            fslPercentage = 0.65
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.65), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.75), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.85), reps: "5+", type: .main)
            ]
        case 2: // 3s week
            fslPercentage = 0.70
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.70), reps: "3", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.80), reps: "3", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.90), reps: "3+", type: .main)
            ]
        case 3: // 5/3/1 week
            fslPercentage = 0.75
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.75), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.85), reps: "3", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.95), reps: "1+", type: .main)
            ]
        case 4: // Deload week
            fslPercentage = 0.40
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.40), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.50), reps: "5", type: .main),
                WorkoutSet(weight: calculatedWeight(tm * 0.60), reps: "5", type: .main)
            ]
        default:
            fslPercentage = 0.65
            main = [
                WorkoutSet(weight: calculatedWeight(tm * 0.65), reps: "5", type: .main)
            ]
        }

        let fslWeight: Double = calculatedWeight(tm * fslPercentage)
        var sslWeight: Double = 0
        
        // Calculate SSL weight (from main set 2)
        switch week {
        case 1: sslWeight = calculatedWeight(tm * 0.75)
        case 2: sslWeight = calculatedWeight(tm * 0.80)
        case 3: sslWeight = calculatedWeight(tm * 0.85)
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
                    supplemental.append(WorkoutSet(weight: calculatedWeight(tm * 0.50), reps: "10", type: .supplemental))
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
                // Since accessories usually don't have predefined weights in this MVP, we use weight=0 or a placeholder.
                // We could repurpose weight for display or ignore it.
                accessorySets.append(WorkoutSet(weight: 0, reps: "\(accessory.targetReps) (\(accessory.name))", type: .accessory))
            }
        }

        return (warmup, main, supplemental, accessorySets)
    }

    // Round to nearest 5 (standard plate math)
    static func calculatedWeight(_ exactWeight: Double) -> Double {
        return round(exactWeight / 5.0) * 5.0
    }
}

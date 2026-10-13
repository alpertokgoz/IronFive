import XCTest
@testable import WorkoutFlow

final class WorkoutProgressTests: XCTestCase {
    private var step: WorkoutStep {
        WorkoutStep(
            title: "Main", liftIcon: nil,
            workoutSet: WorkoutSet(weight: 100, reps: "5+", type: .main,
                                   exerciseName: "Squat", actualReps: 8, isCompleted: true),
            totalSetsInPhase: 3, setNumberInPhase: 3, isAMRAP: true, percentage: 85
        )
    }

    func testLegacyWorkoutRemainsReadable() throws {
        let original = step
        let legacyData = try JSONEncoder().encode([original])
        let progress = try WorkoutProgress.decode(legacyData)
        XCTAssertEqual(progress.steps.first?.id, original.id)
        XCTAssertEqual(progress.steps.first?.workoutSet.actualReps, 8)
        XCTAssertEqual(progress.steps.first?.workoutSet.isCompleted, true)
        XCTAssertFalse(progress.restCountdown.isActive)
    }

    func testProgressRoundTripPreservesSetsAndRest() throws {
        var rest = RestCountdown()
        let now = Date(timeIntervalSince1970: 1_000)
        rest.start(seconds: 180, stepIndex: 0, now: now)
        let progress = WorkoutProgress(steps: [step], restCountdown: rest)
        let data = try JSONEncoder().encode(progress)
        let restored = try WorkoutProgress.decode(data)
        XCTAssertEqual(restored.steps.first?.workoutSet.weight, 100)
        XCTAssertEqual(restored.steps.first?.workoutSet.actualReps, 8)
        XCTAssertEqual(restored.restCountdown.remaining(at: now.addingTimeInterval(45)), 135)
    }

    func testCorruptProgressFailsInsteadOfDiscardingSets() {
        XCTAssertThrowsError(try WorkoutProgress.decode(Data("invalid".utf8)))
    }

    func testRestoredPageIsClampedAndAllowsSummaryPage() {
        let progress = WorkoutProgress(steps: [step])
        XCTAssertEqual(progress.restoredIndex(-1), 0)
        XCTAssertEqual(progress.restoredIndex(100), 1)
        XCTAssertEqual(progress.restoredIndex(1), 1)
    }
    func testPartialAndEmptyWorkoutsCannotAdvanceTraining() {
        XCTAssertFalse(WorkoutProgress(steps: []).isComplete)
        var incomplete = step
        incomplete.workoutSet.isCompleted = false
        XCTAssertFalse(WorkoutProgress(steps: [step, incomplete]).isComplete)
    }

    func testAllLoggedSetsCompleteWorkout() {
        XCTAssertTrue(WorkoutProgress(steps: [step]).isComplete)
    }

}

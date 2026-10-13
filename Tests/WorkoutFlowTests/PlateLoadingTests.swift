import XCTest
@testable import WorkoutFlow

final class PlateLoadingTests: XCTestCase {
    func testPoundsLoadsEachSideOfStandardBar() {
        let plates = PlateLoading.platesNeeded(for: 225, unit: .lbs)
        XCTAssertEqual(plates.count, 1)
        XCTAssertEqual(plates.first?.weight, 45)
        XCTAssertEqual(plates.first?.count, 2)
    }

    func testKilogramsIncludesFractionalPlates() {
        let plates = PlateLoading.platesNeeded(for: 122.5, unit: .kg)
        XCTAssertEqual(plates.map { $0.weight }, [25, 1.25])
        XCTAssertEqual(plates.map { $0.count }, [2, 1])
        let reconstructed = 20 + 2 * plates.reduce(0) { $0 + $1.weight * Double($1.count) }
        XCTAssertEqual(reconstructed, 122.5)
    }

    func testBarOnlyAndInvalidWeightsHaveNoPlates() {
        XCTAssertTrue(PlateLoading.platesNeeded(for: 20, unit: .kg).isEmpty)
        XCTAssertTrue(PlateLoading.platesNeeded(for: 0, unit: .lbs).isEmpty)
        XCTAssertTrue(PlateLoading.platesNeeded(for: .nan, unit: .kg).isEmpty)
    }

    func testZeroRepAmrapDoesNotInventVolume() {
        let set = WorkoutSet(weight: 100, reps: "5+", type: .main, exerciseName: "Squat", actualReps: 0, isCompleted: true)
        XCTAssertEqual(set.completedReps, 0)
    }
}

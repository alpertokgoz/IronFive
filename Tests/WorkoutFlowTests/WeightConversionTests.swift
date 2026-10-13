import XCTest
@testable import WorkoutFlow

final class WeightConversionTests: XCTestCase {
    func testKnownPoundsToKilogramsConversion() {
        XCTAssertEqual(WeightConversion.convert(225, fromKilograms: false, toKilograms: true), 102.05828325, accuracy: 0.00001)
    }

    func testRoundTripPreservesRecordedHistoryWeight() {
        let kilograms = WeightConversion.convert(225, fromKilograms: false, toKilograms: true)
        let restored = WeightConversion.convert(kilograms, fromKilograms: true, toKilograms: false)
        XCTAssertEqual(restored, 225, accuracy: 0.00001)
    }

    func testBodyweightAndUnchangedUnitsStayUnchanged() {
        XCTAssertEqual(WeightConversion.convert(0, fromKilograms: false, toKilograms: true), 0)
        XCTAssertEqual(WeightConversion.convert(120, fromKilograms: true, toKilograms: true), 120)
    }
}

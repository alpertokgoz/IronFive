import XCTest
@testable import WorkoutFlow

final class RestCountdownTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)

    func testCountdownUsesElapsedWallClockTime() {
        var countdown = RestCountdown()
        countdown.start(seconds: 60, stepIndex: 2, now: now)
        XCTAssertEqual(countdown.remaining(at: now.addingTimeInterval(0.5)), 60)
        XCTAssertEqual(countdown.remaining(at: now.addingTimeInterval(35)), 25)
        XCTAssertEqual(countdown.remaining(at: now.addingTimeInterval(90)), 0)
    }

    func testSkipConsumesCompletionOnlyOnce() {
        var countdown = RestCountdown()
        countdown.start(seconds: 60, stepIndex: 2, now: now)
        XCTAssertEqual(countdown.finish(), 2)
        XCTAssertNil(countdown.finish())
        XCTAssertFalse(countdown.isActive)
        XCTAssertEqual(countdown.remaining(at: now.addingTimeInterval(60)), 0)
    }

    func testExpiredRestKeepsItsOriginatingSetUntilConsumed() {
        var countdown = RestCountdown()
        countdown.start(seconds: 60, stepIndex: 3, now: now)
        XCTAssertEqual(countdown.remaining(at: now.addingTimeInterval(61)), 0)
        XCTAssertEqual(countdown.finish(), 3)
        XCTAssertNil(countdown.finish())
    }

    func testAdjustmentUsesCurrentDeadlineAndClampsToFiveSeconds() {
        var countdown = RestCountdown()
        countdown.start(seconds: 60, stepIndex: 2, now: now)
        countdown.adjust(by: 30, now: now.addingTimeInterval(20))
        XCTAssertEqual(countdown.remaining(at: now.addingTimeInterval(20)), 70)
        countdown.adjust(by: -100, now: now.addingTimeInterval(20))
        XCTAssertEqual(countdown.remaining(at: now.addingTimeInterval(20)), 5)
    }

    func testAdjustingSkippedRestCannotRestartIt() {
        var countdown = RestCountdown()
        countdown.start(seconds: 60, stepIndex: 2, now: now)
        _ = countdown.finish()
        countdown.adjust(by: 30, now: now)
        XCTAssertFalse(countdown.isActive)
    }

    func testPersistencePreservesDeadlineAcrossRestart() throws {
        var countdown = RestCountdown()
        countdown.start(seconds: 180, stepIndex: 4, now: now)
        let data = try JSONEncoder().encode(countdown)
        let restored = try JSONDecoder().decode(RestCountdown.self, from: data)
        XCTAssertEqual(restored.remaining(at: now.addingTimeInterval(100)), 80)
        XCTAssertEqual(restored.stepIndex, 4)
    }
}

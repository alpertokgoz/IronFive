import Foundation

struct RestCountdown: Codable, Equatable {
    private(set) var deadline: Date?
    private(set) var stepIndex: Int?

    var isActive: Bool { deadline != nil && stepIndex != nil }

    mutating func start(seconds: Int, stepIndex: Int, now: Date = Date()) {
        self.deadline = now.addingTimeInterval(TimeInterval(seconds))
        self.stepIndex = stepIndex
    }

    func remaining(at now: Date = Date()) -> Int {
        guard let deadline = deadline else { return 0 }
        return max(0, Int(ceil(deadline.timeIntervalSince(now))))
    }

    mutating func adjust(by seconds: Int, now: Date = Date()) {
        guard isActive else { return }
        deadline = now.addingTimeInterval(TimeInterval(max(5, remaining(at: now) + seconds)))
    }

    mutating func finish() -> Int? {
        guard isActive else { return nil }
        let completedIndex = stepIndex
        deadline = nil
        stepIndex = nil
        return completedIndex
    }
}

import Foundation

enum PlateLoading {
    static func platesNeeded(for targetWeight: Double, unit: WeightUnit) -> [(weight: Double, count: Int)] {
        guard targetWeight.isFinite, targetWeight > unit.barWeight else { return [] }
        var remaining = (targetWeight - unit.barWeight) / 2.0
        let availablePlates: [Double] = unit == .lbs
            ? [45.0, 25.0, 10.0, 5.0, 2.5]
            : [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25]
        var result: [(Double, Int)] = []

        for plate in availablePlates {
            let count = Int(remaining / plate)
            if count > 0 {
                result.append((plate, count))
                remaining -= Double(count) * plate
            }
        }
        return result
    }
}

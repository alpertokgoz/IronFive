import Foundation

enum WeightConversion {
    static func convert(_ value: Double, fromKilograms: Bool, toKilograms: Bool) -> Double {
        guard fromKilograms != toKilograms else { return value }
        return toKilograms ? value * 0.45359237 : value / 0.45359237
    }
}

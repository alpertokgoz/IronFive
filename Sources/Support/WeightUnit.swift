import Foundation

enum WeightUnit: Int, Codable, CaseIterable {
    case lbs = 0
    case kg = 1

    var label: String {
        switch self {
        case .lbs: return "lbs"
        case .kg: return "kg"
        }
    }

    var barWeight: Double {
        switch self {
        case .lbs: return 45.0
        case .kg: return 20.0
        }
    }

    var roundTo: Double {
        switch self {
        case .lbs: return 5.0
        case .kg: return 2.5
        }
    }

    var upperIncrement: Double {
        switch self {
        case .lbs: return 5.0
        case .kg: return 2.5
        }
    }

    var lowerIncrement: Double {
        switch self {
        case .lbs: return 10.0
        case .kg: return 5.0
        }
    }
}

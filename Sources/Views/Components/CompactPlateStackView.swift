import SwiftUI

struct CompactPlateStackView: View {
    let targetWeight: Double
    let unit: WeightUnit

    var body: some View {
        let plates = WorkoutCalculator.platesNeeded(for: targetWeight, unit: unit)
        if plates.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 2) {
                ForEach(plates, id: \.weight) { plate in
                    ForEach(0..<plate.count, id: \.self) { _ in
                        Circle()
                            .fill(plateColor(plate.weight))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Text(plateLabel(plate.weight))
                                    .font(.system(size: 6, weight: .black, design: .rounded))
                                    .foregroundColor(textColorForPlate(plate.weight))
                            )
                    }
                }
            }
        }
    }

    private func plateLabel(_ weight: Double) -> String {
        if weight == 1.25 { return "1.2" }
        return "\(Int(weight))"
    }

    private func textColorForPlate(_ weight: Double) -> Color {
        // white plates need black text for high contrast on watchOS
        if weight == 10 && unit == .lbs { return .black }
        if weight == 5 && unit == .kg { return .black }
        return .white
    }

    private func plateColor(_ weight: Double) -> Color {
        unit == .kg ? kgPlateColor(weight) : lbsPlateColor(weight)
    }

    private func kgPlateColor(_ weight: Double) -> Color {
        switch weight {
        case 25: return .red
        case 20: return .blue
        case 15: return .yellow
        case 10: return .green
        case 5: return .white
        case 2.5: return .orange
        case 1.25: return .gray
        default: return .gray
        }
    }

    private func lbsPlateColor(_ weight: Double) -> Color {
        switch weight {
        case 45: return .blue
        case 25: return .yellow
        case 10: return .white
        case 5: return .red
        case 2.5: return .green
        default: return .gray
        }
    }
}

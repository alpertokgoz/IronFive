import SwiftUI

struct CompactPlateStackView: View {
    let targetWeight: Double
    let unit: WeightUnit

    private var plates: [(weight: Double, count: Int)] {
        WorkoutCalculator.platesNeeded(for: targetWeight, unit: unit)
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(plates, id: \.weight) { plate in
                Text("\(IronTheme.weight(plate.weight))\(plate.count > 1 ? "×\(plate.count)" : "")")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(PlateColor.color(plate.weight, unit: unit).opacity(0.18), in: Capsule())
                    .overlay { Capsule().strokeBorder(PlateColor.color(plate.weight, unit: unit).opacity(0.6), lineWidth: 1) }
            }
        }
        .frame(height: 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(plates.isEmpty ? "No plates" : "Each side: " + plates.map { "\($0.count) plates of \(IronTheme.weight($0.weight)) \(unit.label)" }.joined(separator: ", "))
    }
}

enum PlateColor {
    private static let kilograms: [Double: Color] = [
        25: .red, 20: .blue, 15: .yellow, 10: .green, 5: .white, 2.5: .orange
    ]
    private static let pounds: [Double: Color] = [
        45: .blue, 25: .yellow, 10: .white, 5: .red, 2.5: .green
    ]

    static func color(_ weight: Double, unit: WeightUnit) -> Color {
        (unit == .kg ? kilograms : pounds)[weight] ?? .gray
    }
}

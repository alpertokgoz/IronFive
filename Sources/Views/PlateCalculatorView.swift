import SwiftUI

struct PlateCalculatorView: View {
    let targetWeight: Double
    var unit: WeightUnit = .lbs
    private var plates: [(weight: Double, count: Int)] {
        WorkoutCalculator.platesNeeded(for: targetWeight, unit: unit)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(IronTheme.weight(targetWeight)) \(unit.label)")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(IronTheme.ember)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Text("\(IronTheme.weight(unit.barWeight)) \(unit.label) bar · plates on each side")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                if targetWeight < unit.barWeight {
                    Text("Use a lighter bar for this target.")
                        .font(.system(size: 13))
                } else if plates.isEmpty {
                    Label("Bar only", systemImage: "checkmark.circle")
                        .foregroundStyle(IronTheme.mint)
                } else {
                    VStack(spacing: 3) {
                        ForEach(plates, id: \.weight) { plate in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(PlateColor.color(plate.weight, unit: unit))
                                    .frame(width: 5, height: 20)
                                Text("\(IronTheme.weight(plate.weight)) \(unit.label)")
                                Spacer(minLength: 0)
                                Text("×\(plate.count)").fontWeight(.semibold)
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(IronTheme.surface, in: RoundedRectangle(cornerRadius: 10))
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle("Load the bar")
        .navigationBarTitleDisplayMode(.inline)
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
    }
}

import SwiftUI
import SwiftData

struct PlateCalculatorView: View {
    let targetWeight: Double
    var unit: WeightUnit = .lbs
    @Environment(\.dismiss) var dismiss

    var platesNeeded: [(weight: Double, count: Int)] {
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

    var body: some View {
        VStack(spacing: 12) {
            Text("Plate Math")
                .font(.headline)
                .padding(.top)

            VStack(spacing: 2) {
                Text("\(String(format: "%.1f", targetWeight)) \(unit.label)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.tint)
                Text("(per side, \(String(format: "%.0f", unit.barWeight))\(unit.label) bar)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }

            if targetWeight <= unit.barWeight {
                Text("Bar only")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(platesNeeded, id: \.weight) { plate in
                            HStack(spacing: 8) {
                                Circle()
                                    .stroke(plateColor(plate.weight), lineWidth: 3)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Text(plate.weight == 1.25 ? "1.2" : "\(Int(plate.weight))")
                                            .font(.system(size: 6, weight: .black))
                                    )

                                Text("\(String(format: "%.1f", plate.weight)) \(unit.label)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(plate.count)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(plateColor(plate.weight))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                        }
                    }
                }
            }

            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .padding(.bottom)
        }
        .padding()
        .containerBackground(.black.gradient, for: .navigation)
    }

    private func plateColor(_ weight: Double) -> Color {
        if unit == .kg {
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
        } else {
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
}

#Preview {
    PlateCalculatorView(targetWeight: 225, unit: .lbs)
}

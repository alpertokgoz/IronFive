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

            VStack(spacing: 4) {
                Text("\(String(format: "%.1f", targetWeight)) \(unit.label)")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundStyle(.tint)
                Text("(per side, \(String(format: "%.0f", unit.barWeight))\(unit.label) bar)")
                    .font(.caption2)
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
                    VStack(spacing: 8) {
                        ForEach(platesNeeded, id: \.weight) { plate in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(plateColor(plate.weight).opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Circle()
                                        .stroke(plateColor(plate.weight), lineWidth: 4)
                                        .frame(width: 28, height: 28)
                                }
                                
                                Text("\(String(format: "%.1f", plate.weight)) \(unit.label)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                HStack(spacing: 2) {
                                    Text("×")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(plate.count)")
                                        .font(.system(.title2, design: .rounded, weight: .black))
                                        .foregroundColor(plateColor(plate.weight))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(16)
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

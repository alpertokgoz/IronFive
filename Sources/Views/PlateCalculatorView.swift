import SwiftUI

struct PlateCalculatorView: View {
    let targetWeight: Double
    @Environment(\.dismiss) var dismiss

    var platesNeeded: [(weight: Double, count: Int)] {
        let barWeight = 45.0
        var remaining = (targetWeight - barWeight) / 2.0
        let availablePlates = [45.0, 25.0, 10.0, 5.0, 2.5]
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
                Text("\(String(format: "%.1f", targetWeight)) lbs")
                    .font(.title)
                    .fontWeight(.black)
                    .foregroundStyle(.tint)
                Text("(per side, 45lb bar)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if targetWeight <= 45 {
                Text("Bar only")
                    .font(.body)
                    .italic()
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(platesNeeded, id: \.weight) { plate in
                            HStack {
                                Circle()
                                    .fill(plateColor(plate.weight))
                                    .frame(width: 12, height: 12)
                                Text("\(String(format: "%.1f", plate.weight)) lb")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("x\(plate.count)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
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

#Preview {
    PlateCalculatorView(targetWeight: 225)
}

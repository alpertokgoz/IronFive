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
                                
                                Text("\(String(format: "%.1f", plate.weight)) lb")
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

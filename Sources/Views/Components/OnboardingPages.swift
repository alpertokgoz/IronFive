import SwiftUI

struct OnboardingMaxesPage: View {
    let unit: WeightUnit
    @Binding var squat: Double
    @Binding var bench: Double
    @Binding var deadlift: Double
    @Binding var overhead: Double
    let onNext: () -> Void
    @State private var editingLift: MainLift?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                OnboardingStepDots(total: 4, current: 1)
                Text("Your one-rep maxes")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                Text("Estimates are fine. Tap a lift to edit.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                ForEach(MainLift.allCases, id: \.self) { lift in
                    Button { editingLift = lift } label: {
                        HStack {
                            Text(lift.name).font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 3)
                            Text("\(IronTheme.weight(binding(lift).wrappedValue)) \(unit.label)")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(lift.color)
                                .lineLimit(1).minimumScaleFactor(0.7)
                            Image(systemName: "pencil").font(.system(size: 10))
                        }
                        .padding(9)
                        .modifier(IronCard(accent: lift.color))
                    }
                    .buttonStyle(.plain)
                }
                Button("Next", action: onNext).buttonStyle(IronButtonStyle(accent: IronTheme.ember))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .sheet(item: $editingLift) { lift in
            SetWeightEditor(weight: binding(lift), unit: unit, accent: lift.color, isBarbell: false,
                            title: "\(lift.shortName) one-rep max", saveTitle: "Save max")
        }
    }

    private func binding(_ lift: MainLift) -> Binding<Double> {
        switch lift {
        case .squat: return $squat
        case .bench: return $bench
        case .deadlift: return $deadlift
        case .ohp: return $overhead
        }
    }
}

struct OnboardingTrainingMaxPage: View {
    let unit: WeightUnit
    @Binding var percentage: Double
    let maxes: [Double]
    let onNext: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.height < 200
            VStack(spacing: compact ? 4 : 7) {
                OnboardingStepDots(total: 4, current: 2)
                HStack {
                    Text("Training max")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Spacer(minLength: 3)
                    Text("\(Int(percentage))%")
                        .font(.system(size: 23, weight: .semibold, design: .rounded))
                        .foregroundStyle(IronTheme.ember)
                        .fixedSize()
                }
                HStack(spacing: 4) {
                    ForEach([80.0, 85, 90, 95], id: \.self) { option in
                        Button { percentage = option } label: {
                            Text("\(Int(option))")
                                .font(.system(size: 13, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 30)
                                .foregroundStyle(percentage == option ? .black : .white)
                                .background(percentage == option ? IronTheme.ember : IronTheme.surface, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(Int(option)) percent")
                        .accessibilityAddTraits(percentage == option ? .isSelected : [])
                    }
                }
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(Array(MainLift.allCases.enumerated()), id: \.element) { index, lift in
                        HStack(spacing: 3) {
                            Text(lift.shortName).foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                            Text(IronTheme.weight(WorkoutCalculator.calculatedWeight(maxes[index] * percentage / 100, roundTo: unit.roundTo)))
                                .foregroundStyle(lift.color)
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .padding(5)
                        .background(IronTheme.surface, in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("\(lift.name) training max")
                    }
                }
                Text("Calculated weights in \(unit.label)")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Button("Next", action: onNext).buttonStyle(IronButtonStyle(accent: IronTheme.ember))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct OnboardingTemplatePage: View {
    @Binding var selection: SupplementalTemplate
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 5) {
            OnboardingStepDots(total: 4, current: 3)
            Text("Choose your template")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                        Button { selection = template } label: {
                            HStack(spacing: 6) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(template.shortName).font(.system(size: 15, weight: .semibold))
                                    Text(template.descriptionText).font(.system(size: 11)).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                if selection == template {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(IronTheme.mint)
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .modifier(IronCard(accent: selection == template ? IronTheme.mint : .white))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selection == template ? .isSelected : [])
                    }
                }
            }
            Text("Scroll for all 5 templates")
                .font(.system(size: 10)).foregroundStyle(.secondary)
            Button("Save program", action: onSave).buttonStyle(IronButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

extension SupplementalTemplate {
    var descriptionText: String {
        switch self {
        case .fsl: return "5 × 5 · first set weight"
        case .bbb: return "5 × 10 · 50% training max"
        case .ssl: return "5 × 5 · second set weight"
        case .bbs: return "10 × 5 · first set weight"
        case .widowmaker: return "1 × 20 · first set weight"
        }
    }
}

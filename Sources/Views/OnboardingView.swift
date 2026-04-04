import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State private var selectedUnit: WeightUnit = .lbs
    @State private var squat1RM: Double = 200
    @State private var bench1RM: Double = 150
    @State private var deadlift1RM: Double = 250
    @State private var ohp1RM: Double = 100
    @State private var tmPercentage: Double = 90
    @State private var currentStep = 0
    @State private var selectedTemplate: SupplementalTemplate = .fsl

    var body: some View {
        TabView(selection: $currentStep) {

            // Step 1: Welcome + Unit Selection
            VStack(spacing: 14) {
                OnboardingStepDots(total: 4, current: 0)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 36))
                    .foregroundStyle(.orange.gradient)

                Text("IronFive")
                    .font(.system(.title2, design: .rounded, weight: .black))

                Picker("Unit", selection: $selectedUnit) {
                    Text("lbs").tag(WeightUnit.lbs)
                    Text("kg").tag(WeightUnit.kg)
                }
                .pickerStyle(.navigationLink)
                .padding(.horizontal, 16)

                Button(action: { withAnimation { currentStep = 1 } }) {
                    Text("Next")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding()
            .tag(0)

            // Step 2: Enter 1RMs
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    OnboardingStepDots(total: 4, current: 1)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Your 1 Rep Maxes")
                        .font(.system(.headline, design: .rounded, weight: .black))

                    OnboardingLiftRow(lift: .squat, value: $squat1RM, unit: selectedUnit)
                    OnboardingLiftRow(lift: .bench, value: $bench1RM, unit: selectedUnit)
                    OnboardingLiftRow(lift: .deadlift, value: $deadlift1RM, unit: selectedUnit)
                    OnboardingLiftRow(lift: .ohp, value: $ohp1RM, unit: selectedUnit)

                    Button(action: { withAnimation { currentStep = 2 } }) {
                        Text("Next")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .padding(.top, 4)
                }
                .padding()
            }
            .tag(1)

            // Step 3: TM%
            VStack(alignment: .leading, spacing: 12) {
                OnboardingStepDots(total: 4, current: 2)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Training Max %")
                    .font(.system(.headline, design: .rounded, weight: .black))

                HStack {
                    Text("\(Int(tmPercentage))%")
                        .font(.system(.title2, design: .rounded, weight: .black))
                        .foregroundColor(.orange)
                        .frame(width: 60)

                    Slider(value: $tmPercentage, in: 80...95, step: 5)
                        .tint(.orange)
                }

                VStack(spacing: 4) {
                    tmResultRow(.squat, value: squat1RM * tmPercentage / 100)
                    tmResultRow(.bench, value: bench1RM * tmPercentage / 100)
                    tmResultRow(.deadlift, value: deadlift1RM * tmPercentage / 100)
                    tmResultRow(.ohp, value: ohp1RM * tmPercentage / 100)
                }
                .padding(.vertical, 4)

                Button(action: { withAnimation { currentStep = 3 } }) {
                    Text("Next")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding()
            .tag(2)

            // Step 4: Template Selection
            VStack(alignment: .leading, spacing: 10) {
                OnboardingStepDots(total: 4, current: 3)
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Select Template")
                    .font(.system(.headline, design: .rounded, weight: .black))

                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                            Button(action: { selectedTemplate = template }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(template.name)
                                            .font(.system(.caption, design: .rounded, weight: .bold))
                                        Text(templateDescription(template))
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if selectedTemplate == template {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding(8)
                                .background(Color.white.opacity(selectedTemplate == template ? 0.12 : 0.07))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTemplate == template ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button(action: saveAndDismiss) {
                    Text("START TRAINING")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
            .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .containerBackground(Color.black.gradient, for: .navigation)
    }

    private func templateDescription(_ template: SupplementalTemplate) -> String {
        switch template {
        case .fsl: return "5x5 at the first set's weight."
        case .bbb: return "5x10 at 50%. High volume."
        case .ssl: return "5x5 at the second set's weight."
        case .bbs: return "10x5 at the first set's weight."
        case .widowmaker: return "1x20 at the first set's weight."
        }
    }

    private func tmResultRow(_ lift: MainLift, value: Double) -> some View {
        let rounded = (value / selectedUnit.roundTo).rounded() * selectedUnit.roundTo
        return HStack {
            Image(systemName: lift.symbolName)
                .font(.system(size: 10))
                .foregroundColor(lift.color)
            Text(lift.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Spacer()
            Text("\(Int(rounded)) \(selectedUnit.label)")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundColor(lift.color)
        }
    }

    private func saveAndDismiss() {
        let pct = tmPercentage / 100.0
        let r = selectedUnit.roundTo
        let profile = UserProfile(
            squatTM: (squat1RM * pct / r).rounded() * r,
            benchTM: (bench1RM * pct / r).rounded() * r,
            deadliftTM: (deadlift1RM * pct / r).rounded() * r,
            ohpTM: (ohp1RM * pct / r).rounded() * r,
            selectedTemplate: selectedTemplate,
            weightUnit: selectedUnit
        )
        modelContext.insert(profile)

        // Add default accessories for the selected template
        for lift in MainLift.allCases {
            let defaults = selectedTemplate.defaultAccessories(for: lift)
            for acc in defaults {
                modelContext.insert(acc)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

struct OnboardingLiftRow: View {
    let lift: MainLift
    @Binding var value: Double
    let unit: WeightUnit

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: lift.symbolName)
                .font(.system(size: 12))
                .foregroundColor(lift.color)
            Text(lift.name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
            Spacer()
            Text("\(Int(value))")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(isFocused ? .black : lift.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isFocused ? lift.color : Color.white.opacity(0.1))
                .clipShape(Capsule())
                .focusable()
                .focused($isFocused)
                .digitalCrownRotation($value, from: 0, through: 600, by: unit.roundTo, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        }
    }
}

struct OnboardingStepDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? Color.orange : Color.white.opacity(0.15))
                    .frame(width: index == current ? 12 : 6, height: 4)
                    .animation(.spring(), value: current)
            }
        }
    }
}

#Preview {
    OnboardingView()
}

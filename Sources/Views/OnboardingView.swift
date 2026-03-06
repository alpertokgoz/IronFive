import SwiftUI

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

    var body: some View {
        TabView(selection: $currentStep) {

            // Step 1: Welcome + Unit Selection
            VStack(spacing: 16) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange.gradient)

                Text("IronFive")
                    .font(.system(.title2, design: .rounded, weight: .black))

                Text("Your 5/3/1 companion.\nNo phone needed.")
                    .font(.system(.caption, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                // Unit selector
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
                    Text("Your 1 Rep Maxes")
                        .font(.system(.headline, design: .rounded, weight: .black))

                    Text("Enter your tested or estimated 1RM for each lift. We'll calculate your Training Max.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    OnboardingLiftRow(label: "Squat", value: $squat1RM, color: .orange, unit: selectedUnit)
                    OnboardingLiftRow(label: "Bench", value: $bench1RM, color: .blue, unit: selectedUnit)
                    OnboardingLiftRow(label: "Deadlift", value: $deadlift1RM, color: .green, unit: selectedUnit)
                    OnboardingLiftRow(label: "OHP", value: $ohp1RM, color: .purple, unit: selectedUnit)

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

            // Step 3: TM% and Confirmation
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Training Max %")
                        .font(.system(.headline, design: .rounded, weight: .black))

                    Text("Wendler recommends 85-90% of your 1RM. Start conservative—you can always go up.")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack {
                        Text("\(Int(tmPercentage))%")
                            .font(.system(.title2, design: .rounded, weight: .black))
                            .foregroundColor(.orange)
                            .frame(width: 60)

                        Slider(value: $tmPercentage, in: 80...95, step: 5)
                            .tint(.orange)
                    }
                    .padding(.vertical, 4)

                    Divider().background(Color.secondary.opacity(0.3))

                    Text("YOUR TRAINING MAXES")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .kerning(1.2)

                    VStack(spacing: 6) {
                        tmResultRow("Squat", value: squat1RM * tmPercentage / 100, color: .orange)
                        tmResultRow("Bench", value: bench1RM * tmPercentage / 100, color: .blue)
                        tmResultRow("Deadlift", value: deadlift1RM * tmPercentage / 100, color: .green)
                        tmResultRow("OHP", value: ohp1RM * tmPercentage / 100, color: .purple)
                    }

                    Button(action: saveAndDismiss) {
                        Text("Start Training")
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 4)
                }
                .padding()
            }
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .containerBackground(Color.black.gradient, for: .navigation)
    }

    private func tmResultRow(_ name: String, value: Double, color: Color) -> some View {
        let rounded = (value / selectedUnit.roundTo).rounded() * selectedUnit.roundTo
        return HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(name)
                .font(.system(.caption, design: .rounded, weight: .bold))
            Spacer()
            Text("\(Int(rounded)) \(selectedUnit.label)")
                .font(.system(.body, design: .rounded, weight: .black))
                .foregroundColor(color)
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
            weightUnit: selectedUnit
        )
        modelContext.insert(profile)
        do {
            try modelContext.save()
        } catch {
            print("Failed to save profile: \(error.localizedDescription)")
        }
        dismiss()
    }
}

// Reusable row for entering a lift's 1RM via Digital Crown
struct OnboardingLiftRow: View {
    let label: String
    @Binding var value: Double
    let color: Color
    let unit: WeightUnit

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .bold))
            Spacer()
            Text("\(Int(value)) \(unit.label)")
                .font(.system(.body, design: .rounded, weight: .black))
                .foregroundColor(isFocused ? .black : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(isFocused ? color : Color.white.opacity(0.1))
                .clipShape(Capsule())
                .focusable()
                .focused($isFocused)
                .digitalCrownRotation($value, from: 0, through: 600, by: unit.roundTo, sensitivity: .medium, isContinuous: false, isHapticFeedbackEnabled: true)
        }
    }
}

#Preview {
    OnboardingView()
}

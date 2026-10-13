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
    @State private var age: Double = 30
    @State private var saveError: String?

    init(initialStep: Int = 0) {
        _currentStep = State(initialValue: initialStep)
    }

    var body: some View {
        TabView(selection: $currentStep) {

            // Step 1: Welcome + Unit Selection
            VStack(spacing: 8) {
                OnboardingStepDots(total: 4, current: 0)

                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange.gradient)

                Text("Build strength.")
                    .font(.system(.title3, design: .rounded, weight: .black))

                HStack(spacing: 6) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Button { selectedUnit = unit } label: {
                            Text(unit.label)
                                .frame(maxWidth: .infinity, minHeight: 32)
                                .background(selectedUnit == unit ? Color.orange : Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selectedUnit == unit ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 12)

                Text("5/3/1, right on your wrist.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)

                Button(action: { withAnimation { currentStep = 1 } }) {
                    Text("Next")
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(IronButtonStyle(accent: IronTheme.ember))
            }
            .padding()
            .tag(0)

            OnboardingMaxesPage(unit: selectedUnit, squat: $squat1RM, bench: $bench1RM,
                                 deadlift: $deadlift1RM, overhead: $ohp1RM) {
                withAnimation { currentStep = 2 }
            }
            .tag(1)

            OnboardingTrainingMaxPage(unit: selectedUnit, percentage: $tmPercentage,
                                      maxes: [squat1RM, bench1RM, deadlift1RM, ohp1RM]) {
                withAnimation { currentStep = 3 }
            }
            .tag(2)

            OnboardingTemplatePage(selection: $selectedTemplate, onSave: saveAndDismiss)
                .tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .onChange(of: selectedUnit) { old, new in
            squat1RM = converted(squat1RM, from: old, to: new)
            bench1RM = converted(bench1RM, from: old, to: new)
            deadlift1RM = converted(deadlift1RM, from: old, to: new)
            ohp1RM = converted(ohp1RM, from: old, to: new)
        }
        .alert("Check your program", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { Button("OK") { saveError = nil } } message: { Text(saveError ?? "") }
    }

    private func converted(_ value: Double, from old: WeightUnit, to new: WeightUnit) -> Double {
        WorkoutCalculator.calculatedWeight(
            WeightConversion.convert(value, fromKilograms: old == .kg, toKilograms: new == .kg),
            roundTo: new.roundTo
        )
    }

    private func saveAndDismiss() {
        guard [squat1RM, bench1RM, deadlift1RM, ohp1RM].allSatisfy({ $0 > 0 }) else {
            saveError = "Enter a positive one rep max for each lift. Estimates are fine."
            currentStep = 1
            return
        }
        let pct = tmPercentage / 100.0
        let r = selectedUnit.roundTo
        let profile = UserProfile(
            squatTM: (squat1RM * pct / r).rounded() * r,
            benchTM: (bench1RM * pct / r).rounded() * r,
            deadliftTM: (deadlift1RM * pct / r).rounded() * r,
            ohpTM: (ohp1RM * pct / r).rounded() * r,
            selectedTemplate: selectedTemplate,
            weightUnit: selectedUnit,
            age: Int(age)
        )
        modelContext.insert(profile)

        // Add default accessories for the selected template
        for lift in MainLift.allCases {
            let defaults = selectedTemplate.defaultAccessories(for: lift)
            for acc in defaults {
                modelContext.insert(acc)
            }
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            saveError = "Could not save your program. Please try again."
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

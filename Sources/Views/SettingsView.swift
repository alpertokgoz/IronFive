import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var squatTM: Double = 0
    @State private var benchTM: Double = 0
    @State private var deadliftTM: Double = 0
    @State private var ohpTM: Double = 0
    @State private var selectedTemplate: SupplementalTemplate = .fsl
    @State private var selectedUnit: WeightUnit = .lbs
    @State private var usesFourWeekCycle: Bool = false
    @State private var editingLift: MainLift?

    var body: some View {
        Form {
            Section(header: settingsHeader("Training Maxes")) {
                TMRow(lift: .squat, value: squatTM, unit: selectedUnit) {
                    editingLift = .squat
                }
                TMRow(lift: .bench, value: benchTM, unit: selectedUnit) {
                    editingLift = .bench
                }
                TMRow(lift: .deadlift, value: deadliftTM, unit: selectedUnit) {
                    editingLift = .deadlift
                }
                TMRow(lift: .ohp, value: ohpTM, unit: selectedUnit) {
                    editingLift = .ohp
                }
            }
            .listRowBackground(Color.white.opacity(0.05))

            Section(header: settingsHeader("Program")) {
                Picker("Unit", selection: $selectedUnit) {
                    Text("lbs").tag(WeightUnit.lbs)
                    Text("kg").tag(WeightUnit.kg)
                }

                Picker("Template", selection: $selectedTemplate) {
                    ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                        Text(template.name).tag(template)
                    }
                }

                Toggle("4-Week Cycle", isOn: $usesFourWeekCycle)

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text(usesFourWeekCycle ? "TMs progress after Week 4" : "TMs progress after Week 3")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(Color.white.opacity(0.05))

            Section {
                NavigationLink("Manage Accessories", destination: AccessorySettingsView())
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .navigationTitle("Settings")
        .containerBackground(Color.black.gradient, for: .navigation)
        .onAppear {
            loadProfile()
        }
        .onDisappear {
            saveProfile()
        }
        .sheet(item: $editingLift) { lift in
            TMEditorSheet(
                lift: lift,
                value: bindingForLift(lift),
                unit: selectedUnit
            )
        }
    }

    @ViewBuilder
    private func settingsHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .black, design: .rounded))
            .kerning(1.2)
    }

    private func bindingForLift(_ lift: MainLift) -> Binding<Double> {
        switch lift {
        case .squat: return $squatTM
        case .bench: return $benchTM
        case .deadlift: return $deadliftTM
        case .ohp: return $ohpTM
        }
    }

    private func loadProfile() {
        guard let profile = userProfiles.first else { return }
        squatTM = profile.squatTM
        benchTM = profile.benchTM
        deadliftTM = profile.deadliftTM
        ohpTM = profile.ohpTM
        selectedTemplate = profile.selectedTemplate
        selectedUnit = profile.weightUnit
        usesFourWeekCycle = profile.usesFourWeekCycle
    }

    private func saveProfile() {
        if let profile = userProfiles.first {
            profile.squatTM = squatTM
            profile.benchTM = benchTM
            profile.deadliftTM = deadliftTM
            profile.ohpTM = ohpTM
            profile.selectedTemplate = selectedTemplate
            profile.weightUnit = selectedUnit
            profile.usesFourWeekCycle = usesFourWeekCycle
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save settings: \(error.localizedDescription)")
        }
    }
}

// MARK: - TM Row (Tap-to-Edit)

struct TMRow: View {
    let lift: MainLift
    let value: Double
    let unit: WeightUnit
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: lift.symbolName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(lift.color)
                    .frame(width: 20)

                Text(lift.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text("\(String(format: "%.1f", value)) \(unit.label)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(lift.color)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - TM Editor Sheet (Digital Crown)

struct TMEditorSheet: View {
    let lift: MainLift
    @Binding var value: Double
    let unit: WeightUnit
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: lift.symbolName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(lift.color.gradient)

            Text(lift.name.uppercased())
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundColor(.secondary)

            Text("\(String(format: "%.1f", value))")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(lift.color)
                .focusable()
                .digitalCrownRotation(
                    $value,
                    from: 0,
                    through: 500,
                    by: unit.roundTo,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )

            Text(unit.label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(lift.color)
                .padding(.top, 4)
        }
        .containerBackground(Color.black.gradient, for: .navigation)
    }
}

extension MainLift: Identifiable {
    public var id: Int { rawValue }
}

#Preview {
    SettingsView()
}

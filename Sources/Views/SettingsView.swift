import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var sessions: [WorkoutSession]
    @Query private var accessories: [AccessoryExercise]
    @Query private var activeSessions: [ActiveWorkoutSession]

    @State private var squatTM: Double = 0
    @State private var benchTM: Double = 0
    @State private var deadliftTM: Double = 0
    @State private var ohpTM: Double = 0
    @State private var selectedTemplate: SupplementalTemplate = .fsl
    @State private var selectedUnit: WeightUnit = .lbs
    @State private var usesFourWeekCycle: Bool = false
    @State private var isAutopilotEnabled: Bool = false
    @State private var age: Double = 30
    @State private var editingAge = false
    @State private var editingLift: MainLift?
    var initialSection: String?
    @State private var loaded = false
    @State private var saveError: String?

    private var settingsValues: [Double] {
        [squatTM, benchTM, deadliftTM, ohpTM, age, Double(selectedTemplate.rawValue),
         usesFourWeekCycle ? 1 : 0, isAutopilotEnabled ? 1 : 0]
    }

    var body: some View {
        ScrollViewReader { proxy in
        Form {
            if !activeSessions.isEmpty {
                Text("Finish your active workout before changing weights or your program.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Section(header: settingsHeader("Training Maxes")) {
                TMRow(lift: .squat, value: squatTM, unit: selectedUnit) {
                    if activeSessions.isEmpty { editingLift = .squat }
                }
                TMRow(lift: .bench, value: benchTM, unit: selectedUnit) {
                    if activeSessions.isEmpty { editingLift = .bench }
                }
                TMRow(lift: .deadlift, value: deadliftTM, unit: selectedUnit) {
                    if activeSessions.isEmpty { editingLift = .deadlift }
                }
                TMRow(lift: .ohp, value: ohpTM, unit: selectedUnit) {
                    if activeSessions.isEmpty { editingLift = .ohp }
                }
            }
            .disabled(!activeSessions.isEmpty)
            .opacity(activeSessions.isEmpty ? 1 : 0.45)
            .listRowBackground(IronTheme.surface)

            Section(header: settingsHeader("Program")) {
                Picker("Unit", selection: $selectedUnit) {
                    Text("lbs").tag(WeightUnit.lbs)
                    Text("kg").tag(WeightUnit.kg)
                }
                .disabled(!activeSessions.isEmpty)
                .id("program")

                Picker("Template", selection: $selectedTemplate) {
                    ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                        Text(template.name).tag(template)
                    }
                }
                .disabled(!activeSessions.isEmpty)

                Toggle("Deload week", isOn: $usesFourWeekCycle)
                    .disabled(!activeSessions.isEmpty)

                Toggle("Autopilot", isOn: $isAutopilotEnabled).id("autopilot")
                Text("Rest starts after non-AMRAP sets. When it ends, the next set appears.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Button { editingAge = true } label: {
                    HStack {
                        Text("Age")
                        Spacer()
                        Text("\(Int(age))").foregroundStyle(IronTheme.ember)
                        Image(systemName: "chevron.right").font(.caption2)
                    }
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                }
                .buttonStyle(.plain)

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text(usesFourWeekCycle ? "TMs progress after Week 4" : "TMs progress after Week 3")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .listRowBackground(IronTheme.surface)

            Section {
                NavigationLink("Assistance exercises", destination: AccessorySettingsView()).id("assistance")
                    .disabled(!activeSessions.isEmpty)
            }
            .listRowBackground(IronTheme.surface)
        }
        .navigationTitle("Settings")
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .onAppear {
            if !loaded { loadProfile(); loaded = true }
            if let section = initialSection {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { proxy.scrollTo(section, anchor: .top) }
            }
        }
        .onChange(of: settingsValues) { _, _ in if loaded { saveProfile() } }
        .onChange(of: selectedUnit) { old, new in
            if loaded { convertSavedWeights(from: old, to: new) }
        }
        .alert("Could not save settings", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { Button("OK") { saveError = nil } } message: { Text(saveError ?? "") }
        .sheet(isPresented: $editingAge) {
            CountEditor(value: $age, title: "Age", range: 10...100, saveTitle: "Save age")
        }
        .sheet(item: $editingLift) { lift in
            TMEditorSheet(
                lift: lift,
                value: bindingForLift(lift),
                unit: selectedUnit
            )
        }
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
        isAutopilotEnabled = profile.isAutopilotEnabled
        age = Double(profile.age)
    }

    private func convertSavedWeights(from old: WeightUnit, to new: WeightUnit) {
        guard old != new, userProfiles.first?.weightUnit == old else { return }
        let convert: (Double) -> Double = {
            WeightConversion.convert($0, fromKilograms: old == .kg, toKilograms: new == .kg)
        }
        squatTM = WorkoutCalculator.calculatedWeight(convert(squatTM), roundTo: new.roundTo)
        benchTM = WorkoutCalculator.calculatedWeight(convert(benchTM), roundTo: new.roundTo)
        deadliftTM = WorkoutCalculator.calculatedWeight(convert(deadliftTM), roundTo: new.roundTo)
        ohpTM = WorkoutCalculator.calculatedWeight(convert(ohpTM), roundTo: new.roundTo)
        for session in sessions { session.amrapWeight = convert(session.amrapWeight) }
        for accessory in accessories { accessory.weight = convert(accessory.weight) }
        saveProfile()
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
            profile.isAutopilotEnabled = isAutopilotEnabled
            profile.age = Int(age)
            do { try modelContext.save() } catch {
                modelContext.rollback()
                saveError = "Your previous settings have been kept. Please try again."
                loadProfile()
            }
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

                Text("\(IronTheme.weight(value)) \(unit.label)")
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

    var body: some View {
        SetWeightEditor(weight: $value, unit: unit, accent: lift.color,
                        isBarbell: false, title: "\(lift.shortName) training max", saveTitle: "Save training max")
    }
}

extension MainLift: Identifiable {
    public var id: Int { rawValue }
}

#Preview {
    SettingsView()
}

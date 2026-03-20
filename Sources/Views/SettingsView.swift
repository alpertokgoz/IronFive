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

    var body: some View {
        Form {
            Section(header: Text("Training Maxes (TM)").font(.footnote).fontWeight(.bold).kerning(1.2)) {
                Stepper(value: $squatTM, in: 0...1000, step: 2.5) {
                    HStack {
                        Text("Squat")
                        Spacer()
                        Text(String(format: "%.1f", squatTM))
                            .foregroundColor(.orange)
                    }
                }
                Stepper(value: $benchTM, in: 0...1000, step: 2.5) {
                    HStack {
                        Text("Bench")
                        Spacer()
                        Text(String(format: "%.1f", benchTM))
                            .foregroundColor(.blue)
                    }
                }
                Stepper(value: $deadliftTM, in: 0...1000, step: 2.5) {
                    HStack {
                        Text("Deadlift")
                        Spacer()
                        Text(String(format: "%.1f", deadliftTM))
                            .foregroundColor(.green)
                    }
                }
                Stepper(value: $ohpTM, in: 0...1000, step: 2.5) {
                    HStack {
                        Text("OHP")
                        Spacer()
                        Text(String(format: "%.1f", ohpTM))
                            .foregroundColor(.purple)
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))

            Section(header: Text("Program Settings").font(.footnote).fontWeight(.bold).kerning(1.2)) {
                Picker("Unit", selection: $selectedUnit) {
                    Text("lbs").tag(WeightUnit.lbs)
                    Text("kg").tag(WeightUnit.kg)
                }

                Picker("Template", selection: $selectedTemplate) {
                    ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                        Text(template.name).tag(template)
                    }
                }

                Toggle("Use 4-Week Cycle", isOn: $usesFourWeekCycle)

                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text(usesFourWeekCycle ? "TMs increase after Week 4" : "TMs increase after Week 3")
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

#Preview {
    SettingsView()
}

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var squatTM: String = ""
    @State private var benchTM: String = ""
    @State private var deadliftTM: String = ""
    @State private var ohpTM: String = ""
    @State private var trainingMax: String = "90"
    @State private var selectedTemplate: SupplementalTemplate = .fsl

    var body: some View {
        Form {
            Section(header: Text("Training Maxes (TM)").font(.footnote).fontWeight(.bold).kerning(1.2)) {
                HStack {
                    Text("Squat")
                    Spacer()
                    TextField("0", text: $squatTM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.orange)
                }
                HStack {
                    Text("Bench")
                    Spacer()
                    TextField("0", text: $benchTM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.blue)
                }
                HStack {
                    Text("Deadlift")
                    Spacer()
                    TextField("0", text: $deadliftTM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.green)
                }
                HStack {
                    Text("OHP")
                    Spacer()
                    TextField("0", text: $ohpTM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.purple)
                }
            }
            .listRowBackground(Color.white.opacity(0.05))

            Section(header: Text("Program Settings").font(.footnote).fontWeight(.bold).kerning(1.2)) {
                HStack {
                    Text("TM %")
                    Spacer()
                    TextField("90", text: $trainingMax)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.accentColor)
                }
                
                Picker("Template", selection: $selectedTemplate) {
                    ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                        Text(template.name).tag(template)
                    }
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
        squatTM = String(format: "%.1f", profile.squatTM)
        benchTM = String(format: "%.1f", profile.benchTM)
        deadliftTM = String(format: "%.1f", profile.deadliftTM)
        ohpTM = String(format: "%.1f", profile.ohpTM)
        trainingMax = String(format: "%.0f", profile.trainingMaxPercentage * 100)
        selectedTemplate = profile.selectedTemplate
    }

    private func saveProfile() {
        if let profile = userProfiles.first {
            profile.squatTM = Double(squatTM) ?? 0
            profile.benchTM = Double(benchTM) ?? 0
            profile.deadliftTM = Double(deadliftTM) ?? 0
            profile.ohpTM = Double(ohpTM) ?? 0
            profile.trainingMaxPercentage = (Double(trainingMax) ?? 90) / 100
            profile.selectedTemplate = selectedTemplate
        }

        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
}

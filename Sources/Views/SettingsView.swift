import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]

    @State private var squat1RM: String = ""
    @State private var bench1RM: String = ""
    @State private var deadlift1RM: String = ""
    @State private var ohp1RM: String = ""
    @State private var trainingMax: String = "90"

    var body: some View {
        Form {
            Section(header: Text("1 Rep Maxes")) {
                HStack {
                    Text("Squat")
                    Spacer()
                    TextField("0", text: $squat1RM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Text("Bench")
                    Spacer()
                    TextField("0", text: $bench1RM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Text("Deadlift")
                    Spacer()
                    TextField("0", text: $deadlift1RM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.accentColor)
                }
                HStack {
                    Text("OHP")
                    Spacer()
                    TextField("0", text: $ohp1RM)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.accentColor)
                }
            }

            Section(header: Text("Program Settings")) {
                HStack {
                    Text("TM %")
                    Spacer()
                    TextField("90", text: $trainingMax)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.accentColor)
                }
            }

            Section {
                NavigationLink("Manage Accessories", destination: AccessorySettingsView())
            }
        }
        .navigationTitle("Settings")
        .containerBackground(Color.gray.gradient, for: .navigation)
        .onAppear {
            loadProfile()
        }
        .onDisappear {
            saveProfile()
        }
    }

    private func loadProfile() {
        guard let profile = userProfiles.first else { return }
        squat1RM = String(format: "%.1f", profile.squat1RM)
        bench1RM = String(format: "%.1f", profile.bench1RM)
        deadlift1RM = String(format: "%.1f", profile.deadlift1RM)
        ohp1RM = String(format: "%.1f", profile.ohp1RM)
        trainingMax = String(format: "%.0f", profile.trainingMaxPercentage * 100)
    }

    private func saveProfile() {
        if let profile = userProfiles.first {
            profile.squat1RM = Double(squat1RM) ?? 0
            profile.bench1RM = Double(bench1RM) ?? 0
            profile.deadlift1RM = Double(deadlift1RM) ?? 0
            profile.ohp1RM = Double(ohp1RM) ?? 0
            profile.trainingMaxPercentage = (Double(trainingMax) ?? 90) / 100
        }

        try? modelContext.save()
    }
}

#Preview {
    SettingsView()
}

import SwiftUI
import SwiftData

struct AccessorySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var accessories: [AccessoryExercise]

    @State private var showingAddSheet = false
    @State private var editingAccessory: AccessoryExercise?
    @State private var saveError: String?
    @State private var showClearConfirmation = false

    private var weightUnit: WeightUnit {
        userProfiles.first?.weightUnit ?? .lbs
    }

    var body: some View {
        List {
            if accessories.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No assistance exercises.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Button("Load template defaults") {
                            loadDefaults()
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .controlSize(.small)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }

            ForEach(MainLift.allCases, id: \.self) { lift in
                let liftAccessories = accessories.filter { $0.relatedLift == lift }

                if !liftAccessories.isEmpty {
                    Section(header:
                        HStack(spacing: 4) {
                            Image(systemName: lift.symbolName)
                            Text(lift.name)
                        }
                    ) {
                        ForEach(liftAccessories) { accessory in
                            Button(action: { editingAccessory = accessory }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(accessory.name).font(.system(size: 15, weight: .semibold, design: .rounded))
                                        Text("\(accessory.targetSets) × \(accessory.targetReps) · \(accessory.weight == 0 ? "No added weight" : IronTheme.weight(accessory.weight) + " " + weightUnit.label)")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "pencil")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { indexSet in
                            deleteAccessories(at: indexSet, from: liftAccessories)
                        }
                    }
                }
            }

            Section {
                Button(action: { showingAddSheet.toggle() }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add exercise")
                    }
                    .foregroundColor(.accentColor)
                }

                if !accessories.isEmpty {
                    Button(role: .destructive, action: {
                        showClearConfirmation = true
                    }) {
                        Text("Clear all")
                    }
                }
            }
        }
        .navigationTitle("Assistance")
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet.toggle() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("Could not save assistance", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { Button("OK") { saveError = nil } } message: { Text(saveError ?? "") }
        .sheet(isPresented: $showingAddSheet) {
            AddAccessoryView()
        }
        .sheet(item: $editingAccessory) { accessory in
            AddAccessoryView(editingAccessory: accessory)
        }
        .confirmationDialog("Clear all accessories?", isPresented: $showClearConfirmation, titleVisibility: .visible) {
            Button("Clear all", role: .destructive) {
                for acc in accessories { modelContext.delete(acc) }
                saveChanges()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    private func saveChanges() {
        do { try modelContext.save() } catch {
            modelContext.rollback()
            saveError = "Your previous exercises were kept. Please try again."
        }
    }

    private func loadDefaults() {
        let template = userProfiles.first?.selectedTemplate ?? .fsl
        for lift in MainLift.allCases {
            let defaults = template.defaultAccessories(for: lift)
            for acc in defaults {
                modelContext.insert(acc)
            }
        }
        saveChanges()
    }

    private func deleteAccessories(at offsets: IndexSet, from list: [AccessoryExercise]) {
        for index in offsets {
            let accessory = list[index]
            modelContext.delete(accessory)
        }
        saveChanges()
    }
}

#Preview {
    AccessorySettingsView()
}

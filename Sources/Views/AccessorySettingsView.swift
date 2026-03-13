import SwiftUI
import SwiftData

struct AccessorySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userProfiles: [UserProfile]
    @Query private var accessories: [AccessoryExercise]

    @State private var showingAddSheet = false
    @State private var editingAccessory: AccessoryExercise?

    var body: some View {
        List {
            if accessories.isEmpty {
                Section {
                    VStack(spacing: 8) {
                        Text("No accessories found.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Load Template Defaults") {
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
                                        Text(accessory.name).fontWeight(.bold)
                                        Text("\(accessory.targetSets) Sets x \(accessory.targetReps) @ \(String(format: "%.1f", accessory.weight)) kg")
                                            .font(.caption)
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
                        Text("Add Accessory")
                    }
                    .foregroundColor(.accentColor)
                }
                
                if !accessories.isEmpty {
                    Button(role: .destructive, action: {
                        for acc in accessories { modelContext.delete(acc) }
                    }) {
                        Text("Clear All")
                    }
                }
            }
        }
        .navigationTitle("Accessories")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet.toggle() }) {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            if accessories.isEmpty {
                loadDefaults()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAccessoryView()
        }
        .sheet(item: $editingAccessory) { accessory in
            AddAccessoryView(editingAccessory: accessory)
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
        try? modelContext.save()
    }

    private func deleteAccessories(at offsets: IndexSet, from list: [AccessoryExercise]) {
        for index in offsets {
            let accessory = list[index]
            modelContext.delete(accessory)
        }
        try? modelContext.save()
    }
}

#Preview {
    AccessorySettingsView()
}

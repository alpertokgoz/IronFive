import SwiftUI
import SwiftData

struct AccessorySettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accessories: [AccessoryExercise]
    
    @State private var showingAddSheet = false
    
    var body: some View {
        List {
            ForEach(MainLift.allCases, id: \.self) { lift in
                Section(header: Text("\(lift.name) Day Accessories")) {
                    let liftAccessories = accessories.filter { $0.relatedLift == lift }
                    
                    if liftAccessories.isEmpty {
                        Text("No accessories added.")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(liftAccessories) { accessory in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(accessory.name).fontWeight(.bold)
                                    Text("\(accessory.targetSets) Sets x \(accessory.targetReps) Reps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteAccessories(at: indexSet, from: liftAccessories)
                        }
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
        .sheet(isPresented: $showingAddSheet) {
            AddAccessoryView()
        }
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

import SwiftUI
import SwiftData

struct AddAccessoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var targetSets: Int = 3
    @State private var targetReps: Int = 10
    @State private var relatedLift: MainLift = .squat
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Accessory Identity")) {
                    TextField("Exercise Name", text: $name)
                }
                
                Section(header: Text("Volume & Programming")) {
                    Stepper(value: $targetSets, in: 1...10) {
                        Text("\(targetSets) Sets")
                    }
                    
                    Stepper(value: $targetReps, in: 1...30) {
                        Text("\(targetReps) Reps")
                    }
                    
                    Picker("Related Lift", selection: $relatedLift) {
                        ForEach(MainLift.allCases, id: \.self) { lift in
                            Text("\(lift.name) Day").tag(lift)
                        }
                    }
                }
            }
            .navigationTitle("Add Accessory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newAccessory = AccessoryExercise(
                            name: name,
                            targetSets: targetSets,
                            targetReps: targetReps,
                            relatedLift: relatedLift
                        )
                        modelContext.insert(newAccessory)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddAccessoryView()
}

import SwiftUI
import SwiftData

struct AddAccessoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var userProfiles: [UserProfile]
    var editingAccessory: AccessoryExercise?
    var initialSection: String?
    @State private var name = ""
    @State private var targetSets = 3.0
    @State private var targetReps = 10.0
    @State private var weight = 0.0
    @State private var relatedLift: MainLift = .squat
    @State private var editor: Editor?
    @State private var loaded = false
    @State private var saveError: String?

    private var unit: WeightUnit { userProfiles.first?.weightUnit ?? .lbs }
    private var validName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    enum Editor: String, Identifiable {
        case sets, reps, weight
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
            Form {
                Section("Exercise name") {
                    TextField("e.g. Ab wheel", text: $name)
                        .accessibilityLabel("Exercise name")
                }
                Section("Training day") {
                    Picker("Lift", selection: $relatedLift) {
                        ForEach(MainLift.allCases, id: \.self) { lift in Text(lift.name).tag(lift) }
                    }
                }
                Section("Prescription") {
                    editRow("Sets", value: "\(Int(targetSets))", editor: .sets)
                    editRow("Reps", value: "\(Int(targetReps))", editor: .reps)
                    editRow("Added weight", value: weight == 0 ? "None" : "\(IronTheme.weight(weight)) \(unit.label)", editor: .weight)
                    Text("Zero means no added weight. Tap a value to edit.")
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                .id("prescription")
                Section {
                    Button(editingAccessory == nil ? "Add exercise" : "Save exercise", action: save)
                        .buttonStyle(IronButtonStyle())
                        .disabled(validName.isEmpty)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(editingAccessory == nil ? "New exercise" : "Edit exercise")
            .navigationBarTitleDisplayMode(.inline)
            .containerBackground(IronTheme.canvas.gradient, for: .navigation)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .onAppear {
                guard !loaded else { return }
                if let exercise = editingAccessory {
                    name = exercise.name
                    targetSets = Double(exercise.targetSets)
                    targetReps = Double(exercise.targetReps)
                    weight = exercise.weight
                    relatedLift = exercise.relatedLift
                }
                loaded = true
                if let section = initialSection {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { proxy.scrollTo(section, anchor: .top) }
                }
            }
            .sheet(item: $editor) { item in
                switch item {
                case .sets: CountEditor(value: $targetSets, title: "Sets", range: 1...10, saveTitle: "Save sets")
                case .reps: CountEditor(value: $targetReps, title: "Reps", range: 1...50, saveTitle: "Save reps")
                case .weight: SetWeightEditor(weight: $weight, unit: unit, isBarbell: false, title: "Added weight")
                }
            }
            .alert("Could not save exercise", isPresented: Binding(
                get: { saveError != nil }, set: { if !$0 { saveError = nil } }
            )) { Button("OK") { saveError = nil } } message: { Text(saveError ?? "") }
            }
        }
    }

    private func editRow(_ title: String, value: String, editor: Editor) -> some View {
        Button { self.editor = editor } label: {
            HStack(spacing: 5) {
                Text(title).foregroundStyle(.white)
                Spacer(minLength: 0)
                Text(value).foregroundStyle(IronTheme.ember)
                    .lineLimit(1).minimumScaleFactor(0.7)
                Image(systemName: "pencil").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
        }
        .buttonStyle(.plain)
    }

    private func save() {
        guard !validName.isEmpty else { return }
        if let exercise = editingAccessory {
            exercise.name = validName
            exercise.targetSets = Int(targetSets)
            exercise.targetReps = Int(targetReps)
            exercise.weight = weight
            exercise.relatedLift = relatedLift
        } else {
            modelContext.insert(AccessoryExercise(name: validName, targetSets: Int(targetSets),
                                                 targetReps: Int(targetReps), weight: weight, relatedLift: relatedLift))
        }
        do { try modelContext.save() } catch {
            modelContext.rollback()
            saveError = "Your previous exercises were kept. Please try again."
            return
        }
        dismiss()
    }
}

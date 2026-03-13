import SwiftUI
import SwiftData

struct AddAccessoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    var editingAccessory: AccessoryExercise?

    @State private var name: String = ""
    @State private var targetSets: Int = 3
    @State private var targetReps: Int = 10
    @State private var weight: Double = 0
    @State private var relatedLift: MainLift = .squat

    @FocusState private var focusedField: Field?

    enum Field {
        case sets, reps, weight
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    TextField("Exercise Name", text: $name)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        Picker("Related Lift", selection: $relatedLift) {
                            ForEach(MainLift.allCases, id: \.self) { lift in
                                Text(lift.name).tag(lift)
                            }
                        }
                        .pickerStyle(.navigationLink)

                        Divider().background(Color.white.opacity(0.1))

                        // Sets
                        HStack {
                            Text("Sets")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text("\(targetSets)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .frame(width: 44, height: 32)
                                .background(focusedField == .sets ? Color.accentColor : Color.white.opacity(0.1))
                                .foregroundColor(focusedField == .sets ? .black : .primary)
                                .cornerRadius(8)
                                .focusable()
                                .focused($focusedField, equals: .sets)
                                .digitalCrownRotation($targetSets.toDouble(), from: 1, through: 10, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                        }

                        // Reps
                        HStack {
                            Text("Reps")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text("\(targetReps)")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .frame(width: 44, height: 32)
                                .background(focusedField == .reps ? Color.accentColor : Color.white.opacity(0.1))
                                .foregroundColor(focusedField == .reps ? .black : .primary)
                                .cornerRadius(8)
                                .focusable()
                                .focused($focusedField, equals: .reps)
                                .digitalCrownRotation($targetReps.toDouble(), from: 1, through: 50, by: 1, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                        }

                        // Weight
                        HStack {
                            Text("Weight")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            HStack(spacing: 2) {
                                Text("\(String(format: "%.1f", weight))")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                Text("kg")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                            .frame(minWidth: 60, minHeight: 32)
                            .background(focusedField == .weight ? Color.accentColor : Color.white.opacity(0.1))
                            .foregroundColor(focusedField == .weight ? .black : .primary)
                            .cornerRadius(8)
                            .focusable()
                            .focused($focusedField, equals: .weight)
                            .digitalCrownRotation($weight, from: 0, through: 500, by: 2.5, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)

                    Button(action: save) {
                        Text("SAVE")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle(editingAccessory == nil ? "Add" : "Edit")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let acc = editingAccessory {
                    name = acc.name
                    targetSets = acc.targetSets
                    targetReps = acc.targetReps
                    weight = acc.weight
                    relatedLift = acc.relatedLift
                }
            }
        }
    }

    private func save() {
        if let editingAccessory = editingAccessory {
            editingAccessory.name = name
            editingAccessory.targetSets = targetSets
            editingAccessory.targetReps = targetReps
            editingAccessory.weight = weight
            editingAccessory.relatedLift = relatedLift
        } else {
            let newAccessory = AccessoryExercise(
                name: name,
                targetSets: targetSets,
                targetReps: targetReps,
                weight: weight,
                relatedLift: relatedLift
            )
            modelContext.insert(newAccessory)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddAccessoryView()
}

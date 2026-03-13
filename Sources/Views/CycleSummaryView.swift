import SwiftUI
import SwiftData

struct CycleSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query private var accessories: [AccessoryExercise]
    
    let profile: UserProfile
    let lastLift: MainLift
    let amrapReps: Int
    let amrapWeight: Double
    let onComplete: () -> Void

    @State private var suggestedSquat: Double = 0
    @State private var suggestedBench: Double = 0
    @State private var suggestedDeadlift: Double = 0
    @State private var suggestedOHP: Double = 0
    @State private var selectedTemplate: SupplementalTemplate = .fsl

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("CYCLE \(profile.currentCycle) COMPLETE")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                    
                    Text("AUTO-REGULATION")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .padding(.top, 4)

                if amrapReps > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: lastLift.symbolName)
                            .foregroundColor(lastLift.color)
                        VStack(alignment: .leading, spacing: 0) {
                            Text("LAST AMRAP")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("\(amrapReps) × \(Int(amrapWeight)) kg")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                        }
                    }
                    .padding(6)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("SUGGESTED TMS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    TMRow(lift: .squat, old: profile.squatTM, new: $suggestedSquat)
                    TMRow(lift: .bench, old: profile.benchTM, new: $suggestedBench)
                    TMRow(lift: .deadlift, old: profile.deadliftTM, new: $suggestedDeadlift)
                    TMRow(lift: .ohp, old: profile.ohpTM, new: $suggestedOHP)
                }
                .padding(.horizontal, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT CYCLE TEMPLATE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    Picker("Template", selection: $selectedTemplate) {
                        ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                            Text(template.shortName).tag(template)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    NavigationLink(destination: AccessorySettingsView()) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Customise Accessories")
                        }
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)

                Button("CONFIRM & START") {
                    saveAndAdvance()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding()
        }
        .containerBackground(Color.black.gradient, for: .navigation)
        .onAppear {
            calculateSuggestions()
            selectedTemplate = profile.selectedTemplate
        }
    }

    private func TMRow(lift: MainLift, old: Double, new: Binding<Double>) -> some View {
        HStack {
            Image(systemName: lift.symbolName)
                .font(.system(size: 10))
                .foregroundColor(lift.color)
            Text(lift.name)
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Spacer()
            HStack(spacing: 4) {
                Text("\(Int(old))")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .strikethrough()
                
                Text("\(Int(new.wrappedValue))")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(lift.color.opacity(0.15))
                    .cornerRadius(4)
                    .focusable()
                    .digitalCrownRotation(new, from: 0, through: 1000, by: profile.weightUnit.roundTo, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
            }
        }
    }

    private func calculateSuggestions() {
        let unit = profile.weightUnit
        suggestedSquat = profile.squatTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .squat, currentTM: profile.squatTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
        suggestedBench = profile.benchTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .bench, currentTM: profile.benchTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
        suggestedDeadlift = profile.deadliftTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .deadlift, currentTM: profile.deadliftTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
        suggestedOHP = profile.ohpTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .ohp, currentTM: profile.ohpTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
    }

    private func saveAndAdvance() {
        let templateChanged = (profile.selectedTemplate != selectedTemplate)
        
        profile.squatTM = suggestedSquat
        profile.benchTM = suggestedBench
        profile.deadliftTM = suggestedDeadlift
        profile.ohpTM = suggestedOHP
        profile.selectedTemplate = selectedTemplate
        
        if templateChanged {
            for acc in accessories {
                modelContext.delete(acc)
            }
            for lift in MainLift.allCases {
                let defaults = selectedTemplate.defaultAccessories(for: lift)
                for acc in defaults {
                    modelContext.insert(acc)
                }
            }
        }

        profile.currentWeek = 1
        profile.currentCycle += 1
        
        try? modelContext.save()
        onComplete()
        dismiss()
    }
}

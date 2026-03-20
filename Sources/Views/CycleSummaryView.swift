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
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                Text("CYCLE \(profile.currentCycle) COMPLETE")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)

                Text("AUTO-REGULATION")
                    .font(.system(size: 13, weight: .black, design: .rounded))
            }
            .padding(.top, 2)

            if amrapReps > 0 {
                HStack(spacing: 6) {
                    Image(systemName: lastLift.symbolName)
                        .font(.system(size: 10))
                        .foregroundColor(lastLift.color)
                    Text("\(amrapReps) × \(Int(amrapWeight))\(profile.weightUnit.label)")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("SUGGESTED TMS")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    CompactTMBox(lift: .squat, old: profile.squatTM, new: $suggestedSquat, unit: profile.weightUnit)
                    CompactTMBox(lift: .bench, old: profile.benchTM, new: $suggestedBench, unit: profile.weightUnit)
                    CompactTMBox(lift: .deadlift, old: profile.deadliftTM, new: $suggestedDeadlift, unit: profile.weightUnit)
                    CompactTMBox(lift: .ohp, old: profile.ohpTM, new: $suggestedOHP, unit: profile.weightUnit)
                }
            }
            .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Picker("Template", selection: $selectedTemplate) {
                        ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                            Text(template.shortName).tag(template)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .labelsHidden()
                    .frame(height: 32)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1)))

                    NavigationLink(destination: AccessorySettingsView()) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12))
                            .frame(width: 44, height: 32)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)

            Button("CONFIRM & START") {
                saveAndAdvance()
            }
            .font(.system(size: 13, weight: .black, design: .rounded))
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .frame(height: 36)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
        .containerBackground(Color.black.gradient, for: .navigation)
        .onAppear {
            calculateSuggestions()
            selectedTemplate = profile.selectedTemplate
        }
    }

    private func CompactTMBox(lift: MainLift, old: Double, new: Binding<Double>, unit: WeightUnit) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: lift.symbolName)
                    .font(.system(size: 8))
                    .foregroundColor(lift.color)
                Text(lift.shortName)
                    .font(.system(size: 8, weight: .black))
            }

            Text("\(Int(new.wrappedValue))")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 24)
                .background(lift.color.opacity(0.15))
                .cornerRadius(4)
                .focusable()
                .digitalCrownRotation(new, from: 0, through: 1000, by: unit.roundTo, sensitivity: .low, isContinuous: false, isHapticFeedbackEnabled: true)
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
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

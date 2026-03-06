import SwiftUI
import SwiftData

struct CycleSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    let profile: UserProfile
    let lastLift: MainLift
    let amrapReps: Int
    let amrapWeight: Double
    let onComplete: () -> Void

    @State private var suggestedSquat: Double = 0
    @State private var suggestedBench: Double = 0
    @State private var suggestedDeadlift: Double = 0
    @State private var suggestedOHP: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("CYCLE \(profile.currentCycle) COMPLETE")
                        .font(.system(.footnote, design: .rounded, weight: .black))
                        .foregroundColor(.accentColor)
                    
                    Text("Auto-Regulation")
                        .font(.system(.title3, design: .rounded, weight: .black))
                }
                .padding(.top, 8)

                if amrapReps > 0 {
                    VStack(spacing: 2) {
                        Text("LAST SESSION")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text("\(lastLift.name): \(amrapReps) reps @ \(String(format: "%.1f", amrapWeight))")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("SUGGESTED TMS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    TMRow(name: "Squat", old: profile.squatTM, new: suggestedSquat, color: .orange)
                    TMRow(name: "Bench", old: profile.benchTM, new: suggestedBench, color: .blue)
                    TMRow(name: "Deadlift", old: profile.deadliftTM, new: suggestedDeadlift, color: .green)
                    TMRow(name: "OHP", old: profile.ohpTM, new: suggestedOHP, color: .purple)
                }
                .padding(.horizontal, 8)

                Button("Confirm & Advance") {
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
        }
    }

    private func TMRow(name: String, old: Double, new: Double, color: Color) -> some View {
        HStack {
            Text(name)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundColor(color)
            Spacer()
            HStack(spacing: 4) {
                Text("\(Int(old))")
                    .foregroundColor(.secondary)
                    .strikethrough()
                Image(systemName: "arrow.right")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text("\(Int(new))")
                    .fontWeight(.bold)
            }
            .font(.system(size: 12, design: .monospaced))
        }
    }

    private func calculateSuggestions() {
        // We use the last session's performance to guide the jump
        // In a real 5/3/1 program, you usually increase regardless, but 
        // Auto-regulation can double the jump if performance was stellar.
        
        let unit = profile.weightUnit
        
        suggestedSquat = profile.squatTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .squat, currentTM: profile.squatTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
        suggestedBench = profile.benchTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .bench, currentTM: profile.benchTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
        suggestedDeadlift = profile.deadliftTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .deadlift, currentTM: profile.deadliftTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
        suggestedOHP = profile.ohpTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .ohp, currentTM: profile.ohpTM, amrapWeight: amrapWeight, amrapReps: amrapReps, unit: unit)
    }

    private func saveAndAdvance() {
        profile.squatTM = suggestedSquat
        profile.benchTM = suggestedBench
        profile.deadliftTM = suggestedDeadlift
        profile.ohpTM = suggestedOHP
        
        profile.currentWeek = 1
        profile.currentCycle += 1
        
        onComplete()
        dismiss()
    }
}

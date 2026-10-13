import SwiftUI
import SwiftData

struct CycleSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @Query private var accessories: [AccessoryExercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]

    let profile: UserProfile
    let lastLift: MainLift
    let amrapReps: Int
    let amrapWeight: Double
    let onComplete: () -> Void
    var initialPage = 0

    @State private var suggestedSquat: Double = 0
    @State private var suggestedBench: Double = 0
    @State private var suggestedDeadlift: Double = 0
    @State private var suggestedOHP: Double = 0
    @State private var selectedTemplate: SupplementalTemplate = .fsl

    @State private var page = 0
    @State private var showTemplates = false
    @State private var editingLift: MainLift?
    @State private var loaded = false
    @State private var saveError: String?

    var body: some View {
        TabView(selection: $page) {
            GeometryReader { geometry in
                VStack(spacing: 5) {
                    IronEyebrow(text: "Cycle \(profile.currentCycle) complete", color: IronTheme.mint)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                        ForEach(MainLift.allCases, id: \.self) { lift in
                            Button { editingLift = lift } label: {
                                VStack(spacing: 2) {
                                    HStack(spacing: 3) {
                                        Text(lift.shortName)
                                        Image(systemName: "pencil").font(.system(size: 8))
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    Text(IronTheme.weight(suggestion(lift).wrappedValue))
                                        .font(.system(size: 21, weight: .semibold, design: .rounded))
                                        .foregroundStyle(lift.color)
                                        .lineLimit(1).minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: .infinity, minHeight: 43)
                                .modifier(IronCard(accent: lift.color))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit \(lift.name) training max")
                        }
                    }
                    Text("Next training maxes · \(profile.weightUnit.label)")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    Button("Review program") { withAnimation { page = 1 } }
                        .buttonStyle(IronButtonStyle())
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .onAppear(perform: loadSuggestions)
            .tag(0)
            VStack(spacing: 6) {
                ScrollView {
                    VStack(spacing: 8) {
                        Button { showTemplates = true } label: {
                            HStack {
                                Text("Template")
                                Spacer(minLength: 0)
                                Text(selectedTemplate.shortName).foregroundStyle(IronTheme.mint)
                                Image(systemName: "chevron.right").font(.system(size: 10))
                            }
                            .padding(.horizontal, 10)
                        }
                        .buttonStyle(IronButtonStyle(secondary: true))
                        NavigationLink("Assistance exercises", destination: AccessorySettingsView())
                            .buttonStyle(IronButtonStyle(secondary: true))
                        if selectedTemplate != profile.selectedTemplate {
                            Text("Changing template replaces assistance with its defaults.")
                                .font(.system(size: 11)).foregroundStyle(IronTheme.ember)
                        }
                        if amrapReps > 0 {
                            Text("Last set · \(amrapReps) × \(IronTheme.weight(amrapWeight)) \(profile.weightUnit.label)")
                                .font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }
                Button("Start cycle \(profile.currentCycle + 1)", action: saveAndAdvance)
                    .buttonStyle(IronButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .navigationTitle(page == 0 ? "Next cycle" : "Program")
        .navigationBarTitleDisplayMode(.inline)
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .sheet(isPresented: $showTemplates) {
            NavigationStack {
                List {
                    ForEach(SupplementalTemplate.allCases, id: \.self) { template in
                        Button {
                            selectedTemplate = template
                            showTemplates = false
                        } label: {
                            HStack {
                                Text(template.shortName)
                                Spacer()
                                if template == selectedTemplate { Image(systemName: "checkmark").foregroundStyle(IronTheme.mint) }
                            }
                        }
                    }
                }
                .navigationTitle("Template")
            }
        }
        .sheet(item: $editingLift) { lift in
            TMEditorSheet(lift: lift, value: suggestion(lift), unit: profile.weightUnit)
        }
        .alert("Could not start cycle", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { Button("OK") { saveError = nil } } message: { Text(saveError ?? "") }
    }

    private func loadSuggestions() {
        guard !loaded else { return }
        calculateSuggestions()
        selectedTemplate = profile.selectedTemplate
        loaded = true
        page = min(max(initialPage, 0), 1)
    }

    private func suggestion(_ lift: MainLift) -> Binding<Double> {
        switch lift {
        case .squat: return $suggestedSquat
        case .bench: return $suggestedBench
        case .deadlift: return $suggestedDeadlift
        case .ohp: return $suggestedOHP
        }
    }

    private func calculateSuggestions() {
        let unit = profile.weightUnit

        func getAmrap(for lift: MainLift) -> (weight: Double, reps: Int) {
            if lift == lastLift {
                return (amrapWeight, amrapReps)
            }
            if let session = workoutSessions.first(where: { $0.mainLift == lift && $0.amrapReps > 0 }) {
                return (session.amrapWeight, session.amrapReps)
            }
            return (0, 0)
        }

        let squatAmrap = getAmrap(for: .squat)
        suggestedSquat = profile.squatTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .squat, currentTM: profile.squatTM, amrapWeight: squatAmrap.weight, amrapReps: squatAmrap.reps, unit: unit)

        let benchAmrap = getAmrap(for: .bench)
        suggestedBench = profile.benchTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .bench, currentTM: profile.benchTM, amrapWeight: benchAmrap.weight, amrapReps: benchAmrap.reps, unit: unit)

        let deadliftAmrap = getAmrap(for: .deadlift)
        suggestedDeadlift = profile.deadliftTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .deadlift, currentTM: profile.deadliftTM, amrapWeight: deadliftAmrap.weight, amrapReps: deadliftAmrap.reps, unit: unit)

        let ohpAmrap = getAmrap(for: .ohp)
        suggestedOHP = profile.ohpTM + WorkoutCalculator.calculateSuggestedIncrease(lift: .ohp, currentTM: profile.ohpTM, amrapWeight: ohpAmrap.weight, amrapReps: ohpAmrap.reps, unit: unit)
    }

    private func saveAndAdvance() {
        guard [suggestedSquat, suggestedBench, suggestedDeadlift, suggestedOHP].allSatisfy({ $0 > 0 }) else {
            saveError = "Enter a positive training max for every lift."
            return
        }
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

        do { try modelContext.save() } catch {
            modelContext.rollback()
            saveError = "Your cycle was kept. Please try again."
            return
        }
        onComplete()
        dismiss()
    }
}

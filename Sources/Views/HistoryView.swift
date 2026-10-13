import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var userProfiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedLift: MainLift = .squat
    @State private var pendingDeletion: WorkoutSession?
    @State private var saveError: String?

    private var unit: String { userProfiles.first?.weightUnit.label ?? "lbs" }
    private var liftSessions: [WorkoutSession] { sessions.filter { $0.mainLift == selectedLift } }
    private var chartSessions: [WorkoutSession] {
        Array(liftSessions.filter { $0.isCompleted && $0.amrapReps > 0 }.prefix(10).reversed())
    }

    var body: some View {
        List {
            HStack(spacing: 4) {
                ForEach(MainLift.allCases, id: \.self) { lift in
                    Button { selectedLift = lift } label: {
                        Text(lift.shortName)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(selectedLift == lift ? lift.color.opacity(0.22) : IronTheme.surface, in: Capsule())
                            .foregroundStyle(selectedLift == lift ? lift.color : .secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(lift.name)
                    .accessibilityAddTraits(selectedLift == lift ? .isSelected : [])
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            if !chartSessions.isEmpty {
                Group {
                    VStack(alignment: .leading, spacing: 8) {
                        IronMetric(title: "Best estimated 1RM", value: IronTheme.estimate(liftSessions.filter { $0.isCompleted }.map { $0.estimated1RM }.max() ?? 0), unit: unit, accent: selectedLift.color)
                        Chart(chartSessions) { session in
                            LineMark(x: .value("Date", session.date), y: .value("Estimated 1RM", session.estimated1RM))
                                .foregroundStyle(selectedLift.color)
                            PointMark(x: .value("Date", session.date), y: .value("Estimated 1RM", session.estimated1RM))
                                .foregroundStyle(selectedLift.color)
                                .symbolSize(15)
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartXAxis(.hidden)
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) {
                                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                                AxisValueLabel().font(.system(size: 9))
                            }
                        }
                        .frame(height: 85)
                        .accessibilityLabel("Estimated one rep max trend for \(selectedLift.name)")
                        Text("Last \(chartSessions.count) AMRAP sessions")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 5)
                }
                .listRowBackground(IronTheme.surface)
            }
            if liftSessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: selectedLift.symbolName)
                        .font(.system(size: 26)).foregroundStyle(selectedLift.color)
                    Text("Your progress starts here.")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                    Text("Log a \(selectedLift.name.lowercased()) workout to build your history.")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            } else {
                Section("\(liftSessions.count) workouts") {
                    ForEach(liftSessions) { session in
                        HistorySessionRow(session: session, unit: unit)
                            .listRowBackground(IronTheme.surface)
                            .swipeActions {
                                Button(role: .destructive) { pendingDeletion = session } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Progress")
        .containerBackground(IronTheme.canvas.gradient, for: .navigation)
        .confirmationDialog("Delete this workout?", isPresented: Binding(
            get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }
        ), titleVisibility: .visible) {
            Button("Delete workout", role: .destructive, action: deleteSession)
            Button("Keep workout", role: .cancel) { pendingDeletion = nil }
        }
        .alert("Could not save", isPresented: Binding(
            get: { saveError != nil }, set: { if !$0 { saveError = nil } }
        )) { Button("OK") { saveError = nil } } message: { Text(saveError ?? "") }
    }

    private func deleteSession() {
        guard let session = pendingDeletion else { return }
        modelContext.delete(session)
        do { try modelContext.save() } catch {
            modelContext.rollback()
            saveError = "Your workout was kept. Please try again."
        }
        pendingDeletion = nil
    }
}

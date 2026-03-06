import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var userProfiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedChartLift: MainLift = .squat

    private var unitLabel: String {
        userProfiles.first?.weightUnit.label ?? "lbs"
    }

    private var chartData: [WorkoutSession] {
        sessions.filter { $0.mainLift == selectedChartLift && $0.amrapReps > 0 }
            .sorted { $0.date < $1.date } // Chart expects oldest to newest
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Lift", selection: $selectedChartLift) {
                        ForEach(MainLift.allCases, id: \.self) { lift in
                            Text(lift.name).tag(lift)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .tint(selectedChartLift.color)
                    
                    if chartData.isEmpty {
                        Text("No AMRAP data for \(selectedChartLift.name)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical)
                    } else {
                        Chart(chartData) { session in
                            LineMark(
                                x: .value("Date", session.date),
                                y: .value("Est 1RM", session.estimated1RM)
                            )
                            .foregroundStyle(selectedChartLift.color)
                            .symbol(Circle())
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let intVal = value.as(Int.self) {
                                        Text("\(intVal)")
                                            .font(.system(size: 8, weight: .bold))
                                    }
                                }
                            }
                        }
                        .chartXAxis(.hidden)
                        .frame(height: 120)
                        .padding(.top, 8)
                    }
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.white.opacity(0.05))

            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No workouts yet.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowBackground(Color.clear)
            } else {
                ForEach(sessions) { session in
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.mainLift.name)
                                        .font(.system(.title3, design: .rounded, weight: .black))
                                    .foregroundColor(session.mainLift.color)
                                    
                                    Text("Cycle \(session.cycle) • Week \(session.week)")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundColor(.secondary)
                                        .textCase(.uppercase)
                                }
                                Spacer()
                                Text(session.date.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            
                            if session.amrapReps > 0 {
                                Divider().background(Color.secondary.opacity(0.3))
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        Text("AMRAP")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.secondary)
                                        Text("\(String(format: "%.1f", session.amrapWeight)) × \(session.amrapReps)")
                                            .font(.system(.body, design: .rounded, weight: .bold))
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 0) {
                                        Text("EST. 1RM")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.secondary)
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text("\(Int(session.estimated1RM))")
                                                .font(.system(.title3, design: .rounded, weight: .black))
                                                .foregroundColor(.white)
                                            Text(unitLabel)
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteSession)
            }
        }
        .navigationTitle("History")
        .containerBackground(Color.black.gradient, for: .navigation)
    }

    private func deleteSession(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete session: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(for: WorkoutSession.self, inMemory: true)
    }
}

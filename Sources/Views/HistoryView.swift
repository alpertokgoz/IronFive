import SwiftUI
import SwiftData
import Charts

struct ChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let lift: MainLift
}

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var userProfiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    private var unitLabel: String {
        userProfiles.first?.weightUnit.label ?? "lbs"
    }

    private var chartData: [ChartPoint] {
        var points: [ChartPoint] = []
        for lift in MainLift.allCases {
            let liftSessions = sessions
                .filter { $0.mainLift == lift && $0.amrapReps > 0 }
                .sorted { $0.date < $1.date }
                .suffix(10)
            for session in liftSessions {
                points.append(ChartPoint(date: session.date, value: session.estimated1RM, lift: lift))
            }
        }
        return points
    }

    private func weekName(for week: Int) -> String {
        switch week {
        case 1: return "5's Week"
        case 2: return "3's Week"
        case 3: return "1's Week"
        case 4: return "Deload"
        default: return ""
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    if chartData.isEmpty {
                        Text("No 1's Week AMRAP data recorded yet")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical)
                    } else {
                        HStack(spacing: 12) {
                            ForEach(MainLift.allCases, id: \.self) { lift in
                                HStack(spacing: 3) {
                                    Circle().fill(lift.color).frame(width: 7, height: 7)
                                    Text(lift.shortName)
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, -2)

                        Chart(chartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Est 1RM", point.value)
                            )
                            .foregroundStyle(point.lift.color)
                            .interpolationMethod(.monotone)
                            .symbol {
                                Circle()
                                    .stroke(point.lift.color, lineWidth: 1)
                                    .frame(width: 4, height: 4)
                            }
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
                ForEach(sessions.prefix(4)) { session in
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.mainLift.name)
                                        .font(.system(.title3, design: .rounded, weight: .black))
                                    .foregroundColor(session.mainLift.color)

                                    Text("Cycle \(session.cycle) - \(weekName(for: session.week))")
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

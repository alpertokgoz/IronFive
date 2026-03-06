import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
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
                                        .foregroundColor(liftColor(session.mainLift))
                                    
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
                                            Text("lbs")
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
        try? modelContext.save()
    }
    
    private func liftColor(_ lift: MainLift) -> Color {
        switch lift {
        case .squat: return .orange
        case .bench: return .blue
        case .deadlift: return .green
        case .ohp: return .purple
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(for: WorkoutSession.self, inMemory: true)
    }
}

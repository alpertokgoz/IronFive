import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if sessions.isEmpty {
                Text("No workouts yet.")
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(sessions) { session in
                    Section(header: Text(session.date.formatted(date: .abbreviated, time: .omitted))) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(session.mainLift.name)
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                                Spacer()
                                Text("W\(session.week) C\(session.cycle)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                            
                            if session.amrapReps > 0 {
                                HStack {
                                    Text("\(String(format: "%.1f", session.amrapWeight)) lbs × \(session.amrapReps)")
                                        .font(.body)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("Est. 1RM")
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                            .textCase(.uppercase)
                                        Text("\(Int(session.estimated1RM))")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                    }
                                }
                                .padding(.top, 2)
                            } else {
                                Text("Completed")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteSession)
            }
        }
        .navigationTitle("History")
        .containerBackground(Color.accentColor.gradient, for: .navigation)
    }

    private func deleteSession(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        HistoryView()
            .modelContainer(for: WorkoutSession.self, inMemory: true)
    }
}

import SwiftUI

struct HistorySessionRow: View {
    let session: WorkoutSession
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(session.date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer()
                IronEyebrow(text: "C\(session.cycle) · W\(session.week)")
            }
            if !session.isCompleted {
                Label("Partial session", systemImage: "circle.lefthalf.filled")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(IronTheme.ember)
            }
            if session.amrapReps > 0 {
                Text("\(IronTheme.weight(session.amrapWeight)) × \(session.amrapReps)")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(session.mainLift.color)
                Text("\(unit) · e1RM \(IronTheme.estimate(session.estimated1RM)) \(unit)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            } else {
                Text(IronTheme.week(session.week))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

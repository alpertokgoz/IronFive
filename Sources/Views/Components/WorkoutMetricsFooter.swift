import SwiftUI

extension WorkoutActiveView {
    func metricsFooter() -> some View {
        HStack {
            HStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(heartRateColor(for: workoutManager.heartRate), lineWidth: 1.2)
                        .frame(width: 14, height: 14)
                    Image(systemName: "heart.fill")
                        .foregroundColor(heartRateColor(for: workoutManager.heartRate))
                        .font(.system(size: 7))
                }
                Text(workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "—")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                Text("BPM")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .foregroundColor(.purple)
                    .font(.system(size: 10))
                Text(workoutManager.elapsedTimeString)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.3))
    }
}

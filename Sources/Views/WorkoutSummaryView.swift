import SwiftUI

struct WorkoutSummaryView: View {
    @ObservedObject var workoutManager: WorkoutManager
    let profile: UserProfile
    let totalWeight: Double
    let showCelebration: Bool
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 4) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.yellow.gradient)
                Text(showCelebration ? "NEW PR!" : "WORKOUT SAVED")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(showCelebration ? .yellow : .white)
            }
            .padding(.top, 4)
            .padding(.bottom, 6)

            // Hero Stat: Volume
            VStack(alignment: .leading, spacing: 0) {
                Text("TOTAL VOLUME")
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundColor(.accentColor)
                    .opacity(0.8)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(Int(totalWeight))")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                    Text(profile.weightUnit.label.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor.opacity(0.1))
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 3)
                        .cornerRadius(1.5)
                        .padding(.vertical, 8)
                        .padding(.leading, 0)
                }
            )
            .padding(.horizontal, 4)
            .padding(.bottom, 8)

            // Health Stats Row
            HStack(spacing: 6) {
                CompactStatBox(
                    label: "KCAL",
                    value: workoutManager.activeEnergy > 0 ? "\(Int(workoutManager.activeEnergy))" : "—",
                    icon: "flame.fill",
                    color: .orange
                )
                CompactStatBox(
                    label: "BPM",
                    value: workoutManager.heartRate > 0 ? "\(Int(workoutManager.heartRate))" : "—",
                    icon: "heart.fill",
                    color: .red
                )
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 0)

            // Finish Button
            Button(action: onFinish) {
                Text("FINISH")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(Color.black.gradient, for: .navigation)
    }

}

struct CompactStatBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 11))
            VStack(alignment: .leading, spacing: -1) {
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                Text(label)
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

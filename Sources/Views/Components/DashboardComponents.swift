import SwiftUI
import SwiftData
import Charts

struct DashboardHeader: View {
    let profile: UserProfile

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("CYCLE \(profile.currentCycle) · \(profile.selectedTemplate.shortName)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundColor(.accentColor)
                Text(weekDescription(for: profile.currentWeek).uppercased())
                    .font(.system(size: 15, weight: .black, design: .rounded))
            }
            Spacer()

            HStack(spacing: 6) {
                NavigationLink(destination: HistoryView()) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 10))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 10))
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 0)
    }

    private func weekDescription(for week: Int) -> String {
        switch week {
        case 1: return "5's Week"
        case 2: return "3's Week"
        case 3: return "5/3/1 Week"
        case 4: return "Deload"
        default: return "Training"
        }
    }
}

struct WeeklyProgressDots: View {
    let profile: UserProfile
    let workoutSessions: [WorkoutSession]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainLift.allCases, id: \.self) { lift in
                let completed = isLiftCompletedThisWeek(lift, week: profile.currentWeek, cycle: profile.currentCycle)
                HStack(spacing: 2) {
                    if completed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .black))
                    }
                    Text(lift.shortName)
                        .font(.system(size: 8, weight: .black, design: .rounded))
                }
                .foregroundColor(completed ? .white : lift.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(completed ? lift.color : lift.color.opacity(0.1))
                        .overlay(Capsule().stroke(lift.color, lineWidth: completed ? 0 : 1.5))
                )
            }
        }
    }

    private func isLiftCompletedThisWeek(_ lift: MainLift, week: Int, cycle: Int) -> Bool {
        workoutSessions.contains { $0.mainLift == lift && $0.week == week && $0.cycle == cycle && $0.isCompleted }
    }
}

struct MainGlanceableCard: View {
    let nextLift: MainLift
    let profile: UserProfile
    @Binding var showSkipDeloadConfirmation: Bool
    let accessories: [AccessoryExercise]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill((profile.currentWeek == 4 ? Color.teal : nextLift.color).opacity(0.1))
                VStack(spacing: 2) {
                    if profile.currentWeek == 4 {
                        Text("DELOAD")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.teal.opacity(0.3)))
                            .foregroundColor(.teal)
                    }
                    Image(systemName: nextLift.symbolName)
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle((profile.currentWeek == 4 ? Color.teal : nextLift.color).gradient)
                    Text(nextLift.name.uppercased())
                        .font(.system(size: 16, weight: .black, design: .rounded))
                    Text("TM: \(String(format: "%.1f", getTM(for: nextLift, profile: profile))) \(profile.weightUnit.label)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 80)

            NavigationLink(destination: WorkoutActiveView(lift: nextLift, profile: profile, accessories: accessories)) {
                HStack {
                    Text("START WORKOUT")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 10))
                }
                .padding(.horizontal, 12)
                .frame(height: 36)
                .background(nextLift.color.gradient)
                .cornerRadius(10, corners: [.bottomLeft, .bottomRight])
            }
            .buttonStyle(.plain)

            if profile.currentWeek == 4 {
                Button(action: { showSkipDeloadConfirmation = true }) {
                    HStack {
                        Image(systemName: "forward.fill")
                        Text("SKIP DELOAD")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.teal.opacity(0.15)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.teal.opacity(0.3), lineWidth: 1))
                    .foregroundColor(.teal)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.top, 4)
    }

    private func getTM(for lift: MainLift, profile: UserProfile) -> Double {
        switch lift {
        case .squat: return profile.squatTM
        case .bench: return profile.benchTM
        case .deadlift: return profile.deadliftTM
        case .ohp: return profile.ohpTM
        }
    }
}

struct WorkoutPreviewCard: View {
    let profile: UserProfile
    let nextLift: MainLift
    let accessories: [AccessoryExercise]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            PreviewRow(icon: "flame.fill", label: "WARMUP", detail: "3 sets", color: .orange)
            PreviewRow(icon: "bolt.fill", label: "MAIN", detail: "3 sets (AMRAP)", color: .yellow)
            PreviewRow(icon: "repeat", label: profile.selectedTemplate.shortName, detail: supplementalDetail(profile), color: nextLift.color)
            let accCount = accessories.filter({ $0.relatedLift == nextLift }).count
            if accCount > 0 {
                PreviewRow(icon: "dumbbell.fill", label: "ACCESSORIES", detail: "\(accCount) exercises", color: .secondary)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        .padding(.top, 4)
    }

    private func supplementalDetail(_ profile: UserProfile) -> String {
        switch profile.selectedTemplate {
        case .fsl: return "5 × 5"
        case .bbb: return "5 × 10"
        case .ssl: return "5 × 5"
        case .bbs: return "10 × 5"
        case .widowmaker: return "1 × 20"
        }
    }
}

struct QuickStatsView: View {
    let profile: UserProfile
    let nextLift: MainLift
    let workoutSessions: [WorkoutSession]
    @Binding var showLiftPicker: Bool

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                let bestE1RM = workoutSessions.filter { $0.mainLift == nextLift && $0.isCompleted }.map { $0.estimated1RM }.max() ?? 0
                if bestE1RM > 0 {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("BEST E1RM")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(.secondary)
                        Text("\(String(format: "%.1f", bestE1RM))")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.yellow)
                    }
                }
                if let lastDate = workoutSessions.first?.date {
                    let days = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
                    Text(days == 0 ? "TRAINED TODAY" : days == 1 ? "1 DAY AGO" : "\(days) DAYS AGO")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(days > 3 ? .orange : .secondary)
                }
            }
            .padding(.horizontal, 4)
            Spacer()
            Button(action: { showLiftPicker = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("CHANGE")
                }
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 24)
    }
}

struct EmptyStateView: View {
    @Binding var showOnboarding: Bool
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange.gradient)
            Text("IronFive")
                .font(.system(.title3, design: .rounded, weight: .black))
            Button("Get Started") { showOnboarding = true }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }
}

struct PreviewRow: View {
    let icon: String
    let label: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
                .frame(width: 12)

            Text(label)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()

            Text(detail)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

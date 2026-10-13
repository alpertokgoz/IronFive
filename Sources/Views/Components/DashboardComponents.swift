import SwiftUI
import SwiftData

struct DashboardHeader: View {
    let profile: UserProfile
    var compact = false

    var body: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 1) {
                IronEyebrow(text: "IronFive", color: IronTheme.mint)
                Text(compact ? "C\(profile.currentCycle) · W\(profile.currentWeek)" : "Cycle \(profile.currentCycle) · \(IronTheme.week(profile.currentWeek))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 2)
            NavigationLink(destination: HistoryView()) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 34)
                    .background(.white.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Workout history")
            NavigationLink(destination: SettingsView()) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 34)
                    .background(.white.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Training settings")
        }
    }
}

struct WeeklyProgressDots: View {
    let profile: UserProfile
    let workoutSessions: [WorkoutSession]
    var activeLift: MainLift?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainLift.allCases, id: \.self) { lift in
                let completed = workoutSessions.contains {
                    $0.mainLift == lift && $0.week == profile.currentWeek &&
                    $0.cycle == profile.currentCycle && $0.isCompleted
                }
                HStack(spacing: 3) {
                    if completed { Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)) }
                    Text(lift.shortName).font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(completed ? Color.black : (lift == activeLift ? lift.color : Color.secondary))
                .frame(maxWidth: .infinity, minHeight: 22)
                .background(completed ? lift.color : lift.color.opacity(lift == activeLift ? 0.15 : 0.04), in: Capsule())
                .overlay { Capsule().strokeBorder(lift == activeLift ? lift.color.opacity(0.6) : .clear, lineWidth: 1) }
                .accessibilityLabel("\(lift.name), \(completed ? "complete" : lift == activeLift ? "next" : "upcoming")")
            }
        }
    }
}

struct MainGlanceableCard: View {
    let nextLift: MainLift
    let profile: UserProfile
    var isResuming: Bool = false
    var compact = false
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: nextLift.symbolName)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(nextLift.color)
                    .frame(width: 35)
                VStack(alignment: .leading, spacing: 3) {
                    if !compact {
                        IronEyebrow(text: isResuming ? "In progress" : "Next lift", color: nextLift.color)
                    }
                    Text(nextLift.name)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text("TM \(IronTheme.weight(WorkoutCalculator.getTM(for: nextLift, from: profile))) \(profile.weightUnit.label)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(9)
            .modifier(IronCard(accent: nextLift.color))

            Button(action: onStart) {
                HStack {
                    Text(isResuming ? "Resume workout" : "Start workout")
                    Spacer()
                    Image(systemName: isResuming ? "arrow.clockwise" : "arrow.right")
                }
                .padding(.horizontal, 12)
            }
            .buttonStyle(IronButtonStyle(accent: nextLift.color))

        }
    }
}

struct WorkoutPreviewCard: View {
    let profile: UserProfile
    let nextLift: MainLift
    let accessories: [AccessoryExercise]
    var compact = false

    var body: some View {
        VStack(spacing: 5) {
            PreviewRow(icon: "flame", label: "Warm-up", detail: "3 sets", color: nextLift.color)
            PreviewRow(icon: "bolt", label: "Main lift", detail: profile.currentWeek == 4 ? "3 easy sets" : "3 sets · AMRAP", color: nextLift.color)
            if profile.currentWeek != 4 {
                PreviewRow(icon: "repeat", label: profile.selectedTemplate.shortName, detail: supplementalDetail, color: nextLift.color)
            }
            let count = accessories.filter { $0.relatedLift == nextLift }.count
            if count > 0 {
                PreviewRow(icon: "dumbbell", label: "Assistance", detail: "\(count) moves", color: nextLift.color)
            }
        }
        .padding(compact ? 8 : 10)
        .modifier(IronCard(accent: nextLift.color))
    }

    private var supplementalDetail: String {
        switch profile.selectedTemplate {
        case .fsl, .ssl: return "5 × 5"
        case .bbb: return "5 × 10"
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
    var compact = false
    var canChangeLift = true

    private var liftSessions: [WorkoutSession] {
        workoutSessions.filter { $0.mainLift == nextLift && $0.isCompleted }
    }

    var body: some View {
        VStack(spacing: 6) {
            if compact {
                HStack {
                    IronEyebrow(text: "Best e1RM")
                    Spacer(minLength: 3)
                    Text(liftSessions.map { $0.estimated1RM }.max().map { IronTheme.estimate($0) } ?? "—")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(nextLift.color)
                    Text(profile.weightUnit.label).font(.system(size: 10)).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            } else {
            HStack(spacing: 8) {
                IronMetric(title: "Best e1RM", value: liftSessions.map { $0.estimated1RM }.max().map { IronTheme.estimate($0) } ?? "—", unit: profile.weightUnit.label, accent: nextLift.color)
                IronMetric(title: "Sessions", value: "\(liftSessions.count)")
            }
            .padding(.horizontal, 4)
            }
            Button { showLiftPicker = true } label: {
                Label(canChangeLift ? "Change lift" : "Lift locked", systemImage: canChangeLift ? "arrow.triangle.2.circlepath" : "lock.fill")
            }
            .buttonStyle(IronButtonStyle(secondary: true))
            .disabled(!canChangeLift)
            .accessibilityHint(canChangeLift ? "Choose your next lift" : "Finish your saved workout before changing lift")
        }
    }
}

struct EmptyStateView: View {
    @Binding var showOnboarding: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(IronTheme.ember)
            Text("Built for strength.")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
            Text("Your 5/3/1 training, right on your wrist.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Set up training") { showOnboarding = true }
                .buttonStyle(IronButtonStyle())
        }
        .padding(.horizontal, 8)
    }
}

struct PreviewRow: View {
    let icon: String
    let label: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color).frame(width: 15)
            Text(label).foregroundStyle(.secondary)
            Spacer(minLength: 3)
            Text(detail).fontWeight(.semibold)
        }
        .font(.system(size: 11, design: .rounded))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .accessibilityElement(children: .combine)
    }
}

import SwiftUI
import UserNotifications
import WatchKit

extension WorkoutActiveView {
    var nextRestSet: String {
        guard let index = restCountdown.stepIndex, steps.indices.contains(index + 1) else {
            return "Workout summary"
        }
        let next = steps[index + 1]
        return "\(IronTheme.weight(next.workoutSet.weight)) \(profile.weightUnit.label) × \(next.workoutSet.reps)"
    }

    func startRestTimer() {
        guard steps.indices.contains(selectedTab), !restCountdown.isActive else { return }
        let duration: Int
        switch steps[selectedTab].workoutSet.type {
        case .warmup, .accessory: duration = 60
        case .main: duration = 180
        case .supplemental: duration = 90
        }
        restCountdown.start(seconds: duration, stepIndex: selectedTab)
        saveActiveSession()
        scheduleRestNotification()
        WKInterfaceDevice.current().play(.start)
        resumeRestTimer()
    }

    func resumeRestTimer() {
        timer?.invalidate()
        timer = nil
        guard restCountdown.isActive else { showRestTimer = false; return }
        restTimeRemaining = restCountdown.remaining()
        if restTimeRemaining == 0 {
            completeRestTimer()
            return
        }
        showRestTimer = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            guard restCountdown.isActive else { return }
            let remaining = restCountdown.remaining()
            if remaining < restTimeRemaining && remaining > 0 && remaining <= 3 {
                WKInterfaceDevice.current().play(.directionUp)
            }
            restTimeRemaining = remaining
            if remaining == 0 { completeRestTimer() }
        }
    }

    func adjustRestTimer(_ seconds: Int) {
        restCountdown.adjust(by: seconds)
        restTimeRemaining = restCountdown.remaining()
        saveActiveSession()
        scheduleRestNotification()
    }

    func completeRestTimer() {
        guard let restedIndex = restCountdown.finish() else { return }
        stopRestTimer()
        // A native page swipe may already have moved away from the rested set.
        if selectedTab == restedIndex { advanceTab() }
        saveActiveSession()
        WKInterfaceDevice.current().play(.success)
    }

    func stopRestTimer() {
        timer?.invalidate()
        timer = nil
        _ = restCountdown.finish()
        showRestTimer = false
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
    }

    private func scheduleRestNotification() {
        guard !DesignPreview.isEnabled else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["restTimer"])
        guard restCountdown.isActive else { return }
        let content = UNMutableNotificationContent()
        content.title = "Rest Over"
        content.body = "Back to the bar!"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(max(1, restCountdown.remaining())), repeats: false
        )
        let request = UNNotificationRequest(identifier: "restTimer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

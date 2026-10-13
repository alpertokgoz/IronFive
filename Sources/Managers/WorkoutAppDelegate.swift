import WatchKit

final class WorkoutAppDelegate: NSObject, WKApplicationDelegate {
    func handleActiveWorkoutRecovery() {
        DispatchQueue.main.async {
            WorkoutManager.shared.recoverWorkout()
        }
    }
}

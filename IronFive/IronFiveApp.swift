import SwiftUI
import SwiftData

@main
struct IronFiveApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(workoutManager)
                .modelContainer(for: [UserProfile.self, AccessoryExercise.self, WorkoutSession.self])
        }
    }
}

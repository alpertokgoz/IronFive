import SwiftUI
import SwiftData

@main
struct IronFiveApp: App {
    @State private var workoutManager = WorkoutManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            AccessoryExercise.self,
            WorkoutSession.self,
            ActiveWorkoutSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, migrationPlan: IronFiveMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(workoutManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

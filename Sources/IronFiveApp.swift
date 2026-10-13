import SwiftUI
import SwiftData
import WatchKit

@main
struct IronFiveApp: App {
    @WKApplicationDelegateAdaptor(WorkoutAppDelegate.self) private var appDelegate
    @State private var workoutManager = WorkoutManager.shared

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            AccessoryExercise.self,
            WorkoutSession.self,
            ActiveWorkoutSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: DesignPreview.isEnabled, cloudKitDatabase: DesignPreview.isEnabled ? .none : .automatic)

        do {
            let container = try ModelContainer(for: schema, migrationPlan: IronFiveMigrationPlan.self, configurations: [modelConfiguration])
            #if DEBUG
            if DesignPreview.isEnabled { DesignPreview.seed(container) }
            #endif
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if DesignPreview.isEnabled {
                    DesignPreviewLaunchView()
                } else {
                    DashboardView()
                }
                #else
                DashboardView()
                #endif
            }
            .environment(workoutManager)
        }
        .modelContainer(sharedModelContainer)
    }
}

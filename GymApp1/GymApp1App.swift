import SwiftUI
import SwiftData

@main
struct GymApp1App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodEntry.self,
            MacroGoals.self,
            WorkoutTemplate.self,
            WorkoutLog.self,
            ExerciseLog.self,
            SetLog.self,
            WeightEntry.self,
            ProgressPhoto.self,
            UserProfile.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            secureStoreFile(for: modelConfiguration)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    /// Applies iOS Data Protection so the local database file is encrypted
    /// at rest and inaccessible while the device is locked.
    private static func secureStoreFile(for configuration: ModelConfiguration) {
        let storeURL = configuration.url
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: storeURL.path
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

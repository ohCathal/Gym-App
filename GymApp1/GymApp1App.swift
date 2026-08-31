//  GymApp1App.swift
//  GymApp1
//
//  Created by Cathal Davitt on 26/06/2026.
//

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
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}

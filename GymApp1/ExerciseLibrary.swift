import SwiftUI

enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case glutes = "Glutes"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rower"
        case .shoulders: return "figure.arms.open"
        case .biceps, .triceps: return "dumbbell.fill"
        case .legs: return "figure.squat"
        case .glutes: return "figure.strengthtraining.functional"
        case .core: return "figure.core.training"
        case .cardio: return "figure.run"
        case .fullBody: return "figure.mixed.cardio"
        }
    }

    var color: Color {
        switch self {
        case .chest, .triceps, .cardio: return .accentFat
        case .back, .legs, .fullBody: return .accentProtein
        case .shoulders, .glutes: return .accentCarbs
        case .biceps, .core: return .accentPrimary
        }
    }
}

struct ExerciseDefinition: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let muscleGroup: MuscleGroup
}

enum ExerciseLibrary {
    static let all: [ExerciseDefinition] = [
        // Chest
        .init(name: "Bench Press", muscleGroup: .chest),
        .init(name: "Incline Bench Press", muscleGroup: .chest),
        .init(name: "Dumbbell Fly", muscleGroup: .chest),
        .init(name: "Push-Up", muscleGroup: .chest),
        .init(name: "Chest Dip", muscleGroup: .chest),

        // Back
        .init(name: "Deadlift", muscleGroup: .back),
        .init(name: "Pull-Up", muscleGroup: .back),
        .init(name: "Lat Pulldown", muscleGroup: .back),
        .init(name: "Bent-Over Row", muscleGroup: .back),
        .init(name: "Seated Cable Row", muscleGroup: .back),
        .init(name: "T-Bar Row", muscleGroup: .back),

        // Shoulders
        .init(name: "Overhead Press", muscleGroup: .shoulders),
        .init(name: "Lateral Raise", muscleGroup: .shoulders),
        .init(name: "Front Raise", muscleGroup: .shoulders),
        .init(name: "Face Pull", muscleGroup: .shoulders),
        .init(name: "Arnold Press", muscleGroup: .shoulders),

        // Biceps
        .init(name: "Barbell Curl", muscleGroup: .biceps),
        .init(name: "Dumbbell Curl", muscleGroup: .biceps),
        .init(name: "Hammer Curl", muscleGroup: .biceps),
        .init(name: "Preacher Curl", muscleGroup: .biceps),

        // Triceps
        .init(name: "Tricep Pushdown", muscleGroup: .triceps),
        .init(name: "Skull Crusher", muscleGroup: .triceps),
        .init(name: "Overhead Tricep Extension", muscleGroup: .triceps),
        .init(name: "Close-Grip Bench Press", muscleGroup: .triceps),

        // Legs
        .init(name: "Squat", muscleGroup: .legs),
        .init(name: "Leg Press", muscleGroup: .legs),
        .init(name: "Lunge", muscleGroup: .legs),
        .init(name: "Leg Extension", muscleGroup: .legs),
        .init(name: "Leg Curl", muscleGroup: .legs),
        .init(name: "Calf Raise", muscleGroup: .legs),
        .init(name: "Romanian Deadlift", muscleGroup: .legs),
        .init(name: "Bulgarian Split Squat", muscleGroup: .legs),

        // Glutes
        .init(name: "Hip Thrust", muscleGroup: .glutes),
        .init(name: "Glute Bridge", muscleGroup: .glutes),
        .init(name: "Cable Kickback", muscleGroup: .glutes),

        // Core
        .init(name: "Plank", muscleGroup: .core),
        .init(name: "Crunch", muscleGroup: .core),
        .init(name: "Russian Twist", muscleGroup: .core),
        .init(name: "Hanging Leg Raise", muscleGroup: .core),
        .init(name: "Sit-Up", muscleGroup: .core),

        // Cardio
        .init(name: "Running", muscleGroup: .cardio),
        .init(name: "Cycling", muscleGroup: .cardio),
        .init(name: "Rowing Machine", muscleGroup: .cardio),
        .init(name: "Jump Rope", muscleGroup: .cardio),

        // Full Body
        .init(name: "Burpee", muscleGroup: .fullBody),
        .init(name: "Kettlebell Swing", muscleGroup: .fullBody),
        .init(name: "Thruster", muscleGroup: .fullBody),
    ]

    static func grouped() -> [(MuscleGroup, [ExerciseDefinition])] {
        MuscleGroup.allCases.map { group in
            (group, all.filter { $0.muscleGroup == group })
        }
    }
}

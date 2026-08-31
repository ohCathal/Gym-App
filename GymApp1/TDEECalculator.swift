import Foundation

enum BiologicalSexOption: String, CaseIterable {
    case male = "Male"
    case female = "Female"
}

enum ActivityLevel: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case light = "Light"
    case moderate = "Moderate"
    case active = "Active"
    case veryActive = "Very Active"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .sedentary: return "Little or no exercise"
        case .light: return "Exercise 1–3 days/week"
        case .moderate: return "Exercise 3–5 days/week"
        case .active: return "Exercise 6–7 days/week"
        case .veryActive: return "Hard exercise + physical job"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

enum MacroSplit: String, CaseIterable {
    case balanced = "Balanced"
    case highProtein = "High Protein"
    case lowCarb = "Low Carb"

    var percentages: (protein: Double, carbs: Double, fat: Double) {
        switch self {
        case .balanced: return (0.30, 0.40, 0.30)
        case .highProtein: return (0.40, 0.30, 0.30)
        case .lowCarb: return (0.35, 0.25, 0.40)
        }
    }
}

enum TDEECalculator {
    static func bmr(sex: BiologicalSexOption, weightKg: Double, heightCm: Double, age: Int) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return sex == .male ? base + 5 : base - 161
    }

    static func tdee(bmr: Double, activity: ActivityLevel) -> Double {
        bmr * activity.multiplier
    }

    static func macroGrams(calories: Double, split: MacroSplit) -> (protein: Double, carbs: Double, fat: Double) {
        let pct = split.percentages
        return (
            protein: (calories * pct.protein) / 4,
            carbs: (calories * pct.carbs) / 4,
            fat: (calories * pct.fat) / 9
        )
    }
}

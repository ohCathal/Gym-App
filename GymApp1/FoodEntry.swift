import Foundation
import SwiftData

@Model
final class FoodEntry {
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var timestamp: Date
    var grams: Double

    init(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, timestamp: Date = .now, grams: Double = 100) {
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.timestamp = timestamp
        self.grams = grams
    }
}
@Model
final class MacroGoals {
    var calorieGoal: Double
    var proteinGoal: Double
    var carbGoal: Double
    var fatGoal: Double

    init(calorieGoal: Double = 2000, proteinGoal: Double = 150, carbGoal: Double = 200, fatGoal: Double = 65) {
        self.calorieGoal = calorieGoal
        self.proteinGoal = proteinGoal
        self.carbGoal = carbGoal
        self.fatGoal = fatGoal
    }
}

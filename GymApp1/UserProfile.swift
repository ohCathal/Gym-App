import Foundation
import SwiftData

@Model
final class UserProfile {
    var age: Int
    var heightCm: Double
    var weightKg: Double

    init(age: Int = 25, heightCm: Double = 170, weightKg: Double = 70) {
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
    }
}

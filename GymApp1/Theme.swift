import SwiftUI

extension Color {
    static let bgPrimary = Color(red: 0.020, green: 0.027, blue: 0.051)
    static let bgSurface = Color(red: 0.055, green: 0.082, blue: 0.141)
    static let textPrimary = Color(red: 0.918, green: 0.953, blue: 1.0)
    static let textSecondary = Color(red: 0.424, green: 0.478, blue: 0.580)

    // Hero accent — calorie gauge, "tap to log", primary UI accent
    static let accentPrimary = Color(red: 0.302, green: 0.847, blue: 1.0)   // bright cyan

    // Macro family — blue → indigo → violet, so the ring reads as one holographic sweep
    static let accentProtein = Color(red: 0.239, green: 0.663, blue: 0.988) // sky blue
    static let accentCarbs = Color(red: 0.357, green: 0.498, blue: 1.0)    // blue
    static let accentFat = Color(red: 0.545, green: 0.420, blue: 1.0)      // indigo/violet
}

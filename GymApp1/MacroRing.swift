import SwiftUI

struct MacroGauge: View {
    var overallProgress: Double
    var proteinCals: Double
    var carbsCals: Double
    var fatCals: Double
    var lineWidth: CGFloat = 20

    private var clampedOverall: Double {
        min(max(overallProgress.isNaN ? 0 : overallProgress, 0), 1)
    }

    private var totalCals: Double {
        max(proteinCals + carbsCals + fatCals, 0.001)
    }

    private var proteinFrac: Double { proteinCals / totalCals }
    private var carbsFrac: Double { carbsCals / totalCals }
    private var fatFrac: Double { fatCals / totalCals }

    private let sweep: Double = 0.75 // 270° arc

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: sweep)
                .stroke(Color.bgSurface, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(135))

            segment(from: 0, fraction: proteinFrac, color: .accentProtein)
            segment(from: proteinFrac, fraction: carbsFrac, color: .accentCarbs)
            segment(from: proteinFrac + carbsFrac, fraction: fatFrac, color: .accentFat)
        }
        .animation(.easeInOut(duration: 0.5), value: clampedOverall)
    }

    private func segment(from startFrac: Double, fraction: Double, color: Color) -> some View {
        let filled = sweep * clampedOverall
        let start = filled * startFrac
        let end = min(filled * (startFrac + fraction), filled)

        let holographicGradient = AngularGradient(
            gradient: Gradient(colors: [
                color.opacity(0.75),
                color,
                Color.white.opacity(0.7),
                color
            ]),
            center: .center
        )

        return Circle()
            .trim(from: start, to: max(start, end))
            .stroke(holographicGradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            .rotationEffect(.degrees(135))
            .shadow(color: color.opacity(0.6), radius: 6)
    }
}


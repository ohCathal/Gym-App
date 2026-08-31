import SwiftUI

struct BodyAvatarView: View {
    var heightCm: Double
    var weightKg: Double

    @State private var breathe = false

    private var heightScale: CGFloat {
        let raw = heightCm / 170.0
        return CGFloat(min(max(raw, 0.85), 1.18))
    }

    private var widthScale: CGFloat {
        let bmiLike = weightKg / pow(heightCm / 100, 2)
        let raw = bmiLike / 22.0
        return CGFloat(min(max(raw, 0.8), 1.35))
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentPrimary.opacity(0.15))
                .frame(width: 160, height: 160)
                .blur(radius: 20)
                .scaleEffect(breathe ? 1.08 : 0.94)
                .opacity(breathe ? 0.9 : 0.6)

            Image(systemName: "figure.stand")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentPrimary, Color.accentPrimary.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 90, height: 170)
                .scaleEffect(x: widthScale, y: heightScale * (breathe ? 1.015 : 1.0), anchor: .bottom)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: heightCm)
        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: weightKg)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                breathe = true
            }
        }
    }
}

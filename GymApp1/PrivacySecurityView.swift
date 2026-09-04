import SwiftUI

struct PrivacySecurityView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PRIVACY & SECURITY")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(Color.accentPrimary)
                            Text("Your Data")
                                .font(.system(size: 26, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(.top, 8)

                        section(
                            icon: "iphone",
                            title: "Stored on your device",
                            body: "Your food log, workouts, weight history, and goals are stored locally on this device only. Nothing is uploaded to a server or shared with us."
                        )

                        section(
                            icon: "lock.fill",
                            title: "Encrypted at rest",
                            body: "Your local database uses iOS's strongest Data Protection level, meaning it's fully encrypted and inaccessible whenever your device is locked."
                        )

                        section(
                            icon: "heart.fill",
                            title: "Health data",
                            body: "Steps, weight, height, and age are read from Apple Health only with your explicit permission. This data never leaves your device."
                        )

                        section(
                            icon: "network",
                            title: "Food lookups",
                            body: "When you search for a food, only the search term is sent to Open Food Facts (an open, non-profit food database) to find matching results. No personal or health information is included in that request."
                        )

                        section(
                            icon: "camera.fill",
                            title: "Camera access",
                            body: "The camera is used only to scan barcodes when you choose to. No images are stored or transmitted."
                        )

                        section(
                            icon: "person.fill.xmark",
                            title: "No accounts yet",
                            body: "This app doesn't currently store passwords or account credentials. If sign-in is added in the future, it will use Sign in with Apple rather than storing passwords directly."
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func section(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.accentPrimary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(body)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgSurface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
}

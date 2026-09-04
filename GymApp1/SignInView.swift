import SwiftUI
import AuthenticationServices

struct SignInView: View {
    var auth: AuthManager

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentPrimary)

                    VStack(spacing: 6) {
                        Text("WELCOME")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(1.4)
                            .foregroundStyle(Color.accentPrimary)
                        Text("Your Fitness,\nTracked Simply")
                            .font(.system(size: 30, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                VStack(spacing: 14) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName]
                    } onCompletion: { result in
                        auth.handleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)

                    Button {
                        auth.continueAsGuest()
                    } label: {
                        Text("Continue Without Signing In")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.top, 4)

                    Text("Your data stays private and stored only on this device.")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundLayer: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            Circle()
                .fill(Color.accentPrimary.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 100)
                .offset(x: -100, y: -220)
            Circle()
                .fill(Color.accentProtein.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 100)
                .offset(x: 120, y: 260)
        }
    }
}

import SwiftUI

struct RootView: View {
    @State private var selected: AppTab = .macros
    @State private var auth = AuthManager()

    var body: some View {
        Group {
            if auth.isSignedIn {
                ZStack(alignment: .bottom) {
                    Group {
                        switch selected {
                        case .macros:
                            ContentView()
                        case .workouts:
                            WorkoutsView()
                        case .progress:
                            ProgressTrackerView()
                        case .profile:
                            ProfileView()
                        }
                    }

                    FloatingTabBar(selected: $selected)
                        .padding(.bottom, 12)
                }
            } else {
                SignInView(auth: auth)
            }
        }
        .environment(auth)
        .preferredColorScheme(.dark)
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            Text("\(title) — coming soon")
                .foregroundStyle(Color.textSecondary)
        }
    }
}

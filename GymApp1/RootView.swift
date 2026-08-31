import SwiftUI

struct RootView: View {
    @State private var selected: AppTab = .macros

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selected {
                case .macros:
                    ContentView()
                case .workouts:
                    WorkoutsView()
                case .progress:
                    PlaceholderView(title: "Progress")
                case .profile:
                    ProfileView()
                }
            }

            FloatingTabBar(selected: $selected)
                .padding(.bottom, 12)
        }
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

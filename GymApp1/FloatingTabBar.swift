import SwiftUI

enum AppTab: Int, CaseIterable {
    case macros, workouts, progress, profile

    var icon: String {
        switch self {
        case .macros: return "flame.fill"
        case .workouts: return "dumbbell.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .profile: return "person.fill"
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selected: AppTab

    var body: some View {
        HStack(spacing: 32) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selected = tab
                } label: {
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selected == tab ? Color.accentPrimary : Color.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 20)
        .background(
            Capsule()
                .fill(Color.black)
                .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
    }
}

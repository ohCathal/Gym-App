import SwiftUI

struct ExerciseLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: ((ExerciseDefinition) -> Void)? = nil

    @State private var query = ""
    @State private var customName = ""

    private var filteredGroups: [(MuscleGroup, [ExerciseDefinition])] {
        let groups = ExerciseLibrary.grouped()
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return groups }
        return groups.compactMap { group, exercises in
            let matches = exercises.filter { $0.name.localizedCaseInsensitiveContains(query) }
            return matches.isEmpty ? nil : (group, matches)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(onSelect != nil ? "ADD TO SESSION" : "REFERENCE")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(Color.accentPrimary)
                            Text(onSelect != nil ? "Add Exercise" : "Exercise Library")
                                .font(.system(size: 24, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.textSecondary)
                            TextField("Search exercises", text: $query)
                                .foregroundStyle(Color.textPrimary)
                                .autocorrectionDisabled()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.bgSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )

                        if onSelect != nil {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.pencil")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.accentPrimary.opacity(0.8))
                                TextField("Or type a custom exercise", text: $customName)
                                    .foregroundStyle(Color.textPrimary)
                                Button {
                                    let trimmed = customName.trimmingCharacters(in: .whitespaces)
                                    guard !trimmed.isEmpty else { return }
                                    onSelect?(ExerciseDefinition(name: trimmed, muscleGroup: .fullBody))
                                    dismiss()
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Color.accentPrimary)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentPrimary.opacity(0.08))
                            )
                        }

                        ForEach(filteredGroups, id: \.0) { group, exercises in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    ZStack {
                                        Circle()
                                            .fill(group.color.opacity(0.15))
                                            .frame(width: 24, height: 24)
                                        Image(systemName: group.icon)
                                            .font(.system(size: 10))
                                            .foregroundStyle(group.color)
                                    }
                                    Text(group.rawValue.uppercased())
                                        .font(.system(size: 11, weight: .semibold))
                                        .tracking(0.8)
                                        .foregroundStyle(Color.textSecondary)
                                }

                                VStack(spacing: 8) {
                                    ForEach(exercises) { exercise in
                                        exerciseRow(exercise, groupColor: group.color)
                                    }
                                }
                            }
                        }
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

    private var backgroundLayer: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            Circle()
                .fill(Color.accentCarbs.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 90)
                .offset(x: 100, y: -120)
        }
    }

    private func exerciseRow(_ exercise: ExerciseDefinition, groupColor: Color) -> some View {
        Button {
            onSelect?(exercise)
            if onSelect != nil { dismiss() }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(groupColor)
                    .frame(width: 6, height: 6)
                Text(exercise.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if onSelect == nil {
                    Text(exercise.muscleGroup.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(groupColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(groupColor.opacity(0.12)))
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgSurface.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

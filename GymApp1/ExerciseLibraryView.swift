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
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.textSecondary)
                            TextField("Search exercises", text: $query)
                                .foregroundStyle(Color.textPrimary)
                                .autocorrectionDisabled()
                        }
                        .padding(12)
                        .background(Color.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if onSelect != nil {
                            HStack(spacing: 10) {
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
                            .background(Color.bgSurface.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        ForEach(filteredGroups, id: \.0) { group, exercises in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 6) {
                                    Image(systemName: group.icon)
                                        .font(.system(size: 12))
                                        .foregroundStyle(group.color)
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
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle(onSelect != nil ? "Add Exercise" : "Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func exerciseRow(_ exercise: ExerciseDefinition, groupColor: Color) -> some View {
        Button {
            onSelect?(exercise)
            if onSelect != nil { dismiss() }
        } label: {
            HStack(spacing: 12) {
                Text(exercise.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                if onSelect == nil {
                    Text(exercise.muscleGroup.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(groupColor)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.bgSurface.opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }
}

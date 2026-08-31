import SwiftUI
import SwiftData

private struct DraftSet: Identifiable {
    let id = UUID()
    var reps: Int
    var weight: Double
}

private struct DraftExercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: [DraftSet] = []
}

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var workoutName = ""
    @State private var exercises: [DraftExercise] = []
    @State private var showingPicker = false

    private var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("NEW SESSION")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(Color.accentPrimary)
                            TextField("Workout name (e.g. Push Day)", text: $workoutName)
                                .font(.system(size: 26, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.textPrimary)
                                .tint(Color.accentPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                        if totalSets > 0 {
                            HStack(spacing: 10) {
                                miniStat(icon: "list.bullet", value: "\(exercises.count)", label: "EXERCISES", color: .accentProtein)
                                miniStat(icon: "checkmark.circle.fill", value: "\(totalSets)", label: "SETS LOGGED", color: .accentPrimary)
                            }
                        }

                        if exercises.isEmpty {
                            emptyState
                        } else {
                            ForEach($exercises) { $exercise in
                                exerciseCard($exercise)
                            }
                        }

                        Button {
                            showingPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Exercise")
                            }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.accentPrimary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.accentPrimary.opacity(0.25), lineWidth: 1)
                                    )
                            )
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
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") { finish() }
                        .fontWeight(.semibold)
                        .foregroundStyle(exercises.isEmpty || totalSets == 0 ? Color.textSecondary : Color.accentPrimary)
                        .disabled(exercises.isEmpty || totalSets == 0)
                }
            }
            .sheet(isPresented: $showingPicker) {
                ExerciseLibraryView { definition in
                    exercises.append(DraftExercise(name: definition.name))
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            Circle()
                .fill(Color.accentPrimary.opacity(0.14))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -110, y: -150)
            Circle()
                .fill(Color.accentProtein.opacity(0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 90)
                .offset(x: 120, y: 100)
        }
    }

    private func miniStat(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(color.opacity(0.1))
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell")
                .font(.system(size: 30))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            Text("Add your first exercise to get started")
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Exercise Card

    private func exerciseCard(_ exercise: Binding<DraftExercise>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.accentProtein.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentProtein)
                }
                Text(exercise.wrappedValue.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button {
                    exercises.removeAll { $0.id == exercise.wrappedValue.id }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.textSecondary.opacity(0.6))
                }
            }

            if !exercise.wrappedValue.sets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(exercise.wrappedValue.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("SET \(index + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(0.4)
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 56, alignment: .leading)
                            Text("\(set.reps) reps")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text("\(String(format: "%.1f", set.weight)) kg")
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.accentPrimary)
                            Button {
                                exercise.wrappedValue.sets.removeAll { $0.id == set.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.red.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.bgPrimary.opacity(0.5))
                        )
                    }
                }
            }

            AddSetRow { reps, weight in
                exercise.wrappedValue.sets.append(DraftSet(reps: reps, weight: weight))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func finish() {
        let log = WorkoutLog(
            name: workoutName.trimmingCharacters(in: .whitespaces).isEmpty ? "Workout" : workoutName,
            exercises: exercises.compactMap { draft in
                guard !draft.sets.isEmpty else { return nil }
                return ExerciseLog(
                    name: draft.name,
                    sets: draft.sets.map { SetLog(reps: $0.reps, weight: $0.weight) }
                )
            }
        )
        modelContext.insert(log)
        dismiss()
    }
}

private struct AddSetRow: View {
    var onAdd: (Int, Double) -> Void

    @State private var repsText = ""
    @State private var weightText = ""

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "repeat")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                TextField("Reps", text: $repsText)
                    .keyboardType(.numberPad)
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgPrimary.opacity(0.6)))

            HStack(spacing: 6) {
                Image(systemName: "scalemass")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                TextField("Weight (kg)", text: $weightText)
                    .keyboardType(.decimalPad)
                    .foregroundStyle(Color.textPrimary)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgPrimary.opacity(0.6)))

            Button {
                guard let reps = Int(repsText), let weight = Double(weightText) else { return }
                onAdd(reps, weight)
                repsText = ""
                weightText = ""
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(Color.accentPrimary)
            }
        }
    }
}

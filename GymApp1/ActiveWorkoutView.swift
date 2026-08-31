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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        TextField("Workout name (e.g. Push Day)", text: $workoutName)
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.top, 8)

                        if exercises.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 30))
                                    .foregroundStyle(Color.textSecondary.opacity(0.5))
                                Text("Add your first exercise to get started")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 50)
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
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") { finish() }
                        .disabled(exercises.isEmpty || exercises.allSatisfy { $0.sets.isEmpty })
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

    private func exerciseCard(_ exercise: Binding<DraftExercise>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(exercise.wrappedValue.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Button {
                    exercises.removeAll { $0.id == exercise.wrappedValue.id }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.textSecondary)
                }
            }

            if !exercise.wrappedValue.sets.isEmpty {
                VStack(spacing: 6) {
                    ForEach(Array(exercise.wrappedValue.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                                .frame(width: 50, alignment: .leading)
                            Text("\(set.reps) reps")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Text("\(String(format: "%.1f", set.weight)) kg")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundStyle(Color.textPrimary)
                            Button {
                                exercise.wrappedValue.sets.removeAll { $0.id == set.id }
                            } label: {
                                Image(systemName: "minus.circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.red.opacity(0.7))
                            }
                        }
                    }
                }
            }

            AddSetRow { reps, weight in
                exercise.wrappedValue.sets.append(DraftSet(reps: reps, weight: weight))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
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
            TextField("Reps", text: $repsText)
                .keyboardType(.numberPad)
                .foregroundStyle(Color.textPrimary)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgPrimary))

            TextField("Weight (kg)", text: $weightText)
                .keyboardType(.decimalPad)
                .foregroundStyle(Color.textPrimary)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgPrimary))

            Button {
                guard let reps = Int(repsText), let weight = Double(weightText) else { return }
                onAdd(reps, weight)
                repsText = ""
                weightText = ""
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.accentPrimary)
            }
        }
    }
}

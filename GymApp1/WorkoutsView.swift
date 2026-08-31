import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutLog.date, order: .reverse) private var logs: [WorkoutLog]

    @State private var showingActiveWorkout = false
    @State private var showingLibrary = false

    private var thisWeekCount: Int {
        let calendar = Calendar.current
        return logs.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.count
    }

    private var totalSetsAllTime: Int {
        logs.reduce(0) { $0 + $1.exercises.reduce(0) { $0 + $1.sets.count } }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("WORKOUTS")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(Color.accentPrimary)
                            Text("Train Today")
                                .font(.system(size: 30, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)

                        if !logs.isEmpty {
                            statsRow
                        }

                        Button {
                            showingActiveWorkout = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.bgPrimary.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "plus")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundStyle(Color.bgPrimary)
                                }
                                Text("Start Workout")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(Color.bgPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.accentPrimary.opacity(0.35), radius: 16, y: 8)
                        }

                        Button {
                            showingLibrary = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentCarbs.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.accentCarbs)
                                }
                                Text("Browse Exercise Library")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.bgSurface.opacity(0.7))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                    )
                            )
                        }

                        if logs.isEmpty {
                            emptyState
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("HISTORY")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.8)
                                    .foregroundStyle(Color.textSecondary)
                                    .padding(.leading, 4)

                                VStack(spacing: 10) {
                                    ForEach(logs) { log in
                                        workoutRow(log)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 110)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingActiveWorkout) {
                ActiveWorkoutView()
            }
            .sheet(isPresented: $showingLibrary) {
                ExerciseLibraryView()
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            Circle()
                .fill(Color.accentProtein.opacity(0.16))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 130, y: -160)

            Circle()
                .fill(Color.accentPrimary.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: -110, y: 120)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            statCard(icon: "calendar", value: "\(thisWeekCount)", label: "THIS WEEK", color: .accentPrimary)
            statCard(icon: "chart.bar.fill", value: "\(totalSetsAllTime)", label: "TOTAL SETS", color: .accentCarbs)
        }
    }

    private func statCard(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 34))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            Text("No workouts logged yet")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.textPrimary)
            Text("Tap Start Workout to log your first session")
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - History Row

    private func workoutRow(_ log: WorkoutLog) -> some View {
        let totalSets = log.exercises.reduce(0) { $0 + $1.sets.count }
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentProtein.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentProtein)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(log.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                Text("\(log.exercises.count) exercises · \(totalSets) sets")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.accentPrimary)
            }

            Spacer()

            Button {
                modelContext.delete(log)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.red)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.red.opacity(0.12)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgSurface.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                )
        )
    }
}

import SwiftUI
import SwiftData
import Charts

private struct CaloriePoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
}

private struct StepPoint: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Double
}

struct ProgressTrackerView: View {
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]
    @Query private var goalsList: [MacroGoals]
    @Query(sort: \WorkoutLog.date, order: .reverse) private var workoutLogs: [WorkoutLog]

    @State private var health = HealthKitManager()
    @State private var stepPoints: [StepPoint] = []
    @State private var weightRange: WeightRange = .week
    @State private var weightPoints: [WeightPoint] = []

    private var goals: MacroGoals {
        goalsList.first ?? MacroGoals()
    }

    private var caloriePoints: [CaloriePoint] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { offset -> CaloriePoint? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: .now) else { return nil }
            let total = allEntries
                .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
                .reduce(0) { $0 + $1.calories }
            return CaloriePoint(date: calendar.startOfDay(for: day), calories: total)
        }
    }

    private var averageCalories: Double {
        guard !caloriePoints.isEmpty else { return 0 }
        return caloriePoints.reduce(0) { $0 + $1.calories } / Double(caloriePoints.count)
    }

    private var averageSteps: Double {
        guard !stepPoints.isEmpty else { return 0 }
        return stepPoints.reduce(0) { $0 + $1.steps } / Double(stepPoints.count)
    }

    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        return workoutLogs.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .weekOfYear) }.count
    }

    private var weeklyMacroAverages: (protein: Double, carbs: Double, fat: Double) {
        let calendar = Calendar.current
        let last7 = allEntries.filter {
            guard let daysAgo = calendar.dateComponents([.day], from: $0.timestamp, to: .now).day else { return false }
            return daysAgo >= 0 && daysAgo < 7
        }
        guard !last7.isEmpty else { return (0, 0, 0) }
        let days = max(Double(Set(last7.map { calendar.startOfDay(for: $0.timestamp) }).count), 1)
        let protein = last7.reduce(0) { $0 + $1.protein } / days
        let carbs = last7.reduce(0) { $0 + $1.carbs } / days
        let fat = last7.reduce(0) { $0 + $1.fat } / days
        return (protein, carbs, fat)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        quickStatsRow
                        caloriesCard
                        stepsCard
                        weightCard
                        macroAveragesCard
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                Task {
                    await health.requestAuthorization()
                    await loadSteps()
                    await loadWeight()
                }
            }
            .onChange(of: weightRange) { _, _ in
                Task { await loadWeight() }
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            Circle()
                .fill(Color.accentPrimary.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -120, y: -170)
            Circle()
                .fill(Color.accentCarbs.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 90)
                .offset(x: 130, y: 140)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PROGRESS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color.accentPrimary)
            Text("Your Trends")
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    // MARK: - Quick Stats

    private var quickStatsRow: some View {
        HStack(spacing: 10) {
            quickStat(icon: "flame.fill", value: "\(Int(averageCalories))", label: "AVG KCAL/DAY", color: .accentPrimary)
            quickStat(icon: "figure.walk", value: "\(Int(averageSteps))", label: "AVG STEPS/DAY", color: .accentCarbs)
            quickStat(icon: "dumbbell.fill", value: "\(workoutsThisWeek)", label: "WORKOUTS/WK", color: .accentProtein)
        }
    }

    private func quickStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .tracking(0.3)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Calories Card

    private var caloriesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("CALORIES")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.textSecondary)
                Text("\(Int(averageCalories)) kcal")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("daily average, last 7 days")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
            }

            Chart {
                ForEach(caloriePoints) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Calories", point.calories)
                    )
                    .foregroundStyle(Color.accentPrimary.gradient)
                    .cornerRadius(4)
                }
                RuleMark(y: .value("Goal", goals.calorieGoal))
                    .foregroundStyle(Color.textSecondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow))
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .foregroundStyle(Color.textSecondary)
                    AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.15))
                }
            }
            .frame(height: 140)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Steps Card

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STEPS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.textSecondary)
                Text("\(Int(averageSteps))")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.textPrimary)
                Text("daily average, last 7 days")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
            }

            if stepPoints.isEmpty {
                Text("Connect Health in your Profile to see step trends here.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Chart(stepPoints) { point in
                    BarMark(
                        x: .value("Day", point.date, unit: .day),
                        y: .value("Steps", point.steps)
                    )
                    .foregroundStyle(Color.accentCarbs.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textSecondary)
                        AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.15))
                    }
                }
                .frame(height: 140)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Weight Card

    private var weightCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEIGHT")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(Color.textSecondary)
                    if let latest = weightPoints.last {
                        Text("\(String(format: "%.1f", latest.kg)) kg")
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                    } else {
                        Text("No data")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                Spacer()
                Picker("", selection: $weightRange) {
                    ForEach(WeightRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if weightPoints.isEmpty {
                Text("Log your weight in the Health app to see trends here.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                Chart(weightPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.kg)
                    )
                    .foregroundStyle(Color.accentPrimary)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Weight", point.kg)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentPrimary.opacity(0.25), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textSecondary)
                        AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.15))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(Color.textSecondary)
                        AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.15))
                    }
                }
                .frame(height: 140)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Macro Averages Card

    private var macroAveragesCard: some View {
        let averages = weeklyMacroAverages
        return VStack(alignment: .leading, spacing: 14) {
            Text("WEEKLY MACRO AVERAGE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: 10) {
                macroStat(title: "Protein", value: averages.protein, color: .accentProtein)
                macroStat(title: "Carbs", value: averages.carbs, color: .accentCarbs)
                macroStat(title: "Fat", value: averages.fat, color: .accentFat)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func macroStat(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 6) {
            Text("\(Int(value))g")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(color)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Actions

    private func loadSteps() async {
        let raw = await health.fetchDailySteps(daysBack: 7)
        stepPoints = raw.map { StepPoint(date: $0.date, steps: $0.steps) }
    }

    private func loadWeight() async {
        let samples = await health.fetchWeightSamples(daysBack: weightRange.daysBack)
        weightPoints = groupSamples(samples, for: weightRange)
    }

    private func groupSamples(_ samples: [(date: Date, kg: Double)], for range: WeightRange) -> [WeightPoint] {
        switch range {
        case .week:
            return samples.map { WeightPoint(date: $0.date, kg: $0.kg) }
        case .month:
            return averaged(samples, component: .weekOfYear)
        case .year:
            return averaged(samples, component: .month)
        }
    }

    private func averaged(_ samples: [(date: Date, kg: Double)], component: Calendar.Component) -> [WeightPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: samples) { sample -> Date in
            let comps = calendar.dateComponents(component == .weekOfYear ? [.yearForWeekOfYear, .weekOfYear] : [.year, .month], from: sample.date)
            return calendar.date(from: comps) ?? sample.date
        }
        return grouped.map { key, values in
            WeightPoint(date: key, kg: values.map { $0.kg }.reduce(0, +) / Double(values.count))
        }.sorted { $0.date < $1.date }
    }
}

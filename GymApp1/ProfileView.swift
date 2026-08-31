import SwiftUI
import SwiftData
import Charts
import HealthKit

enum WeightRange: String, CaseIterable {
    case week = "Week", month = "Month", year = "Year"

    var daysBack: Int {
        switch self {
        case .week: return 7
        case .month: return 56
        case .year: return 365
        }
    }
}

struct WeightPoint: Identifiable {
    let id = UUID()
    let date: Date
    let kg: Double
}

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goalsList: [MacroGoals]
    @State private var health = HealthKitManager()

    @State private var weightRange: WeightRange = .week
    @State private var weightPoints: [WeightPoint] = []

    // Goals editing
    @State private var calorieText = ""
    @State private var proteinText = ""
    @State private var carbText = ""
    @State private var fatText = ""

    // TDEE inputs
    @State private var tdeeAge: String = ""
    @State private var tdeeHeight: String = ""
    @State private var tdeeWeight: String = ""
    @State private var tdeeSex: BiologicalSexOption = .male
    @State private var tdeeActivity: ActivityLevel = .moderate
    @State private var showTDEEResult = false

    private var goals: MacroGoals {
        goalsList.first ?? MacroGoals()
    }

    private var currentWeight: Double? {
        weightPoints.last?.kg
    }

    private var tdeeResult: Double? {
        guard let age = Int(tdeeAge), let height = Double(tdeeHeight), let weight = Double(tdeeWeight),
              age > 0, height > 0, weight > 0 else { return nil }
        let bmr = TDEECalculator.bmr(sex: tdeeSex, weightKg: weight, heightCm: height, age: age)
        return TDEECalculator.tdee(bmr: bmr, activity: tdeeActivity)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: 16) {
                        header
                        activityCard
                        weightCard
                        goalsCard
                        tdeeCard

                        if let authError = health.authError {
                            Text(authError)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.textSecondary)
                                .padding(.horizontal)
                        } else if !health.isAuthorized {
                            Button {
                                Task { await health.requestAuthorization() }
                            } label: {
                                Text("Connect to Health")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.bgPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.accentPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                if goalsList.isEmpty { modelContext.insert(MacroGoals()) }
                loadGoalsText()
                Task {
                    await health.requestAuthorization()
                    await loadWeight()
                    prefillTDEEFromHealth()
                }
            }
            .onChange(of: weightRange) { _, _ in
                Task { await loadWeight() }
            }
            .onChange(of: currentWeight) { _, _ in prefillTDEEFromHealth() }
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
                .offset(x: 120, y: -170)
            Circle()
                .fill(Color.accentFat.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 90)
                .offset(x: -110, y: 200)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PROFILE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(Color.accentPrimary)
            Text("Your Setup")
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        HStack(spacing: 0) {
            statBlock(icon: "figure.walk", value: "\(Int(health.todaySteps))", label: "STEPS", color: .accentCarbs)
            Divider().frame(height: 40).background(Color.textSecondary.opacity(0.2))
            statBlock(icon: "flame.fill", value: "\(Int(health.todayActiveCalories))", label: "ACTIVE KCAL", color: .accentPrimary)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    private func statBlock(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .serif))
                .foregroundStyle(Color.textPrimary)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
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
                    if let currentWeight {
                        Text("\(String(format: "%.1f", currentWeight)) kg")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
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
                Text("Log your weight in the Health app to see it here.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Chart(weightPoints) { point in
                    LineMark(x: .value("Date", point.date), y: .value("Weight", point.kg))
                        .foregroundStyle(Color.accentPrimary)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Date", point.date), y: .value("Weight", point.kg))
                        .foregroundStyle(LinearGradient(colors: [Color.accentPrimary.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisValueLabel().foregroundStyle(Color.textSecondary)
                        AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.15))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().foregroundStyle(Color.textSecondary)
                        AxisGridLine().foregroundStyle(Color.textSecondary.opacity(0.15))
                    }
                }
                .frame(height: 130)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    // MARK: - Goals Card

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DAILY GOALS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.textSecondary)

            goalField(icon: "flame.fill", label: "Calories", text: $calorieText, unit: "kcal", color: .accentPrimary)
            goalField(icon: "bolt.fill", label: "Protein", text: $proteinText, unit: "g", color: .accentProtein)
            goalField(icon: "leaf.fill", label: "Carbs", text: $carbText, unit: "g", color: .accentCarbs)
            goalField(icon: "drop.fill", label: "Fat", text: $fatText, unit: "g", color: .accentFat)

            Text("QUICK MACRO SPLIT")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.textSecondary)
                .padding(.top, 4)

            HStack(spacing: 8) {
                ForEach(MacroSplit.allCases, id: \.self) { split in
                    Button {
                        applySplit(split)
                    } label: {
                        Text(split.rawValue)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.bgPrimary.opacity(0.6))
                            )
                    }
                }
            }

            Button {
                saveGoals()
            } label: {
                Text("Save Goals")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.bgPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    private func goalField(icon: String, label: String, text: Binding<String>, unit: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(color)
                .frame(width: 18)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 70)
            Text(unit)
                .font(.system(size: 11))
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - TDEE Card

    private var tdeeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("TDEE CALCULATOR")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.textSecondary)
                Text("Estimate your maintenance calories")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 10) {
                tdeeField(label: "Age", text: $tdeeAge, unit: "yrs")
                tdeeField(label: "Height", text: $tdeeHeight, unit: "cm")
                tdeeField(label: "Weight", text: $tdeeWeight, unit: "kg")
            }

            HStack(spacing: 10) {
                Picker("Sex", selection: $tdeeSex) {
                    ForEach(BiologicalSexOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ACTIVITY LEVEL")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Color.textSecondary)
                ForEach(ActivityLevel.allCases) { level in
                    Button {
                        tdeeActivity = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.textPrimary)
                                Text(level.subtitle)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            Spacer()
                            if tdeeActivity == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentPrimary)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(tdeeActivity == level ? Color.accentPrimary.opacity(0.12) : Color.bgPrimary.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let result = tdeeResult {
                VStack(spacing: 6) {
                    Text("\(Int(result)) kcal/day")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.accentPrimary)
                    Text("estimated maintenance calories")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textSecondary)

                    Button {
                        calorieText = String(Int(result))
                        saveGoals()
                    } label: {
                        Text("Set as Calorie Goal")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.bgPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.accentPrimary)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            } else {
                Text("Fill in age, height, and weight above to calculate.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.bgSurface)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    private func tdeeField(label: String, text: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color.textSecondary)
            TextField(unit, text: text)
                .keyboardType(.numberPad)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.bgPrimary.opacity(0.6)))
        }
    }

    // MARK: - Actions

    private func loadGoalsText() {
        calorieText = String(Int(goals.calorieGoal))
        proteinText = String(Int(goals.proteinGoal))
        carbText = String(Int(goals.carbGoal))
        fatText = String(Int(goals.fatGoal))
    }

    private func saveGoals() {
        goals.calorieGoal = Double(calorieText) ?? goals.calorieGoal
        goals.proteinGoal = Double(proteinText) ?? goals.proteinGoal
        goals.carbGoal = Double(carbText) ?? goals.carbGoal
        goals.fatGoal = Double(fatText) ?? goals.fatGoal
        loadGoalsText()
    }

    private func applySplit(_ split: MacroSplit) {
        let calories = Double(calorieText) ?? goals.calorieGoal
        let grams = TDEECalculator.macroGrams(calories: calories, split: split)
        proteinText = String(Int(grams.protein))
        carbText = String(Int(grams.carbs))
        fatText = String(Int(grams.fat))
        saveGoals()
    }

    private func prefillTDEEFromHealth() {
        if tdeeAge.isEmpty, let age = health.ageYears { tdeeAge = String(age) }
        if tdeeHeight.isEmpty, let height = health.latestHeightCm { tdeeHeight = String(Int(height)) }
        if tdeeWeight.isEmpty, let weight = currentWeight { tdeeWeight = String(Int(weight)) }
        if let sex = health.biologicalSex {
            tdeeSex = sex == .female ? .female : .male
        }
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

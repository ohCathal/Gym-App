import SwiftUI
import SwiftData
import Charts

enum WeightRange: String, CaseIterable {
    case day = "Day", week = "Week", month = "Month"

    var daysBack: Int {
        switch self {
        case .day: return 7
        case .week: return 56
        case .month: return 365
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
    @Query private var profiles: [UserProfile]
    @State private var health = HealthKitManager()

    @State private var weightRange: WeightRange = .day
    @State private var weightPoints: [WeightPoint] = []

    private var profile: UserProfile {
        profiles.first ?? UserProfile()
    }

    private var currentWeight: Double? {
        weightPoints.last?.kg
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    activityCard
                    weightCard
                    statsCard

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
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 100)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Profile")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                if profiles.isEmpty { modelContext.insert(UserProfile()) }
                Task {
                    await health.requestAuthorization()
                    await loadWeight()
                    await health.fetchProfileData()
                }
            }
            .onChange(of: weightRange) { _, _ in
                Task { await loadWeight() }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        HStack(spacing: 0) {
            statBlock(icon: "figure.walk", value: "\(Int(health.todaySteps))", label: "STEPS", color: .accentCarbs)
            Divider().frame(height: 40).background(Color.textSecondary.opacity(0.2))
            statBlock(icon: "flame.fill", value: "\(Int(health.todayActiveCalories))", label: "ACTIVE KCAL", color: .accentPrimary)
        }
        .padding(.vertical, 20)
        .background(Color.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
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
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                    } else {
                        Text("No data")
                            .font(.system(size: 20, weight: .medium))
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
        .background(Color.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }

    // MARK: - Stats Card (Health-synced avatar)

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("YOUR BODY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                    Text("SYNCED FROM HEALTH")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.4)
                }
                .foregroundStyle(Color.accentPrimary.opacity(0.8))
            }

            BodyAvatarView(
                heightCm: health.latestHeightCm ?? profile.heightCm,
                weightKg: currentWeight ?? profile.weightKg
            )

            HStack(spacing: 0) {
                bodyStat(label: "AGE", value: health.ageYears.map { "\($0)" } ?? "—", unit: "yrs")
                Divider().frame(height: 30).background(Color.textSecondary.opacity(0.2))
                bodyStat(label: "HEIGHT", value: health.latestHeightCm.map { "\(Int($0))" } ?? "—", unit: "cm")
                Divider().frame(height: 30).background(Color.textSecondary.opacity(0.2))
                bodyStat(label: "WEIGHT", value: currentWeight.map { String(format: "%.1f", $0) } ?? "—", unit: "kg")
            }

            if health.latestHeightCm == nil || currentWeight == nil || health.ageYears == nil {
                Text("Add your height, weight, and date of birth in the Health app to see them here.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.bgSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal)
    }

    private func bodyStat(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
            Text("\(label) \(unit.isEmpty ? "" : "(\(unit))")")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func loadWeight() async {
        let samples = await health.fetchWeightSamples(daysBack: weightRange.daysBack)
        weightPoints = groupSamples(samples, for: weightRange)
    }

    private func groupSamples(_ samples: [(date: Date, kg: Double)], for range: WeightRange) -> [WeightPoint] {
        switch range {
        case .day:
            return samples.map { WeightPoint(date: $0.date, kg: $0.kg) }
        case .week:
            return averaged(samples, component: .weekOfYear)
        case .month:
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

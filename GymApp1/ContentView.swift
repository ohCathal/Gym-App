import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var goalsList: [MacroGoals]
    @Query(sort: \FoodEntry.timestamp, order: .reverse) private var allEntries: [FoodEntry]

    @State private var showingSearch = false
    @State private var editingEntry: FoodEntry?
    @State private var selectedDate: Date = Date()
    @State private var showingDatePicker = false

    private var goals: MacroGoals {
        goalsList.first ?? MacroGoals()
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var todayEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
    }

    private var totalCalories: Double { todayEntries.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { todayEntries.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { todayEntries.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { todayEntries.reduce(0) { $0 + $1.fat } }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var dateHeaderString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: selectedDate)
    }

    // MARK: - Recommendations

    private var recommendedEntries: [FoodEntry] {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: .now)
        let loggedTodayNames = Set(todayEntries.map { $0.name })

        let pastEntries = allEntries.filter { !calendar.isDate($0.timestamp, inSameDayAs: selectedDate) }

        let timeMatched = pastEntries.filter { entry in
            let hour = calendar.component(.hour, from: entry.timestamp)
            return abs(hour - currentHour) <= 2
        }

        let source = timeMatched.isEmpty ? pastEntries : timeMatched
        let grouped = Dictionary(grouping: source, by: { $0.name })

        let ranked = grouped
            .sorted { $0.value.count > $1.value.count }
            .compactMap { $0.value.max(by: { $0.timestamp < $1.timestamp }) }
            .filter { !loggedTodayNames.contains($0.name) }

        return Array(ranked.prefix(6))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundLayer

                ScrollView {
                    VStack(spacing: 24) {
                        header

                        gaugeCard

                        if todayEntries.isEmpty {
                            emptyState
                        } else {
                            logSection
                        }

                        if isToday && !recommendedEntries.isEmpty {
                            recommendedSection
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingSearch) {
                FoodSearchView(logDate: selectedDate)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            }
            .sheet(item: $editingEntry) { entry in
                NavigationStack {
                    ManualFoodEntryView(existingEntry: entry, onSaved: { editingEntry = nil })
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationStack {
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Color.accentPrimary)
                    .padding()
                    .background(Color.bgPrimary.ignoresSafeArea())
                    .navigationTitle("Select Day")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarColorScheme(.dark, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingDatePicker = false }
                                .foregroundStyle(Color.accentPrimary)
                        }
                    }
                }
                .presentationDetents([.medium])
                .preferredColorScheme(.dark)
            }
            .onAppear {
                if goalsList.isEmpty {
                    modelContext.insert(MacroGoals())
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundLayer: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            Circle()
                .fill(Color.accentProtein.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: -120, y: -180)

            Circle()
                .fill(Color.accentFat.opacity(0.15))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 140, y: -100)

            Circle()
                .fill(Color.accentPrimary.opacity(0.12))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -60, y: 300)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    withAnimation { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.bgSurface))
                }

                VStack(spacing: 2) {
                    Text((isToday ? greeting : "Viewing").uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(Color.accentPrimary)
                    Button {
                        showingDatePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(dateHeaderString)
                                .font(.system(size: 22, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.textPrimary)
                            Image(systemName: "calendar")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                Button {
                    withAnimation { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(isToday ? Color.textSecondary.opacity(0.25) : Color.textSecondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.bgSurface))
                }
                .disabled(isToday)
            }

            if !isToday {
                Button {
                    withAnimation { selectedDate = Date() }
                } label: {
                    Text("Jump to Today")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    // MARK: - Gauge Card

    private var gaugeCard: some View {
        VStack(spacing: 22) {
            Button {
                showingSearch = true
            } label: {
                ZStack {
                    MacroGauge(
                        overallProgress: goals.calorieGoal > 0 ? totalCalories / goals.calorieGoal : 0,
                        proteinCals: totalProtein * 4,
                        carbsCals: totalCarbs * 4,
                        fatCals: totalFat * 9,
                        lineWidth: 22
                    )
                    .frame(width: 240, height: 240)

                    VStack(spacing: 4) {
                        Text("\(Int(totalCalories))")
                            .font(.system(size: 46, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.textPrimary)
                        Text("of \(Int(goals.calorieGoal)) kcal")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(Color.textSecondary)
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 11))
                            Text("TAP TO LOG")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1.2)
                        }
                        .foregroundStyle(Color.accentPrimary)
                        .padding(.top, 6)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            HStack(spacing: 10) {
                macroPill(icon: "bolt.fill", title: "Protein", value: totalProtein, goal: goals.proteinGoal, color: .accentProtein)
                macroPill(icon: "leaf.fill", title: "Carbs", value: totalCarbs, goal: goals.carbGoal, color: .accentCarbs)
                macroPill(icon: "drop.fill", title: "Fat", value: totalFat, goal: goals.fatGoal, color: .accentFat)
            }
        }
        .padding(.bottom, 20)
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.bgSurface.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func macroPill(icon: String, title: String, value: Double, goal: Double, color: Color) -> some View {
        let progress = min(max(goal > 0 ? value / goal : 0, 0), 1)
        return VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(color)
            Text("\(Int(value))g")
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(Color.textSecondary)
            Capsule()
                .fill(Color.bgPrimary)
                .frame(height: 4)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(color)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 4)
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 34))
                .foregroundStyle(Color.textSecondary.opacity(0.5))
            Text(isToday ? "Nothing logged yet" : "No entries this day")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.textPrimary)
            Text(isToday ? "Tap the ring above to log your first meal today" : "Tap the ring above to add something for this day")
                .font(.system(size: 12))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Log Section

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isToday ? "TODAY'S LOG" : "LOG")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 10) {
                ForEach(todayEntries) { entry in
                    logRow(entry)
                }
            }
        }
    }

    private func logRow(_ entry: FoodEntry) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "fork.knife")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentPrimary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                Text("\(Int(entry.calories)) kcal · P \(Int(entry.protein))g · C \(Int(entry.carbs))g · F \(Int(entry.fat))g")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            HStack(spacing: 6) {
                Button {
                    editingEntry = entry
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentPrimary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.accentPrimary.opacity(0.12)))
                }

                Button {
                    modelContext.delete(entry)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.red)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Color.red.opacity(0.12)))
                }
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

    // MARK: - Recommended Section

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SUGGESTED FOR NOW")
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.textSecondary)
                .padding(.leading, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recommendedEntries) { entry in
                        recommendedCard(entry)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 4)
            }
        }
    }

    private func recommendedCard(_ entry: FoodEntry) -> some View {
        Button {
            quickAdd(entry)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.accentPrimary)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accentPrimary)
                }
                Text(entry.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Text("\(Int(entry.calories)) kcal")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(12)
            .frame(width: 140, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.bgSurface.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func quickAdd(_ source: FoodEntry) {
        let entry = FoodEntry(
            name: source.name,
            calories: source.calories,
            protein: source.protein,
            carbs: source.carbs,
            fat: source.fat,
            timestamp: selectedDate
        )
        modelContext.insert(entry)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, MacroGoals.self], inMemory: true)
}

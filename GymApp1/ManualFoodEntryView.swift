import SwiftUI
import SwiftData

struct ManualFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    var existingEntry: FoodEntry?
    var onSaved: () -> Void = {}

    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var grams: Double = 100
    @State private var previousGrams: Double = 100

    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(existingEntry == nil ? "Add Manually" : "Edit Entry")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("FOOD")
                        styledField(placeholder: "Name", text: $name, keyboard: .default)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("AMOUNT")
                        VStack(spacing: 12) {
                            HStack {
                                Text("\(Int(grams))g")
                                    .font(.system(size: 28, weight: .semibold, design: .serif))
                                    .foregroundStyle(Color.accentPrimary)
                                Spacer()
                                Stepper("", value: $grams, in: 1...2000, step: 5)
                                    .labelsHidden()
                            }
                            Slider(value: $grams, in: 1...500, step: 1)
                                .tint(Color.accentPrimary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.bgSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                        .onChange(of: grams) { _, newValue in
                            scaleValues(to: newValue)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("MACROS")
                        VStack(spacing: 10) {
                            styledField(placeholder: "Calories", text: $calories, keyboard: .decimalPad, icon: "flame.fill", color: .accentPrimary)
                            styledField(placeholder: "Protein (g)", text: $protein, keyboard: .decimalPad, icon: "bolt.fill", color: .accentProtein)
                            styledField(placeholder: "Carbs (g)", text: $carbs, keyboard: .decimalPad, icon: "leaf.fill", color: .accentCarbs)
                            styledField(placeholder: "Fat (g)", text: $fat, keyboard: .decimalPad, icon: "drop.fill", color: .accentFat)
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.bgPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.accentPrimary.opacity(0.3) : Color.accentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if let entry = existingEntry {
                name = entry.name
                calories = String(Int(entry.calories))
                protein = String(Int(entry.protein))
                carbs = String(Int(entry.carbs))
                fat = String(Int(entry.fat))
                grams = entry.grams
                previousGrams = entry.grams
            } else {
                previousGrams = grams
            }
        }
        .preferredColorScheme(.dark)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(Color.textSecondary)
            .padding(.leading, 4)
    }

    private func styledField(placeholder: String, text: Binding<String>, keyboard: UIKeyboardType, icon: String? = nil, color: Color = .accentPrimary) -> some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                    .frame(width: 20)
            }
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .foregroundStyle(Color.textPrimary)
                .tint(Color.accentPrimary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func scaleValues(to newGrams: Double) {
        guard previousGrams > 0 else {
            previousGrams = newGrams
            return
        }
        let ratio = newGrams / previousGrams

        if let cal = Double(calories) { calories = String(Int((cal * ratio).rounded())) }
        if let p = Double(protein) { protein = String(Int((p * ratio).rounded())) }
        if let c = Double(carbs) { carbs = String(Int((c * ratio).rounded())) }
        if let f = Double(fat) { fat = String(Int((f * ratio).rounded())) }

        previousGrams = newGrams
    }

    private func save() {
        if let entry = existingEntry {
            entry.name = name
            entry.calories = Double(calories) ?? 0
            entry.protein = Double(protein) ?? 0
            entry.carbs = Double(carbs) ?? 0
            entry.fat = Double(fat) ?? 0
            entry.grams = grams
        } else {
            let entry = FoodEntry(
                name: name,
                calories: Double(calories) ?? 0,
                protein: Double(protein) ?? 0,
                carbs: Double(carbs) ?? 0,
                fat: Double(fat) ?? 0,
                grams: grams
            )
            modelContext.insert(entry)
        }
        onSaved()
    }
}

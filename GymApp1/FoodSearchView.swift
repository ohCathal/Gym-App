import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [FoodSearchResult] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var selected: FoodSearchResult?
    @State private var showingScanner = false
    @State private var scanError: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textSecondary)
                    TextField("Search food, e.g. Dunnes chicken breast", text: $query)
                        .foregroundStyle(Color.textPrimary)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top, 12)

                Button {
                    showingScanner = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "barcode.viewfinder")
                        Text("Scan Barcode")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.accentPrimary)
                }
                .padding(.top, 8)

                if isSearching {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                } else if results.isEmpty && query.trimmingCharacters(in: .whitespaces).count >= 2 {
                    Spacer()
                    Text("No matches. Try a different search or add it manually below.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                } else {
                    List(results) { result in
                        Button {
                            selected = result
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text(result.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(Color.textPrimary)
                                    Text(result.source.uppercased())
                                        .font(.system(size: 9, weight: .semibold))
                                        .tracking(0.4)
                                        .foregroundStyle(Color.accentPrimary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.accentPrimary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                if let brand = result.brand, !brand.isEmpty {
                                    Text(brand)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color.textSecondary)
                                }
                                Text("\(Int(result.caloriesPer100g)) kcal / 100g · P \(Int(result.proteinPer100g))g · C \(Int(result.carbsPer100g))g · F \(Int(result.fatPer100g))g")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Color.bgSurface)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                NavigationLink {
                    ManualFoodEntryView(onSaved: { dismiss() })
                } label: {
                    Text("Can't find it? Add manually")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.accentPrimary)
                }
                .padding(.vertical, 16)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Log Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task(id: query) {
                await runSearch()
            }
            .sheet(item: $selected) { result in
                QuantityEntryView(result: result, onSaved: {
                    selected = nil
                    query = ""
                    results = []
                })
            }
            .fullScreenCover(isPresented: $showingScanner) {
                BarcodeScannerScreen { barcode in
                    Task {
                        do {
                            if let product = try await OpenFoodFactsService.lookupProduct(barcode: barcode) {
                                selected = product
                            } else {
                                scanError = "Product not found for that barcode."
                            }
                        } catch {
                            scanError = "Couldn't look up that barcode."
                        }
                    }
                }
            }
            .alert("Not found", isPresented: .constant(scanError != nil), presenting: scanError) { _ in
                Button("OK") { scanError = nil }
            } message: { message in
                Text(message)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func runSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []
            errorMessage = nil
            return
        }
        try? await Task.sleep(nanoseconds: 400_000_000)
        guard !Task.isCancelled else { return }

        isSearching = true
        errorMessage = nil

        async let usdaTask: [FoodSearchResult] = {
            do {
                return try await USDAFoodService.search(query: trimmed)
            } catch {
                print("USDA search failed: \(error)")
                return []
            }
        }()

        async let offTask: [FoodSearchResult] = {
            do {
                return try await OpenFoodFactsService.search(query: trimmed)
            } catch {
                print("Open Food Facts search failed: \(error)")
                return []
            }
        }()

        let combined = await usdaTask + offTask
        results = combined
        isSearching = false
    }
}

struct QuantityEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let result: FoodSearchResult
    var onSaved: () -> Void

    @State private var grams: Double = 100
    @State private var gramsText: String = "100"
    @FocusState private var gramsFieldFocused: Bool

    private var scale: Double { grams / 100 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text(result.name)
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)
                    if let brand = result.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .padding(.top, 24)

                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        TextField("100", text: $gramsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.system(size: 36, weight: .semibold, design: .serif))
                            .foregroundStyle(Color.accentPrimary)
                            .fixedSize()
                            .focused($gramsFieldFocused)
                            .onChange(of: gramsText) { _, newValue in
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered != newValue { gramsText = filtered }
                                if let value = Double(filtered) {
                                    grams = min(max(value, 1), 2000)
                                }
                            }
                        Text("g")
                            .font(.system(size: 22, weight: .medium, design: .serif))
                            .foregroundStyle(Color.accentPrimary.opacity(0.7))
                    }

                    Stepper("", value: $grams, in: 1...2000, step: 1)
                        .labelsHidden()
                        .onChange(of: grams) { _, newValue in
                            let rounded = Int(newValue)
                            if gramsText != String(rounded) {
                                gramsText = String(rounded)
                            }
                        }
                }
                .onTapGesture {
                    gramsFieldFocused = true
                }

                VStack(spacing: 12) {
                    statRow("Calories", result.caloriesPer100g * scale, unit: " kcal", color: .accentPrimary)
                    statRow("Protein", result.proteinPer100g * scale, unit: "g", color: .accentProtein)
                    statRow("Carbs", result.carbsPer100g * scale, unit: "g", color: .accentCarbs)
                    statRow("Fat", result.fatPer100g * scale, unit: "g", color: .accentFat)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    save()
                } label: {
                    Text("Add to Today's Log")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.bgPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color.bgPrimary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { gramsFieldFocused = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func statRow(_ title: String, _ value: Double, unit: String, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text("\(Int(value))\(unit)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundStyle(Color.textPrimary)
        }
    }

    private func save() {
        let entry = FoodEntry(
            name: result.name,
            calories: result.caloriesPer100g * scale,
            protein: result.proteinPer100g * scale,
            carbs: result.carbsPer100g * scale,
            fat: result.fatPer100g * scale,
            grams: grams
        )
        modelContext.insert(entry)
        onSaved()
    }
}

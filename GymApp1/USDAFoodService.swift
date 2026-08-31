import Foundation

enum USDAFoodService {
    // Replace with your real key from fdc.nal.usda.gov/api-key-signup.html
    private static let apiKey = "uuQM5ZL2KPuZBRP9oo0HjHBWRQNxTogoqYzbvazk"
    private static let baseURL = "https://api.nal.usda.gov/fdc/v1"

    static func search(query: String) async throws -> [FoodSearchResult] {
        guard var components = URLComponents(string: "\(baseURL)/foods/search") else {
            return []
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "pageSize", value: "25"),
            URLQueryItem(name: "dataType", value: "Foundation,SR Legacy,Branded")
        ]
        guard let url = components.url else { return [] }

        let (data, response) = try await URLSession.shared.data(from: url)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(USDASearchResponse.self, from: data)

        return decoded.foods.compactMap { food in
            guard let calories = food.nutrientValue(number: "208") else { return nil }
            return FoodSearchResult(
                name: food.description,
                brand: food.brandOwner,
                caloriesPer100g: calories,
                proteinPer100g: food.nutrientValue(number: "203") ?? 0,
                carbsPer100g: food.nutrientValue(number: "205") ?? 0,
                fatPer100g: food.nutrientValue(number: "204") ?? 0,
                source: "USDA"
            )
        }
    }
}

private struct USDASearchResponse: Decodable {
    let foods: [USDAFoodDTO]
}

private struct USDAFoodDTO: Decodable {
    let description: String
    let brandOwner: String?
    let foodNutrients: [USDANutrientDTO]

    func nutrientValue(number: String) -> Double? {
        foodNutrients.first { $0.nutrientNumber == number }?.value
    }
}

private struct USDANutrientDTO: Decodable {
    let nutrientNumber: String?
    let value: Double?
}

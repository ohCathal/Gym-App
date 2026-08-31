import Foundation

struct FoodSearchResult: Identifiable {
    let id = UUID()
    let name: String
    let brand: String?
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    var source: String = "Open Food Facts"
}

enum OpenFoodFactsService {
    static func search(query: String) async throws -> [FoodSearchResult] {
        guard var components = URLComponents(string: "https://search.openfoodfacts.org/search") else {
            return []
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page_size", value: "25"),
            URLQueryItem(name: "fields", value: "product_name,brands,nutriments")
        ]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.setValue("GymApp1 - iOS App", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)

        return decoded.hits.compactMap { product in
            guard let name = product.product_name, !name.isEmpty,
                  let kcal = product.nutriments?.energyKcal100g else { return nil }
            return FoodSearchResult(
                name: name,
                brand: product.brandsJoined,
                caloriesPer100g: kcal,
                proteinPer100g: product.nutriments?.proteins100g ?? 0,
                carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
                fatPer100g: product.nutriments?.fat100g ?? 0
            )
        }
    }
}

extension OpenFoodFactsService {
    static func lookupProduct(barcode: String) async throws -> FoodSearchResult? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json?fields=product_name,brands,nutriments") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue("GymApp1 - iOS App", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoded = try JSONDecoder().decode(OFFProductLookupResponse.self, from: data)

        guard let product = decoded.product,
              let name = product.product_name, !name.isEmpty,
              let kcal = product.nutriments?.energyKcal100g else {
            return nil
        }

        return FoodSearchResult(
            name: name,
            brand: product.brandsJoined,
            caloriesPer100g: kcal,
            proteinPer100g: product.nutriments?.proteins100g ?? 0,
            carbsPer100g: product.nutriments?.carbohydrates100g ?? 0,
            fatPer100g: product.nutriments?.fat100g ?? 0
        )
    }
}

private struct OFFProductLookupResponse: Decodable {
    let product: OFFProductDTO?
}

private struct OFFSearchResponse: Decodable {
    let hits: [OFFProductDTO]
}

private struct OFFProductDTO: Decodable {
    let product_name: String?
    let brands: [String]?
    let nutriments: OFFNutrimentsDTO?

    var brandsJoined: String? {
        brands?.joined(separator: ", ")
    }
}

private struct OFFNutrimentsDTO: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
    }
}

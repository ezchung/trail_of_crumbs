import Hummingbird
import SourdoughCore


struct RecipeDTO: ResponseEncodable {
    let name: String
    let flourGrams: Double
    let waterGrams: Double
    let starterGrams: Double
    let saltGrams: Double
    let totalDoughGrams: Double

    init(_ r: Recipe) {
        name = r.name
        flourGrams = r.flourGrams
        waterGrams = r.waterGrams
        starterGrams = r.starterGrams
        saltGrams = r.saltGrams
        totalDoughGrams = r.totalDoughGrams
    }
}

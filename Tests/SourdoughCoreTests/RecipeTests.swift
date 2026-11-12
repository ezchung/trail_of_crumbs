import Testing
@testable import SourdoughCore

@Test func calculatesIngredientsFromBakersPercentages() {
    let recipe = Recipe(name: "Test", flourGrams: 500, hydration: 0.75, starterPercent: 0.20, saltPercent: 0.02)
    #expect(recipe.waterGrams == 375)
    #expect(recipe.starterGrams == 100)
    #expect(recipe.saltGrams == 10)
    #expect(recipe.totalDoughGrams == 985)
}

@Test func appStoreNamesFitLimits() {
    #expect(AppInfo.storeName.count <= 30)
    #expect(AppInfo.storeSubtitle.count <= 30)
}

@Test func scalingKeepsPercentages() {
    let doubled = Recipe(name: "Test", flourGrams: 500).scaled(toFlour: 1000)
    #expect(doubled.waterGrams == 750)
    #expect(doubled.hydration == 0.75)
}

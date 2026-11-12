/// A sourdough recipe described in baker's percentages.
///
/// Baker's percentages express every ingredient relative to total flour weight,
/// e.g. 75% hydration means 75 g water per 100 g flour.
public struct Recipe: Sendable {
    public var name: String
    public var flourGrams: Double
    public var hydration: Double      // water / flour, e.g. 0.75
    public var starterPercent: Double // starter / flour, e.g. 0.20
    public var saltPercent: Double    // salt / flour, e.g. 0.02

    public init(
        name: String,
        flourGrams: Double,
        hydration: Double = 0.75,
        starterPercent: Double = 0.20,
        saltPercent: Double = 0.02
    ) {
        self.name = name
        self.flourGrams = flourGrams
        self.hydration = hydration
        self.starterPercent = starterPercent
        self.saltPercent = saltPercent
    }

    public var waterGrams: Double { flourGrams * hydration }
    public var starterGrams: Double { flourGrams * starterPercent }
    public var saltGrams: Double { flourGrams * saltPercent }

    public var totalDoughGrams: Double {
        flourGrams + waterGrams + starterGrams + saltGrams
    }

    /// Returns a copy of this recipe resized to the given flour weight.
    public func scaled(toFlour grams: Double) -> Recipe {
        var copy = self
        copy.flourGrams = grams
        return copy
    }
}

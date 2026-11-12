import SourdoughCore

print("🍞 \(AppInfo.displayName)")
print(String(repeating: "-", count: 44))

let loaf = Recipe(name: "Country Loaf", flourGrams: 500)

func show(_ recipe: Recipe) {
    print("\(recipe.name) (\(Int(recipe.flourGrams))g flour)")
    print("  Water:   \(Int(recipe.waterGrams))g  (\(Int(recipe.hydration * 100))% hydration)")
    print("  Starter: \(Int(recipe.starterGrams))g")
    print("  Salt:    \(Int(recipe.saltGrams))g")
    print("  Total dough: \(Int(recipe.totalDoughGrams))g")
    print()
}

show(loaf)
show(loaf.scaled(toFlour: 1000))

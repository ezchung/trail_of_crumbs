import Hummingbird
import SourdoughCore

let router = Router()

// GET /  -> an HTML page with a small calculator form.
// Example: http://localhost:8080/?flour=750&hydration=80
router.get("/") { request, _ -> Response in
    let flour = request.uri.queryParameters.get("flour", as: Double.self) ?? 500
    let hydrationPct = request.uri.queryParameters.get("hydration", as: Double.self) ?? 75
    let recipe = Recipe(name: "Country Loaf", flourGrams: flour, hydration: hydrationPct / 100)

    return Response(
        status: .ok,
        headers: [.contentType: "text/html; charset=utf-8"],
        body: .init(byteBuffer: ByteBuffer(string: Page.home(recipe)))
    )
}

// GET /api/recipe  -> the same numbers as JSON, for a future iOS app or JS front end.
router.get("/api/recipe") { request, _ -> RecipeDTO in
    let flour = request.uri.queryParameters.get("flour", as: Double.self) ?? 500
    let hydrationPct = request.uri.queryParameters.get("hydration", as: Double.self) ?? 75
    return RecipeDTO(Recipe(name: "Country Loaf", flourGrams: flour, hydration: hydrationPct / 100))
}

let app = Application(
    router: router,
    configuration: .init(address: .hostname("127.0.0.1", port: 8080), serverName: AppInfo.displayName)
)
print("🍞 \(AppInfo.displayName) is running at http://localhost:8080")
try await app.runService()

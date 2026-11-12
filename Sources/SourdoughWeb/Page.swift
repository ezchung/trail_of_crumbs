import SourdoughCore

/// HTML templates. Plain string building for now; swap for a template
/// engine (e.g. Mustache) once pages get bigger.
enum Page {
    static func home(_ r: Recipe) -> String {
        func g(_ x: Double) -> String { "\(Int(x.rounded()))g" }

        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(AppInfo.displayName)</title>
          <style>
            body { font-family: system-ui, sans-serif; max-width: 32rem; margin: 2rem auto;
                   padding: 0 1rem; background: #fbf6ee; color: #3b2f22; }
            h1 { font-size: 1.5rem; }
            form { display: flex; gap: .75rem; flex-wrap: wrap; align-items: end; margin-bottom: 1.5rem; }
            label { display: flex; flex-direction: column; font-size: .9rem; }
            input { padding: .4rem; width: 7rem; }
            button { padding: .5rem 1rem; background: #8a5a2b; color: white; border: 0; border-radius: 4px; }
            table { border-collapse: collapse; width: 100%; }
            td { padding: .4rem 0; border-bottom: 1px solid #e6d9c6; }
            td:last-child { text-align: right; font-variant-numeric: tabular-nums; }
            tr.total td { font-weight: bold; border-bottom: 0; }
          </style>
        </head>
        <body>
          <h1>🍞 \(AppInfo.displayName)</h1>
          <form method="get" action="/">
            <label>Flour (g) <input name="flour" type="number" min="1" value="\(Int(r.flourGrams))"></label>
            <label>Hydration (%) <input name="hydration" type="number" min="1" max="150" value="\(Int((r.hydration * 100).rounded()))"></label>
            <button type="submit">Calculate</button>
          </form>
          <table>
            <tr><td>Flour</td><td>\(g(r.flourGrams))</td></tr>
            <tr><td>Water</td><td>\(g(r.waterGrams))</td></tr>
            <tr><td>Starter</td><td>\(g(r.starterGrams))</td></tr>
            <tr><td>Salt</td><td>\(g(r.saltGrams))</td></tr>
            <tr class="total"><td>Total dough</td><td>\(g(r.totalDoughGrams))</td></tr>
          </table>
        </body>
        </html>
        """
    }
}

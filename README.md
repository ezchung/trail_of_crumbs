# Doughn't worry, I left a trail of crumbs

A sourdough companion built around a shelf of jars. Each jar is a starter or dough you have going, and its face and fill level tell you what it needs: hungry, thirsty, ready, and so on.

| Where | Name |
| --- | --- |
| Full name (web, headings) | Doughn't worry, I left a trail of crumbs |
| App Store name (max 30) | Doughn't Worry |
| App Store subtitle (max 30) | I left a trail of crumbs |
| Home-screen name | Doughn't Worry |

All names live in `Sources/SourdoughCore/App.swift`.

---

## How it runs

```
Browser  ──request──▶  SourdoughWeb (Hummingbird server)  ──calls──▶  SourdoughCore (logic)
         ◀──HTML/JSON──        routes + pages                          recipes, math, rules
```

| Part | Folder | Job |
| --- | --- | --- |
| Logic | `Sources/SourdoughCore/` | All bread rules and math. No UI, no web code. Reusable by a future iOS app. |
| Web server + UI | `Sources/SourdoughWeb/` | `main.swift` = routes (URL → code). `Page.swift` = HTML pages. `RecipeDTO.swift` = JSON shapes. |
| CLI | `Sources/SourdoughApp/` | Terminal version, handy for quick checks. |
| Tests | `Tests/SourdoughCoreTests/` | Tests for the logic. |

**Rule of thumb:** new bread rules go in `SourdoughCore`; new pages and routes go in `SourdoughWeb`.

### Commands

```sh
swift run SourdoughWeb   # start the web app → open http://localhost:8080
swift run SourdoughApp   # terminal version
swift test               # run tests
swift build              # compile only
```

Requires Swift 6.1.3 (installed via swiftly). Hummingbird is capped below 2.27 until the toolchain moves to Swift 6.2.

---

## Scope

A small iPhone app for one thing: **looking after your starters and doughs**. It has a welcome screen with Log in / Sign up, then 4 tabs and no other pages. Everything else is a popup or part of a jar.

Colors, fonts and screen looks are in [DESIGN.md](DESIGN.md).

| Decided | |
|---|---|
| Focus | Starter jars + bread/pizza dough jars, on one shelf |
| Target | iPhone app (App Store) |
| For now | No Mac yet, so build the logic + a web preview on the PC. The same `SourdoughCore` goes into the SwiftUI app later. |
| Look | Cute. A jar's face and fill show what it needs, with no extra screens to explain it |
| Notifications | Yes, for the key moments (see Settings) |
| Accounts | Log in / Sign up with email + password (see DESIGN.md → Welcome screen) |

---

## App layout

```
┌────────────────────────────────────┐
│  Doughn't Worry                    │
│                                    │
│   ┌────┐   ┌────┐   ┌────┐  ┌ ─ ─┐ │
│   │ ^^ │   │ >< │   │ -- │    +    │   Home = the jar shelf
│   │▓▓▓▓│   │▓   │   │▓▓  │  │    │ │   one jar per starter/dough
│   └────┘   └────┘   └────┘  └ ─ ─┘ │   "+" empty jar = Add Dough
│   Bubbles   Rye    Old Faithful    │
│                                    │
├────────────────────────────────────┤
│  Home  │ Journal │  Bake  │ Settings │
└────────────────────────────────────┘
```

| Tab | What it is |
|---|---|
| **Home** | The jar shelf. Tap a jar to zoom in. Tap the "+" empty jar to add one. |
| **Journal** | History + your recipes: what you made, what you liked, search |
| **Bake** | Plan a bake backwards from when you want bread or pizza |
| **Settings** | Units, defaults, notifications |

Popups (not pages): **Jar detail** (zoomed jar), **Add Dough** (from the "+" jar), **Feed / Take out** sheets.

Before the tabs (logged out only): **Welcome** (title, monkey, Log in / Sign up), then the **Log in** or **Sign up** form.

---

## Home: the jar shelf

A jar is anything you have going: a starter, or a dough in progress (bread or pizza). Every jar works the same way. Only its calculator and its timings differ.

### Fill level: one picture, like a real jar

The jar on screen behaves like the real one on your counter:

- **Feed it** and the level goes up (more stuff in the jar).
- **Take some out** and the level goes down.
- **As it ferments** it rises, up to about double at peak, then sinks back.
- A **rubber band line** marks where the level was right after the last feeding, like the band bakers put on real jars. Rise is easy to read against it.

Behind the picture the app only tracks two things: **grams in the jar** and **time since the last feeding**.

### Faces (moods)

The face says what the jar needs. No labels or extra screens are required.

| Face | When | What to do |
|---|---|---|
| **Rising** | Fed, still climbing toward peak | Wait |
| **Ready** | At or near peak | Use it now (mix dough, build levain) |
| **Hungry** | Past peak and falling | Feed it (flour + water) |
| **Thirsty** | Too stiff or drying out (low hydration, dry top) | Add water / feed at a higher hydration |
| **Starving** | Long overdue; hooch (liquid) on top | Discard and feed, maybe twice |
| **Sleepy** | In the fridge | Nothing; feed before baking |
| **Baby** | New starter, first ~7 days | Feed daily; it's still getting going |

Dough jars use simpler faces: **Rising**, **Ready** (bake / stretch now), **Over-proofed**.

The rules that pick a face live in `SourdoughCore`, not in the UI, so the iPhone app shows the same moods. Draw the jar and face art yourself, in your own style.

### Jar detail (popup: tap a jar, it zooms in)

The jar grows to fill the screen, with its face, name, grams, and the rubber band line.

```
        ┌──────────┐
        │   ^ ^    │   "Bubbles" · Ready
        │  ▓▓▓▓▓▓  │   180 g in jar
        │──▓▓▓▓▓▓──│ ← rubber band (level at last feed)
        │  ▓▓▓▓▓▓  │   fed 5 h ago · peaks in ~1 h
        └──────────┘

   [ Feed ]   [ Take out ]   [ Fridge ]   [ ··· ]
```

| Button | What you enter | What happens |
|---|---|---|
| **Feed** | Flour g + water g (prefilled from its usual ratio; +/- buttons) | Grams go up, the rubber band moves to the new level, the timer resets |
| **Take out** | Grams removed, and why: *bake*, *discard*, *gave away* | Grams go down. If the reason is *bake*, it can start a Bake |
| **Fridge** | Nothing | Face turns Sleepy, rising pauses. Tap again to take it out |
| **··· (more)** | Rename, change ratio, notes, delete | Edit the jar |

- [ ] Undo the last action (a mis-tap shouldn't ruin the history)
- [ ] Every action is saved to the Journal automatically, so you never type anything twice
- [ ] Swipe down or tap outside to zoom back out to the shelf

### Add Dough (popup: tap the "+" jar)

Pick what it is, and that choice leads to the right screen:

```
+ (empty jar)
 ├─ Starter      → name, flour type, feeding ratio → jar on the shelf
 ├─ Bread dough  → Bread calculator               → jar on the shelf
 └─ Pizza dough  → Pizza calculator               → jar on the shelf
```

**Bread calculator** (the math exists today at `/`)
- [x] Flour + hydration % → water, starter, salt, total
- [ ] Starter % and salt % inputs
- [ ] Or enter the loaf weight you want and work back to flour

**Pizza calculator**: you think in dough balls, not flour
- [ ] Inputs: number of balls × weight per ball (e.g. 6 × 250 g), hydration % (default ~65%), salt %, starter %, optional oil %
- [ ] Works backwards: total dough → flour → everything else
- [ ] Dough is ready on a set time (e.g. 24 h or 48 h cold ferment)

**Both calculators**
- [ ] Start from a saved recipe (from the Journal) or from scratch
- [ ] "Use starter from: [jar]" → takes that many grams out of the jar automatically
- [ ] "Start" puts the dough on the shelf as its own jar (pizza can look like a dough box)

---

## Journal (tab)

The trail of crumbs, and where your recipes live. Three sections along the top:

```
 [ History ]  [ Recipes ]  [ Liked ♥ ]        🔍 search
```

| Section | What's in it |
|---|---|
| **History** | Everything that happened, newest first: feedings, take-outs, bakes. Filled in automatically from jar actions |
| **Recipes** | Your saved bread and pizza formulas. Tap one to open it in the calculator, scaled to any size |
| **Liked ♥** | Bakes and recipes you hearted. Your "make this again" list |

- [ ] **Search** across all three (recipe name, jar name, notes, e.g. "rye", "pizza", "75%")
- [ ] After a bake: photo, rating, notes, and a ♥ if you'd make it again
- [ ] "Save as recipe" from any bake in History
- [ ] Filter History by jar

---

## Bake (tab)

Plan backwards from when you want bread or pizza.

- [ ] Pick a recipe (from the Journal) and a jar to use starter from
- [ ] Pick the time you want it ready (e.g. "Saturday 6 pm, pizza")
- [ ] Auto-schedule the steps:
    - bread: feed → levain → autolyse → mix → bulk (stretch & folds) → shape → cold retard → bake
    - pizza: feed → mix → bulk → ball → cold ferment → bring to room temp → bake
- [ ] While it's in progress, the dough shows up as its own jar on Home
- [ ] Checklist and countdown to the next step (with a notification)
- [ ] When finished, it goes to the Journal and asks for a photo, rating and ♥

---

## Settings (tab)

- [ ] Units (grams / ounces)
- [ ] Default hydration, starter %, salt % (bread and pizza separately)
- [ ] Default step durations for Bake
- [ ] **Notifications**, each one on or off:
    - "Bubbles is ready!": a jar reaches peak
    - "Rye is hungry": a jar is past peak
    - "Time to stretch & fold": a Bake step is due
    - Weekly reminder for Sleepy (fridge) jars

Notifications on iPhone are **local**: the phone schedules them from feeding times, so no server or account is needed. The web preview can't send them, so they get built with the iPhone app.

---

## Web preview (current, for building on the PC)

| Route | Screen | Status |
|---|---|---|
| `/` | Calculator (moves into Add Dough) | Built |
| `/` | Home: jar shelf | Planned (takes over `/`) |
| `/jars/{id}` | Jar detail | Planned |
| `/add` | Add Dough | Planned |
| `/journal` | Journal (History / Recipes / Liked, search) | Planned |
| `/bake` | Bake | Planned |
| `/settings` | Settings | Planned |

---

## Build order

1. `Jar` + mood rules in `SourdoughCore`, with tests (fill level and face from grams + feeding time)
2. Home shelf in the web preview with sample jars, to tune the cute look early
3. Jar detail: Feed / Take out / Fridge
4. Add Dough + pizza calculator
5. Save data (a JSON file in the preview; SwiftData on iPhone later)
6. Journal: History, Recipes, Liked, search
7. Bake planner
8. Settings
9. iPhone app (needs a Mac): SwiftUI screens on top of `SourdoughCore`, plus notifications

## Open questions

- [ ] How many jars fit on the shelf before it scrolls (a second shelf)?
- [ ] Do dough jars disappear when baked, or move to the Journal automatically?
- [ ] Photos in the Journal: yes from day one, or later?

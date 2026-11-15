# Design: Doughn't Worry

The look and feel the app follows. **Every design change gets approved by Ezra first.** Nothing here changes and nothing new is added without that approval.

Scope for now: **colors and fonts** for each part, plus screen layouts. The animation, jar art and proboscis monkey mascot come later.

---

## Direction

- **Structure:** inspired by Waterllama. A Home screen of characters (jars) whose look shows their status, plus a simple floating tab bar.
- **Style:** bubbly and cute, but minimal. Soft sky background, rounded type, dough-colored buttons.
- **Mode:** light only for now. Dark mode is a later decision.

---

## Color palette

| Token | Hex | Used for |
|---|---|---|
| `paleSky` | `#EEF7FF` | App background, every screen incl. welcome |
| `sky` | `#5AB0FF` | Active tab, starter lid |
| `dough` | `#FFC97A` | Buttons |
| `navy` | `#23395B` | Titles (title font) |
| `softBlack` | `#1F1F1F` | Body text, button text |
| `softBlack55` | `#1F1F1F` at 55% | Secondary text (hints, timestamps) |
| `softBlack40` | `#1F1F1F` at 40% | Inactive tab icon + name |
| `leaf` | `#6CCB8B` | Bread dough lid |
| `tomato` | `#FF7A5C` | Pizza dough lid |

## Fonts

| Role | Font | Color | Notes |
|---|---|---|---|
| Titles (app name, screen titles, jar names, big numbers) | **Pansy** (Brocats) | `navy` | Final choice. Needs the font file + an **app embedding license** before release |
| Titles, for now | **Modak** (Google Fonts, free) | `navy` | Stand-in until Pansy is licensed |
| Body (numbers, notes, buttons, form fields) | **Nunito** (Google Fonts, free) | `softBlack` | Bold for emphasis and buttons |
| Secondary text | Nunito | `softBlack55` | |

---

## Parts

### Welcome screen (first screen when logged out)

Background `paleSky`, one color with no visible split.

```
┌──────────────────────────┐
│                          │
│     Doughn't Worry       │  Modak (→ Pansy), navy
│ I left a trail of crumbs │  Nunito Bold
│                          │
│ ─ ─ ─ ─ half ─ ─ ─ ─ ─ ─ │
│      [ monkey face ]     │  art comes later
│       (  Log in  )       │  dough buttons, black text
│       (  Sign up )       │
└──────────────────────────┘
```

- Top half: app name + subtitle.
- Bottom half: monkey face + **Log in** and **Sign up** buttons.
- Sign-in method: **email + password only** for now.

### Log in / Sign up forms

- Fields: email, password (+ confirm password on Sign up).
- Background `paleSky`, buttons `dough` with `softBlack` text.

### Bottom tab bar

Floating, **no border and nothing behind it**. Icons and names sit right on the page background.

```
     ⌂        ✎        △        ⚙
    Home   Journal    Bake   Settings
```

| State | Color |
|---|---|
| Active icon + name | `sky` |
| Inactive icon + name | `softBlack40` |

Each tab shows its icon on top and its name below. Icons are to be drawn or chosen later.

### Buttons

| Where | Look |
|---|---|
| **Home** | Shaped like **dough** (blobby, soft), to match the jars. Final shape comes with the jar art |
| **Everywhere else** | Minimalist: `dough` fill, `softBlack` Nunito Bold text, rounded |

### Jars (Home shelf)

- **No mood colors.** The face shows the status (Ready, Hungry, Thirsty, etc.), and the jar's **name** sits with it.
- **Lid color shows the type:**

| Type | Lid |
|---|---|
| Sourdough starter | `sky` `#5AB0FF` |
| Bread dough | `leaf` `#6CCB8B` |
| Pizza dough | `tomato` `#FF7A5C` |

- **Jar shape shows how it's used** (art comes later):
  - **Starter**: keeps going on its own; you feed it and take some out, and it never runs out.
  - **Pizza dough**: gets **split into portions** (dough balls); you take parts until it's gone.
  - **Bread dough**: used up at its own rate over one bake.

---

## To confirm (not decided yet)

- [ ] Card / panel color (e.g. white) for Journal entries, Settings rows, form areas
- [ ] Subtitle color on the welcome screen (`navy` or `softBlack`)
- [ ] Font sizes for titles, body and small text
- [ ] Error / warning color (wrong password, a Starving jar alert)
- [ ] Input field look (white bubbles? outline?)
- [ ] Tab bar icons

## Later (owned by Ezra)

- Jar art, faces, lids, dough-shaped buttons
- Proboscis monkey mascot
- Animations (jar zoom, rising dough)
- Pansy font license

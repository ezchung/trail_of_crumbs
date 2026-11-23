# Starter rules: how a jar picks its face

Every number here comes from **King Arthur Baking** (one source, no mixing). Where King Arthur gives no number, the app asks you instead of guessing. Those spots are marked **(no KA data)**.

These rules live in `SourdoughCore` as plain functions. The UI only displays the result.

## Sources

| Short name | Page | Used for |
|---|---|---|
| **KA-create** | [Sourdough Starter recipe](https://www.kingarthurbaking.com/recipes/sourdough-starter-recipe) | Baby schedule, "mature" test, 70–78°F |
| **KA-feed** | [Feeding and Maintaining](https://www.kingarthurbaking.com/recipes/feeding-and-maintaining-your-sourdough-starter-recipe) | 24 h schedule, weekly fridge feeding, waking up from the fridge |
| **KA-maintain** | [Maintain guide](https://www.kingarthurbaking.com/learn/guides/sourdough/maintain) | 12 h schedule, 1–2 h rest before fridge |
| **KA-ratios** | [Feeding ratios test (2025)](https://www.kingarthurbaking.com/blog/2025/03/13/sourdough-feeding-ratios) | Peak time per ratio (all tests at ~78°F) |
| **KA-hooch** | [Liquid on top](https://www.kingarthurbaking.com/blog/2023/08/28/liquid-on-top-of-sourdough-starter) | Starving, how long revival takes, pink streaks |
| **KA-forgot** | [Forgot to feed](https://www.kingarthurbaking.com/blog/2023/10/18/forgot-to-feed-starter) | Revival test, spoilage |

---

## What the app stores (inputs)

The face is **never stored**. It's worked out from these whenever the jar is shown:

- **Feedings**: time, grams of starter kept, flour g, water g
- **Location**: counter or fridge (with the time it moved)
- **Schedule** (counter only, picked per jar): every **12 h** (KA-maintain) or **24 h** (KA-feed)
- **Reports** (buttons in Jar detail): *I see liquid on top* (thin / lots or dark), *It's dry / thick*, *Pink or orange streaks*, *It peaked*, *It doubled*
- **Created at**, for Baby

## Feeding ratio → peak time

`ratio = flour g ÷ starter kept g`. Peak times come from KA-ratios (~78°F):

| Ratio | Ready starts | Ready ends (Hungry) |
|---|---|---|
| 1:1:1 | 4 h ("doubled by 4 hours") | 8 h ("starting to fall by 8 hours") |
| 1:2:2 | 8 h ("peaked at 8 hours") | the first scheduled feeding *after* it peaks **(no KA fall time)** |
| 1:4:4 | 12 h ("peaked by 12 hours") | the first scheduled feeding *after* it peaks **(no KA fall time)** |

Example: 1:4:4 on a 12 h schedule peaks at 12 h, exactly when it's due, so it stays Ready until 24 h instead of never showing Ready.

- **Not one of the three tested ratios:** use the nearest one (below 1.5 → 1:1:1, 1.5 to under 3 → 1:2:2, 3 and up → 1:4:4) and label the time an **estimate**.
- **Below 1:1:1:** do the same, and also show King Arthur's tip that 1:1:1 is the minimum feeding (KA-ratios).
- **It peaked** (tap): Ready starts now, whatever the clock says. This corrects every estimate.
- **Temperature** isn't used. King Arthur gives no formula for it, only that warmer means faster and that 70–78°F is ideal (KA-create).

## Faces, checked in this order (first match wins)

| # | Face | When | Tell the user | Source |
|---|---|---|---|---|
| 1 | **Spoiled** | *Pink or orange streaks* reported | Throw it out and start over. Offer: delete the jar, or restart it as Baby | KA-hooch, KA-forgot |
| 2 | **Starving** | *Liquid on top* reported, cleared by the next feeding | Stir it in or pour it off, then feed. *Lots or dark* liquid: "two or more days of twice-a-day feedings" | KA-hooch |
| 3 | **Sleepy** | In the fridge, fed less than 7 days ago | Nothing. Feed weekly | KA-feed |
| 4 | **Hungry** (fridge) | In the fridge, 7+ days since feeding | Weekly feed: keep 50 g, add 50 g flour + 50 g water, rest 1–2 h, back in the fridge | KA-feed, KA-maintain |
| 5 | **Baby** | New starter that hasn't had *It doubled* tapped yet | Follow the day plan below | KA-create |
| 6 | **Thirsty** | Last feeding had less water than flour, or *It's dry / thick* reported | Add water 1–2 tbsp at a time; target a "thick but easily stirrable paste" | KA-create (staff replies) |
| 7 | **Rising** | On the counter, before Ready starts | Wait | KA-ratios |
| 8 | **Ready** | Between Ready start and Ready end | Use it now | KA-ratios |
| 9 | **Hungry** | After Ready end | Feed it | KA-feed, KA-maintain |

The next feeding is **due** at `last feed + schedule` (12 h or 24 h). The face stays Hungry; "due" is used for notifications and for Ready end on 1:2:2 / 1:4:4.

> Thirsty sits above Rising/Ready/Hungry, so a dry jar shows Thirsty until the next feeding fixes it or the report gets cleared.

## Reviving (no extra face)

After **Starving**, or after taking a starter **out of the fridge**, the jar gets a *reviving* flag. Its face cycles Rising → Ready → Hungry as normal, but the Feed sheet says:

> Feed every 12 h until it doubles within 6–8 h. (KA-feed, KA-forgot)

Tapping *It doubled* clears the flag. Copious or dark hooch can take "two or more days" (KA-hooch). If it never rises after several feedings, it "really is dead" (KA-forgot).

## Baby day plan (KA-create, 50 g each)

| Day | Do this |
|---|---|
| 1 | 50 g whole wheat or pumpernickel + 50 g cool water. Wait 24 h |
| 2 | Keep 50 g, add 50 g water + 50 g all-purpose. Wait 24 h |
| 3–5 | Same feed, twice a day (~12 h apart) |
| 5+ | Ready when it "at least doubles in volume in about 6–8 hours." Keep going on days 6–7 if needed |

The jar becomes an adult starter once *It doubled* is tapped (KA: "once it reliably doubles after each feeding").

---

## Not covered yet

- **Bread / pizza dough jars** (Rising, Ready, Over-proofed) need their own King Arthur bread and pizza recipes. These get researched when the Bake tab comes up.

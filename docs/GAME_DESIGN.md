# Truth B Told: The Awakening — Game Design Document

Working title. v0.1 — June 12, 2026.

## Logline

Bro Truth, a regular man living a regular St. Louis life, finds a hidden book
in a red-brick alley. When he opens it, the veil
over the world tears — he begins to see the lies, the agents who guard them,
and the spirits behind them. Guided by the Truth B Told family, he walks the
book's chapters through time — Enoch, Abraham, Joseph, Moses — gathering
gifts of knowledge to face the present and uncover who his people really are.

## Pillars

1. **Awakening IS the gameplay.** Discernment (book vision) is the core verb —
   every puzzle, fight, and secret runs through seeing what's hidden.
2. **The Book is everything.** It's the menu, the skill tree, the map, the
   journal, and the time machine. The player never leaves the fiction.
3. **Action serves revelation.** Combat and puzzles exist to deliver truths,
   not the other way around. Every encounter ends in something learned.
4. **Mobile-first.** Touch controls, 5–10 minute quest beats, 60fps on
   mid-tier Android.

## Genre & platform

Action-adventure with a puzzle core. Godot 4.4, Mobile renderer.
Android/iOS first; desktop export is free with Godot.

## Setting — St. Louis, the Mound City

Present-day **St. Louis, MO** — Bro Truth's city of origin. Red-brick alleys,
the riverfront, downtown, and the north side for street levels.

**The Mound City thread.** St. Louis earned that nickname from the dozens of
Mississippian mounds that were leveled as the modern city grew — erased
history, literally under the streets. In Discernment, the ghost-outlines of
the leveled mounds glow up through the asphalt. Mound sites — including
Sugarloaf Mound, the last one still standing, and the great Cahokia complex
across the river — serve as study points, Oil refills, and Witness locations.
The erasure of the mounds mirrors the game's core theme: the truth wasn't
lost, it was buried.

**The Gateway Arch is a literal gateway.** The "Gateway to the West" is
revealed at the end of Act 2 as a colossal veiled portal (cutscene CS-07) —
and in Act 3 it becomes the way through.

## Story structure

### Act 1 — Sleep (the Matrix-parallel act, up to the awakening)

- Ordinary life. The opening quests are deliberately mundane — commute, work,
  errands — doubling as the tutorial.
- Glitches: a billboard flickers to something darker for one frame, a stranger
  stares too long, a déjà vu NPC repeats.
- An errand sparked by a message from **Lala** — the words that begin the
  mission — routes Bro Truth through a red-brick alley → **the hidden Book**
  in a broken wall cavity (cutscene CS-02).
- Opening it = the awakening (CS-03). First Discernment. The city never looks
  normal again.
- First contact with the Veil (CS-04), rescue by Truth B Told (CS-05).

### Act 2 — The Family & the Chapters

- Hub: the TBT safehouse in north St. Louis — maps, scripture, a timeline wall.
- The central mystery: **the 400-year prophecy (Genesis 15:13)**. The player
  assembles it as collectible **Witness** entries — each one a document,
  vision, or testimony tying the prophecy → the transatlantic slave trade →
  the identity revelation: who the captives' descendants really are.
- **Jasher Jumps**: the Book pulls the Lead into its chapters (see Mechanics).
  Each jump returns a permanent Gift that unlocks new areas and truths in the
  present.

### Act 3 — The Veil's counterattack & the choice

Outline only — to be developed once the Act 1–2 vertical slice is proven.
Known anchor: the Gateway Arch portal opens (CS-07), and the endgame goes
through it.

## Release structure — five Parts

The game ships episodically as **five Parts**. Each Part ends with a complete
arc — a proper ending — that is clearly not final.

| Part | Title | Covers | Ending (complete, not final) |
|---|---|---|---|
| 1 | **The Awakening** | Act 1 → safehouse → Enoch jump → first Gift | Bro Truth commits to the mission; final shot: a Watcher photographing the safehouse door — the Veil knows where they are |
| 2 | **The Furnace** | Abraham chapter; the prophecy thread opens | First Witness thread completed; a name surfaces inside the Veil |
| 3 | **The Dreamer** | Joseph chapter; the Veil strikes back | Dream Sight foretells "the Gateway"; the safehouse is compromised |
| 4 | **The Deliverer** | Moses chapter; the timeline wall completes | CS-07 — the Arch ignites. The biggest cliffhanger in the game |
| 5 | **The Gateway** | Act 3, through the Arch | Finale |

**Ship one app.** Parts are content updates / in-game unlocks inside a single
app — never five separate store listings. Saves carry forward automatically,
ratings and installs accumulate on one listing, and returning players just
update instead of re-downloading.

## Save system

**v1 — local-first (built):** the `SaveManager` autoload writes versioned
JSON to `user://saves/` (slot-based). Autosaves on every meaningful pickup
and checkpoint. Works fully offline — non-negotiable on mobile. Tracks:
schema version, current Part/checkpoint, Gifts, Witness entries, Oil,
playtime.

**v2 — cloud sync (later):** mirror the same JSON to Firebase per account
for cross-device continuity. Local stays the source of truth; the cloud is a
mirror, so the game never requires a connection.

## Core loop

Explore the present → **Discern** the hidden layer → solve / fight / cast out →
find Book pages & Witness entries → **Jasher Jump** → return with a Gift →
new areas and deeper truths open up.

## Mechanics

### Discernment (book vision)

Hold a button to see the world's true layer: hidden glyphs over doorways,
spiritual chains on the streets, the demonic presence riding a human agent,
walkable paths that don't exist in the false world. Costs **Oil** (a lamp
meter), refilled at study/meditation points. Risk/reward: most threats can
only be fought *while* Discerning, and the meter drains in combat.

### Combat — deliverance, not killing

Human agents are people under influence — a spirit rides them. You never kill
humans; you **cast out** what's riding them (stagger the body, Discern,
strike the spirit). Demons are fought directly, but only visible in
Discernment. This is thematically right *and* keeps the game ratable for
mobile stores.

- Early kit: dodge, staff/rod melee.
- Later: "Word" projectiles (unlocked via Gifts), crowd-parting, phase-walk.

### Puzzles

- Scripture-cipher locks (verse fragments → combinations)
- Hebrew letter matching / reconstruction
- Light-and-shadow alignment (only solvable in Discernment)
- The prophecy timeline board — assembling the 400-year thread from Witness
  entries is itself the Act 2 meta-puzzle.

### Jasher Jumps (the time chapters)

Each past chapter is a **self-contained 10–15 minute trial** playing as a
figure from the Book, reusing the same controller with a swapped environment
and one unique mechanic. Each grants one permanent **Gift** used back in the
present (Metroidvania-style gating). The Lead's silhouette — the shoulder-
length dreadlocks — stays recognizable in every era as the identity anchor.

| Chapter | Figure | Trial | Gift (back in the present) |
|---|---|---|---|
| 1 | **Enoch** | Walk the path of light before the flood; learn the heavens | **Walking With God** — phase through veil barriers |
| 2 | **Abraham** | Nimrod's furnace; stand in the fire | **Unburned** — pass through corrupted zones |
| 3 | **Joseph** | From the pit to the palace; read the dreams | **Dream Sight** — preview puzzle solutions, foresee ambushes |
| 4 | **Moses** | Confrontation and exodus | **The Rod** — combat upgrade; part hostile crowds |

More figures can slot in later — the structure is one trial + one Gift each.

### Truth B Told family cameos

The founding five are cast — **Bro Rashaud** (the Guide), **Sister Lola**
(the Trainer), **KB** (the Scribe), **Christina B.** (the Provider), and
**Lala** (the Spark, on comms). They appear as safehouse NPCs, mission
handlers, trainers, and scripted rescuers. Roster and likeness specs live in
[CHARACTERS.md](CHARACTERS.md) — data-driven so more family members can be
added without touching story code.

## Enemies

**The Veil (human, ridden):**
- *Watchers* — ordinary-looking civilians who track you; harmless until they call it in
- *Agents* — suits; the spirit riding them is visible only in Discernment
- *Handlers* — mini-bosses; the spirit fights back when cast out

**Principalities (spirit, Discernment-only):**
- *Whisperers* — fear debuffs, distort the screen
- *Chains* — bind movement, anchor puzzle locks
- *Gatekeepers* — bosses guarding each major truth

## Mobile design

- **Controls:** left virtual stick; right-side context cluster (Discern,
  interact, dodge); auto-aim on Word projectiles.
- **Sessions:** 5–10 minute quest beats; checkpoint at every truth found.
- **Performance budget:** 60fps on mid-tier Android → < 150k triangles per
  scene, baked lighting, one dynamic light for Discernment mode. Art style
  choice is the biggest perf lever — see [ART_STYLE.md](ART_STYLE.md).

## Cutscenes

**Production order: gameplay first.** Every cutscene slot plays a simple
title-card placeholder until its video lands, so scenes can be inserted after
the build without touching game code. Generated externally with Grok from the
shot-by-shot scripts in [CUTSCENE_SCRIPTS.md](CUTSCENE_SCRIPTS.md), stitched,
converted to `.ogv`, and played via `VideoStreamPlayer`. Voice-over and
subtitles are added in-engine. Keep scenes ≤ 60 seconds.

## Open questions

- [x] The Lead's in-game name — **Bro Truth**
- [x] Art style — **A, stylized low-poly** (cel-shade evolution later; see ART_STYLE.md)
- [x] TBT roster — founding five cast (CHARACTERS.md); likeness details to refine
- [x] City — **St. Louis, MO** (Mound City / Gateway Arch threads)

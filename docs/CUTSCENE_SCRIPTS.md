# Cutscene Scripts — Grok generation pipeline

Every scene below is broken into **shots**, because video generators work in
short clips (~6–10 seconds each). Generate each shot as its own clip, stitch
the shots into one scene in your editor, then convert to `.ogv`
(see `assets/cutscenes/README.md` for the ffmpeg command).

**Rules for consistency:**

1. Paste the **Character Block** at the top of *every* prompt that shows the Lead.
2. Use the same reference image of the Lead across all generations if Grok
   supports image references — lock the face once, reuse it forever.
3. Generate clips **dialogue-free**. Voice-over and subtitles are added
   in-engine (generated lip-sync drifts and breaks immersion).
4. 16:9 landscape, 1080p.

---

## CHARACTER BLOCK (paste into every prompt)

> [LEAD] (BRO TRUTH): African American man in his mid-30s, shoulder-length
> dreadlocks, athletic build, wearing a dark olive hoodie under a worn denim
> jacket, jeans, white sneakers.

*(Tweak this block to match your actual likeness — skin tone, beard, build,
outfit — or replace it with a reference photo. Once it's right, never change
it between scenes.)*

---

## CS-01 — "Routine" (opening montage, before the title card)

**Purpose:** establish normal life; plant the first glitch.
**Placement:** game start. **Target length:** ~30s.

| Shot | Prompt (after the Character Block) | VO / notes |
|---|---|---|
| 1 | Dawn breaking over the St. Louis skyline, the Gateway Arch silhouetted in golden haze above the Mississippi River, birds crossing frame, cinematic establishing shot | — |
| 2 | [LEAD] in a small apartment, morning routine — alarm, mirror; he pauses at his own reflection a beat too long, subtle unease | VO: "Same bus. Same faces. Same noise." |
| 3 | Commute montage from a bus window: crowds with heads down in phones, walls of glowing billboard ads, gray light | VO: "I used to think that's all there was." |
| 4 | Close-up of a phone in [LEAD]'s hand; an unread message lights the screen, sender "LALA" | Message text rendered in-engine (don't trust Grok with text): **LALA:** "You ever think about using that voice of yours? Somebody's got to tell the truth." — the mission begins with her words. |
| 5 | Close on one digital billboard; its colors flicker — for a single frame something darker shows underneath, then back to the ad | The first glitch. Hold the dark frame 2–3 frames only. |

---

## CS-02 — "The Alley"

**Purpose:** finding the Book.
**Placement:** end of the Level 1 errand quest — the errand Lala's message set in motion — when it routes him off the main street.
**Target length:** ~25s.

| Shot | Prompt | VO / notes |
|---|---|---|
| 1 | Rain-slick narrow alley between old St. Louis red-brick buildings at dusk, steam from a vent, one last beam of sunlight cutting down onto a recess in the worn brick wall | — |
| 2 | Inside a broken wall cavity: an old leather-bound book wrapped in rough cloth, untouched by the rain | — |
| 3 | Close-up: a man's hand brushing dust off embossed letters on the leather cover; the letters catch light and faintly glow | VO: "It wasn't lost. It was waiting." |

---

## CS-03 — "Opening" (THE awakening — the biggest scene in Act 1)

**Purpose:** the red-pill moment. Spend the most generation attempts here.
**Placement:** immediately after the player chooses to open the Book.
**Target length:** ~60s.

| Shot | Prompt | VO / notes |
|---|---|---|
| 1 | [LEAD] opens the heavy cover of an ancient book in a dim alley; warm golden light floods up from the pages onto his face | — |
| 2 | Pages turning by themselves, faster and faster, ancient script lifting off the paper as glowing letters in the air | — |
| 3 | The alley walls peel away like burning paper, revealing a second world layered underneath the first: chains of shadow over the streets, glowing symbols burning above doorways, dark watching figures on the rooftops | The money shot. |
| 4 | Extreme close-up of his eyes, moving script reflected in them, pupils widening | — |
| 5 | He slams the book shut, breathing hard — but the city behind him does NOT return to normal; the symbols remain | VO: "And once you see… you can't unsee." |

---

## CS-04 — "Watchers" (first sight of the Veil)

**Purpose:** the world is now watching him back.
**Placement:** first street section after the awakening.
**Target length:** ~20s.

| Shot | Prompt | VO / notes |
|---|---|---|
| 1 | A city street at night; across the street an ordinary man in plain clothes stands perfectly still, staring directly into camera, too long | — |
| 2 | Same framing, flash transition: a towering shadow figure stands behind and through the staring man, smoke-like, only its eyes lit | The first demonic presence — riding a human. |
| 3 | Down the block, every person holding a phone turns it toward camera in unison | — |

---

## CS-05 — "The Family" (meeting Truth B Told)

**Purpose:** rescue + introduce the community.
**Placement:** end of the first chase/escape sequence.
**Target length:** ~40s.

| Shot | Prompt | VO / notes |
|---|---|---|
| 1 | [LEAD] cornered at the dead end of an alley at night, breathing hard, headlights growing behind him | — |
| 2 | A steel door swings open beside him, warm light spilling out, a strong hand pulls him inside | — |
| 3 | Interior: a safehouse with warm light — walls covered in maps, scripture pages, photographs, and a long pinned timeline stretching across one wall with "GENESIS 15:13 — 400 YEARS" at its head | The timeline wall = Act 2's meta-puzzle, seen here first. |
| 4 | Hero shot: BRO RASHAUD — African American man, deep mystic presence, long locs under a black skully, calm penetrating gaze — steps forward into the candlelight | Line (subtitled in-engine): **BRO RASHAUD:** "You opened it. Then you already know — truth don't hide. It's *hidden*. Different thing." |
| 5 | Hero shot: SISTER LOLA — African American woman of Haitian descent, 5'5", warrior bearing, arms crossed, firelight catching her eyes | The Trainer. |
| 6 | Hero shot: KB — African American man, 20 years old, tall and slim, baseball cap, notebook in hand, standing at the timeline wall | The Scribe. |
| 7 | Hero shot: CHRISTINA B. — white woman, 35, sharply dressed, warm intelligent expression, unlocking a supply room stacked with gear | The Provider. |
| 8 | Hero shot: LALA — white woman, 35, warm encouraging presence at a comms desk, headset around her neck, smiling like she's been waiting for him | The Spark — her message in CS-01 started all of this. |

---

## CS-06 — "The First Walk" (Enoch transition — into the first Jasher Jump)

**Purpose:** establish the time-jump language used for every chapter.
**Placement:** end of the first safehouse sequence.
**Target length:** ~35s.

| Shot | Prompt | VO / notes |
|---|---|---|
| 1 | The ancient book lying open on a candlelit wooden table; the camera dives down INTO the page | — |
| 2 | Ink on parchment swirls and becomes a living landscape — an ancient world before the flood, green and vast under an enormous sky | — |
| 3 | A robed figure walks a path of light up a mountainside under wheeling stars — his silhouette shows shoulder-length locks | The dreadlocks silhouette is the identity anchor in every era. Keep it. |
| 4 | Stars wheel overhead in accelerated motion; the path of light continues past the summit into the sky | VO: "Enoch walked with God. Tonight… I walk where he walked." |

---

## CS-07 — "The Gateway" (the Arch reveal — end of Act 2)

**Purpose:** reveal the Gateway Arch as the Veil's great portal and Mound City's buried truth in one scene.
**Placement:** after the final Witness entry completes the timeline wall.
**Target length:** ~45s.

| Shot | Prompt | VO / notes |
|---|---|---|
| 1 | The Gateway Arch at night seen from the riverfront, mist rolling off the Mississippi, the city lights quiet behind it | — |
| 2 | Discernment flash: ancient glowing glyphs ignite along the entire span of the Arch revealing it as a colossal gate; beneath the modern streets, ghost-outlines of great earthen mounds glow up through the asphalt across the whole city | Mound City revealed — the buried truth under St. Louis. |
| 3 | The air between the legs of the Arch ripples like water; a column of golden light opens beneath the span | — |
| 4 | [LEAD] and five companions silhouetted on the riverfront steps, facing the open gate | VO: "They called it the Gateway to the West. They never told us what it was a gateway *to*." |

---

## Template for new scenes

```
## CS-XX — "Title"

**Purpose:**
**Placement:**
**Target length:**

| Shot | Prompt (Character Block first if the Lead appears) | VO / notes |
|---|---|---|
| 1 |  |  |
```

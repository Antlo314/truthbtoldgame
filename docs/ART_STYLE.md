# Art Style Options

> **DECIDED (June 2026): Option A — stylized low-poly.** Cel-shaded (B)
> stays on the table as the later evolution target. Gameplay feel comes
> first; the style serves it.

Four candidate directions for the 3D look. The choice drives the performance
budget, the asset pipeline, and how well the in-game look matches the
Grok-generated cutscenes. To see all four on the Lead at once, paste the
prompt in the appendix at the bottom of this file into Grok.

## A — Stylized Low-Poly (flat-shaded)

Reference feel: Quaternius / Kenney asset packs, *Superhot*, modern indie low-poly.

- **Mobile perf:** ★★★★★ — easily 60fps on cheap phones
- **Asset cost:** lowest. Huge free ecosystems (Quaternius, Kenney) cover
  city, characters, and props; Mixamo animations retarget cleanly
- **Identity:** the dreadlocks silhouette reads great in low-poly
- **Risk:** biggest visual gap vs. cinematic Grok cutscenes — mitigate by
  prompting the cutscenes stylized rather than photoreal

## B — Cel-Shaded / Toon (ink outlines)

Reference feel: *The World Ends With You*, Spider-Verse energy, graphic novel.

- **Mobile perf:** ★★★★ — toon shading + outline pass is cheap in Godot
- **Asset cost:** medium — needs consistent custom texturing; fewer free packs fit
- **Identity:** strongest. The prophetic-vision / hidden-truth theme *sings*
  in a graphic-novel look; Discernment mode can shift the ink style
- **Risk:** more custom art time per asset

## C — Hand-Painted Stylized

Reference feel: *Kena: Bridge of Spirits*, heroic proportions, soft painterly textures.

- **Mobile perf:** ★★★ — fine with discipline, but textures get heavy
- **Asset cost:** highest for a consistent look; mixed marketplace assets clash
- **Identity:** warm and broadly appealing
- **Risk:** the "asset flip" look if sourcing isn't strict

## D — Realistic / Cinematic

Reference feel: AAA console.

- **Mobile perf:** ★ — fights the phone the whole way
- **Asset cost:** extreme; faces fall into the uncanny valley fast
- **Identity:** matches Grok cutscenes 1:1, but everything else suffers
- **Verdict:** not recommended for a mobile-first project

## Recommendation

**Start with A (low-poly) for the vertical slice — it's the fastest path to a
playable build — and treat B (cel-shaded) as the evolution target if the
slice proves the game.** A toon shader can be layered onto low-poly assets
later without redoing them, so A → B is a smooth upgrade path. D is off the
table for mobile.

## Appendix — Grok prompt for the comparison sheet

Paste this into Grok's image generator to see the Lead in all four styles in
one image (tweak the character description to match your likeness first):

> Video game character art style comparison sheet, a single image divided
> into a clean 2x2 grid of four panels, each panel showing the SAME character
> rendered in a different 3D video game art style, each panel with a small
> clean text label in its corner. Character in all four panels: African
> American man in his mid-30s, shoulder-length dreadlocks, short beard,
> athletic build, wearing a dark olive hoodie under a worn denim jacket,
> holding an ancient leather-bound book glowing with warm golden light,
> standing in a moody rain-slick city alley at dusk. Panel 1 (top-left,
> label "A — LOW-POLY"): flat-shaded stylized low-poly 3D render, visible
> facets, bold simple colors, minimal textures. Panel 2 (top-right, label
> "B — CEL-SHADED"): cel-shaded toon 3D with bold ink outlines, graphic-novel
> shading, halftone accents. Panel 3 (bottom-left, label "C — HAND-PAINTED"):
> hand-painted stylized 3D, soft painterly textures, heroic stylized
> proportions like Kena Bridge of Spirits. Panel 4 (bottom-right, label
> "D — REALISTIC"): realistic cinematic 3D game render, PBR materials,
> detailed skin and fabric, dramatic rim lighting.

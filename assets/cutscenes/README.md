# Cutscene videos

Drop your Grok-generated clips here. Two things to know:

1. **Godot only plays Ogg Theora (`.ogv`) natively.** Convert each mp4 first:

   ```
   ffmpeg -i cs01_routine.mp4 -c:v libtheora -q:v 7 -c:a libvorbis -q:a 5 cs01_routine.ogv
   ```

2. **Naming convention:** `cs<scene#>_<shortname>.ogv` matching the scene IDs in
   `docs/CUTSCENE_SCRIPTS.md` (e.g. `cs03_opening.ogv`). Multi-shot scenes get
   stitched into one file in your editor before converting.

Voice-over and subtitles are added in-engine, not in Grok — keep the generated
clips dialogue-free.

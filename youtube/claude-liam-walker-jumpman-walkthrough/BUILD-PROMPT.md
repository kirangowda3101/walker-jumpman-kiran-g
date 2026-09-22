# BUILD-PROMPT — The Fork That Wasn't.

Paste-ready prompt that rebuilds this reel end to end. Never publishes, never
pushes, never calls a paid API.

---

```
Rebuild the walker-jumpman walkthrough reel at
/Users/kiran/Documents/walker-jumpman-kiran-g/youtube/claude-liam-walker-jumpman-walkthrough
using the brutalist.art godot-waikthrough skill in `walker` mode.

Read first, in this order:
  ~/Documents/brutalist.art/skills/make/godot-waikthrough/SKILL.md
  ~/Documents/brutalist.art/skills/make/godot-waikthrough/references/capture-and-coverage.md
  ~/Documents/brutalist.art/skills/make/riff/SKILL.md
  ~/Documents/brutalist.art/skills/make/ai-explainer/SKILL.md
  ~/Documents/brutalist.art/OUTRO-LOCK.md
  ~/Documents/brutalist.art/RENDER-TARGETS.md
  ~/Documents/brutalist.art/docs/PIPELINE-SAFETY.md
  the reel's own CAPTURE.md, SHOTLIST.md, FACTCHECK.md, PROMPTS.md, RIFF.md

Hard constraints:
  * Do NOT modify anything under walker-jumpman-kiran-g/godot/. Capture from an
    rsync copy in a scratch directory with capture/capture_driver.gd added.
  * Gameplay must be real engine output through the real input path
    (Input.parse_input_event for held keys, SubViewport.push_input for UI keys).
    Never use player.test_control / test_axis / test_jump_pressed.
  * Native 3840x2160: run the session in a 3840x2160 SubViewport with
    Camera2D.zoom = 6 and a 6x HUD CanvasLayer transform. The display is smaller
    than 4K, so an OS window would be clamped.
  * Every media/<beat>.mp4 for a gameplay beat is a byte copy of its capture.
    Set actual_duration_s = frames/30 so the compositor ratio is exactly
    1.000000. Fit narration inside that window with silence; never retime,
    trim, slow or centre-cut gameplay.
  * The outro follows OUTRO-LOCK.md: exact title, hardcoded @NikBearBrown,
    slug-seeded mascot, NO subline, spoken never scored, 1 s silent tail.
  * Never publish, never push, never upload.

Steps:
  1. Recapture if the game source changed (the build_id in coverage.json is a
     SHA-256 over a manifest of every file under godot/ excluding .godot/).
     Run each take twice and require identical tick and frame counts.
     run-05 must be run on its own — it demonstrates focus-loss auto-pause and
     needs the window to actually hold focus.
  2. cd ~/Documents/brutalist.art
     ./art godot-waikthrough --check <REEL>
  3. python3 runtime/scripts/generate_audio_kokoro.py <REEL>
  4. Conform audio to the slots: pad each beat's mp3 with lead/trailing silence
     to exactly frames/30, and rewrite actual_duration_s to match.
     Lead-ins: B01 0.8, B02 0.4, B03 0.3, B04 1.0, B05 0.2, B06 1.2.
  5. python3 runtime/scripts/remotion_scenes.py <REEL>
  6. Re-run step 4 against the rendered bookend frame counts so every slot lands
     at ratio 1.000000, then ./art godot-waikthrough --check <REEL> again.
  7. ./art final <REEL> --height 2160 --fps 30 --out <REEL>/exports/landscape
  8. Visual QC: sample frames at >= 2 fps plus each beat at 15/50/85% of its
     span, actually read the PNGs, audit the 9-point rubric, and write
     _qc/REPORT.md. Fix root causes and re-render until zero BLOCKER/MAJOR.
  9. Report the absolute mp4 path, a quoted `open` command, feature coverage,
     limitations and QC results. Do not upload.
```

---

## Notes for whoever runs this

**The dimming scrim.** `hud.gd` draws a translucent panel over the play area on
the menu, pause and completion screens. If the frame checker's flat-card
contrast heuristic fires on B02, B04 or B05, inspect the actual pixels before
touching anything — the text under the scrim is legible at 4K. Declare named
`qc.contrast_regions` with a written `qc.contrast_reason` on the specific beat
rather than relabelling gameplay or suppressing the check.

**run-05 is environment-sensitive by design.** It demonstrates the game pausing
itself when the OS window loses focus, so it fails if the window never had
focus. It fails deterministically and loudly ("not playing before the focus
test"); it does not fail quietly.

**Do not run pantry intake on the captures.** Its stripping and retiming
behaviour is not an evidence-preserving edit.

**If a capture changes, its hash changes.** `coverage.json` records the SHA-256
of each capture file; the evidence gate will reject a stale pairing.

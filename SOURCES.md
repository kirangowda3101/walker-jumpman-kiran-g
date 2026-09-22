# SOURCES — walker-jumpman-kiran-g

**Student:** Kiran Gowda Ramanagara Jayaram
**Course:** CSYE 7270, Fall 2026 — Assignment 1

Credits for the starter, tools, and assets, and an account of what the AI
contributed versus what I decided, checked, changed, or rejected.

---

## Starter

This project is an extension of **walker-jumpman**, the "First Steps" playable
slice, by Nik Bear Brown:

https://github.com/nikbearbrown/walker-jumpman

Cloned on 18 September 2026 and developed in my own repository. The starter's
commit history is preserved in this repository, so the boundary between the
original work and mine is visible in `git log`.

**What the starter provided:** the Godot project structure, the movement model
in `player.gd` and `tuning.gd`, the session and drawing code in `session.gd`, the
HUD, the level data format, the mechanics and keyboard test suites, the route
driver fixture, and the design package (`GDD.md`, `LEVEL-DESIGN.md`,
`PLAYTEST-PLAN.md`, `BUILD-REPORT.md` and the rest).

**What I added or changed:**

| File | Change |
|---|---|
| `godot/features/player/player.gd` | Rewrote `_draw()` entirely — ninja character |
| `godot/levels/first_steps.json` | Rewrote the level; width 960 → 1920 |
| `godot/game/session.gd` | Made grid, backdrop, hills and FINISH label data-driven; fixed the hazard drawing; added zone 03 caption and a wayfinding hint |
| `godot/tests/route_driver.gd` | Extended `jump_marks` from 5 to 10 entries |
| `scripts/check_reachability.py` | New |
| `scripts/sim.py` | New |
| `scripts/solve.py` | New |
| `CHANGE-BRIEF.md`, `TEST-REPORT.md`, `FRICTIONAL.md`, `SOURCES.md` | New |
| `README.md` | Updated |
| `evidence/` | Test receipts and screenshots from this work |

**Unchanged, deliberately:** `godot/features/player/tuning.gd` — every movement
constant is exactly as shipped. The 18x28 collider in `player.gd::_ready()` is
also untouched. No collision check was removed, weakened, or bypassed.

---

## Assets

**None imported.** Every visual in this project is original geometric drawing
executed in code — `draw_rect`, `draw_line`, `draw_colored_polygon` and
`draw_string` calls in `player.gd` and `session.gd`. There are no image files,
no sprite sheets, no fonts beyond Godot's built-in `ThemeDB.fallback_font`, and
no audio.

The starter's own `ASSET-PLAN.md` describes the same greybox-only boundary, and
this extension stays inside it. No paid asset or generation service was used.

---

## Tools

| Tool | Use |
|---|---|
| Godot 4.7.2.stable.official.ed1daf0bf | Engine, editor, and headless test runner |
| Claude (Anthropic), via the chat interface | Code generation, explanation, and document drafting |
| Python 3.12 | The three verification scripts; standard library only, no packages |
| git | Version control |
| macOS 15, Apple M4 | Development machine |

No purchased API credits or paid services were used. Access to Claude was through
my Northeastern student access, as the assignment permits.

---

## Human and AI contributions

This is the honest split. The short version: **the AI wrote most of the code and
most of the prose; I made the decisions, did all the testing, and rejected what
did not work.**

### What the AI produced

- All GDScript for the ninja character, across four iterations
- All level coordinates, across roughly eight layouts
- All three Python scripts: `check_reachability.py`, `sim.py`, `solve.py`
- The drafts of `CHANGE-BRIEF.md`, `TEST-REPORT.md`, `FRICTIONAL.md` and this file
- Explanations of the starter's code that I used to understand it
- Diagnosis of most failures from the coordinates the tests reported

### What I decided

- The ninja concept, and every judgment on whether an iteration looked right
- To keep the headband sway at 0.3 after trying 0.9 — the faster version did not
  read as cloth of that size
- To keep the crimson sash after testing it against the red spikes rather than
  changing it pre-emptively
- To fix the hazard-drawing defect rather than document it and leave it
- To fix the visual/data coupling by deriving from `level.width` rather than
  typing in new constants
- Which of the offered approaches to take when the fork did not work — I chose
  making the high route faster over adding a collectible
- To stop hand-tuning the level and require the physics be simulated instead
- To extend the reachability checker after it missed a bug, rather than simply
  patching the level
- To generate the test fixture's jump marks rather than continue tuning them
- To ship with no external playtester and state that plainly, rather than
  invent one

### What I rejected

- Three sword implementations: invisible in the torso colour, hidden behind the
  18-wide body, and a fourth version so long it read as a staff
- The headband sway at 0.9
- A proposed collectible feature, on the grounds that it would paper over a fork
  that did not yet work
- Several level layouts that failed on play

### What I found that the tools did not

- **The blocked low route.** A high platform 32 px above the ground slab left
  16 px of headroom for a 28 px player. Found by walking into it.
- **The unjumpable spike cluster.** 32 px of clearance is enough to stand under
  but not to jump in. Found by playing the ground route. The reachability checker
  had passed that spot, because it only tested standing height. I then had the
  checker extended so it would catch this class of defect.

### Where the AI was wrong

Recorded because the assignment asks for it, and because it is relevant to how
much weight the AI's output should carry:

- It produced roughly eight level layouts that did not work, including one where
  the ground route was impossible and one where a spike cluster could not be
  jumped
- It hand-calculated jump arcs with the analytic projectile formula, giving a
  53.3 px apex, when the engine's true discrete value is 56.00 — a 2.7 px error
  that contributed to several of those failures
- It proposed a stale-cache explanation for a test failure that turned out to be
  wrong; clearing the cache changed nothing, and the real cause was that the
  fixture was airborne and the jump marks were never firing
- Its first simulator-generated set of jump marks completed in the simulator but
  died in the engine, because the marks fired inside the coyote-time window

### Verification

Every test run, every play session, and every timing in this submission was
performed by me. The AI never ran the game. All results in `TEST-REPORT.md` are
things I observed on my own machine.

---

## Film

**The Fork That Wasn't.** — 2:47, 3840x2160, 30 fps, rendered 22 September 2026.

    youtube/claude-liam-walker-jumpman-walkthrough/exports/landscape/claude-liam-walker-jumpman-walkthrough.mp4
    sha256  a6a46018fdf342300cb94f5dc6886b6c0f2add217da710d8c6a17e9d4bbf329a

Produced with the course-provided Brutalist `godot-walkthrough` workflow using
the `walker` modifier. Its own credits are in
`youtube/claude-liam-walker-jumpman-walkthrough/SOURCES.md`; the short version:

**Captured gameplay (real engine output).** All 61.7 s of gameplay is a real
Godot 4.7.2 run of this project, captured at native 3840x2160 across five
takes. The game source under `godot/` was not modified; capture ran against a
copy with one added `capture_driver.gd`, which is committed with the reel. The
driver drives the game through its real input path and never uses the
`test_control` / `test_axis` / `test_jump_pressed` hooks that `route_driver.gd`
relies on. Each capture's SHA-256 is recorded in `coverage.json`, and the five
gameplay slots in the finished film are byte-identical to those captures.

**AI-generated.** The narration voice (local Kokoro-82M, `am_onyx` — free, no
API); the script and beat sheet; the capture driver; the jump-mark search for
the ground route; the five Claude bookend scenes (Remotion, deterministic,
seeded); and the reel's documents.

**Declared, not hidden.** The opening Walker prompt is an *illustrative
reconstruction* — no Walker transcript exists for this project, since it
extends an existing starter — and it is labelled as such on screen, in the
narration and in the reel's `PROMPTS.md`. No fictional build log or progress
receipt appears anywhere in the film.

**Not claimed.** No human playtested the game for the film. The captures are
scripted input, labelled `scripted-input` in `coverage.json`, and the missing
external playtester is stated out loud in the film's verdict. The only human
play evidence for this project remains my own, in `TEST-REPORT.md` section 5.

**One thing the film found that these documents did not.** `godot/ui/hud.gd:24`
computes the progress bar as `(x - 64) / 852` — the starter's 960-wide span.
The level is now 1920 wide with the finish at 1620, so the bar fills at x=916
and stays full for the rest of the run. `hud.gd` is listed as unchanged above,
and that is accurate: the defect is inherited from the starter and my
presentation-fix pass on `session.gd` never reached the HUD. It is in the
film's verdict and in the reel's `FACTCHECK.md`.

---

## Collaborators

None. This is individual work. No other student contributed to the code,
documents, or testing, and no external playtester was involved.

# walker-jumpman-kiran-g

**CSYE 7270, Fall 2026 — Assignment 1: Extend Walker Jumpman**
Kiran Gowda Ramanagara Jayaram · Godot 4.7.2.stable.official.ed1daf0bf · macOS

An extension of **[nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman)**,
the "First Steps" playable slice. This is not a new game: the starter's movement
model, session code, HUD, level format and test suites are all retained, and its
commit history is preserved in this repository so the boundary between the
original work and mine is visible in `git log`.

---

## Run it

Install Godot **4.7.2** (standard build, not .NET) from
[godotengine.org](https://godotengine.org/download). Then either:

- Import `godot/project.godot` in the Godot editor and press **F5**, or
- With Godot in `/Applications`, double-click `walker-jumpman.command`

No .NET runtime, no external assets, no packages.

**Controls:** **Enter** to start · **A/D** or arrows to move · **Space** to jump ·
**R** to retry · **Escape/P** to pause. Reach the flag. Retries are unlimited.

---

## What I changed

### Character — a ninja

The starter's player is seven `draw_rect` calls making a uniform 18-wide block.
Mine is a hooded figure with a tapered head, a mask slit, a sash, a sword slung
across the back and a headband that trails behind whichever way you face.

- The silhouette changes along its height rather than being one slab
- Three readable states: standing, running, and a distinct airborne tuck
- Left/right is handled by one `draw_set_transform` canvas mirror rather than
  per-line coordinate ternaries
- All original geometric drawing. No imported art, no sprite sheets, no fonts
  beyond Godot's built-in fallback

The 18x28 collider and every value in `tuning.gd` are **unchanged**.

### Level — a branching third zone

The level grows from 960 to 1920 wide. Past the starter's two zones, a third
section offers two ways to the finish, which now sits on a raised shelf.

- **High route.** Two steps up, then a long runway straight onto the shelf.
- **Ground route.** Stay low, clear four spike clusters, and discover the flag
  is unreachable from below. The only climb is past the far east end, and the
  stepping stone above it sits 96 px over the ground — beyond the 56 px jump
  ceiling — so it cannot be shortcut. You climb, then hop back west and walk
  back to the flag.

The ground route is slower because it is physically longer. Measured: **high
10.1 s, ground 13.6 s**. The solver's optimum is 9.73 s and 11.87 s.

The starter's original section is untouched and still fully playable.

### Presentation fixes

Several drawing coordinates in `session.gd` were hard-coded to the old 960-wide
level. The background grid, backdrop, hills and the FINISH label now derive from
the level data. A defect in the hazard drawing — which took x from the data but
hard-coded y — was fixed so that what the player sees matches what the physics
checks.

---

## Verification

Three read-only scripts, all standard-library Python 3.

    python3 scripts/check_reachability.py     # geometry and clearance
    python3 scripts/solve.py routes           # fastest time for each route
    python3 scripts/solve.py marks            # regenerate the test fixture

`scripts/sim.py` is a tick-accurate replica of `player.gd::_physics_process`.
It was validated against the engine before being relied on: the engine's own
test measures a jump rise of 56.07 px and the simulator produces 56.00, and
across a full scripted route the engine takes 589 ticks to the simulator's 592.

`scripts/solve.py` searches routes over that simulator. It proved that
completion time in this game is horizontal distance divided by run speed —
`velocity.x` survives jumps and landings — which is why the level's fork had to
be built around a forced backtrack rather than around hazards or platform count.

`scripts/check_reachability.py` derives the jump envelope from `tuning.gd` and
checks standing headroom, forced-jump corridors, every platform transition, and
whether a spawn-to-finish route exists. Passing a weaker jump makes it fail with
a specific reason:

    python3 scripts/check_reachability.py --jump-velocity 190

### Engine test suites

    /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_game.gd
    /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_keyboard.gd

**25 of 25 mechanics checks and 9 of 9 keyboard checks pass.** Both suites write
timestamped JSON receipts into `evidence/`; the failing runs from development
are committed alongside the passing ones.

---

## Known limitations

- **No external playtester.** Every human result is my own. Whether a
  first-time player finds the eastern climb on the ground route is untested.
- **No pre-change baseline** was captured before modifying the project.
- **The ground route has no automated coverage.** `route_driver.gd` can only
  hold the right key, so it cannot drive the backtrack; the fixture covers the
  high route instead.
- **The route fixture is tightly coupled to the geometry** and has broken on
  every level change. It is now generated rather than hand-tuned.
- **Scope.** At 1920 wide the level is double the starter's, which is more than
  the assignment asked for.

Full detail in [TEST-REPORT.md](TEST-REPORT.md) section 7.

---

## Documents

| File | Contents |
|---|---|
| [CHANGE-BRIEF.md](CHANGE-BRIEF.md) | Predictions written before implementation, with an append-only revision log. Sections 1–5 are deliberately left wrong where reality diverged. |
| [TEST-REPORT.md](TEST-REPORT.md) | What was tested and observed, including four defects and which method found each. |
| [FRICTIONAL.md](FRICTIONAL.md) | Honest log of attempts, failures, a wrong diagnosis, and what was not done. |
| [SOURCES.md](SOURCES.md) | Starter credit, tooling, and the human/AI authorship split. |

The starter's own design package — `GDD.md`, `LEVEL-DESIGN.md`,
`PLAYTEST-PLAN.md`, `BUILD-REPORT.md` and the rest — is retained unmodified.

---

## Film

**The Fork That Wasn't.** — 2:47, 3840x2160, 30 fps.

    claude-liam-walker-jumpman-walkthrough.mp4
    sha256  a6a46018fdf342300cb94f5dc6886b6c0f2add217da710d8c6a17e9d4bbf329a

**The MP4 is not in this repository.** Per the assignment, all MP4 and MP3
files are held outside this repository:

> **Film:** https://drive.google.com/file/d/1Em5TEtrmVKopzQVVNRjtT0zdUq28tFdq/view?usp=sharing
> Also attached to the Canvas submission. No designated course media storage was
> named on the assignment page; the course TA confirmed any accessible location is fine.

[`youtube/claude-liam-walker-jumpman-walkthrough/MEDIA.md`](youtube/claude-liam-walker-jumpman-walkthrough/MEDIA.md)
is the manifest — every excluded file with its SHA-256, so a copy retrieved
from course storage can be verified byte-for-byte against this repository.

Produced with the course-provided Brutalist `godot-walkthrough` workflow using
the `walker` modifier. Narration is Liam (local Kokoro `am_onyx`); no paid API
was used.

All gameplay is real engine output captured for this film — five scripted-input
runs at native 4K, hashed in
[`coverage.json`](youtube/claude-liam-walker-jumpman-walkthrough/coverage.json)
and documented in
[`CAPTURE.md`](youtube/claude-liam-walker-jumpman-walkthrough/CAPTURE.md).
**Nothing under `godot/` was modified to make it**; capture ran against a copy
with one added driver script, which is committed alongside the captures. The
driver uses the real input path (`Input.parse_input_event` and
`Viewport.push_input`), not the `test_control` hooks the test suites use.

The film shows 28 implemented features and names 4 GDD features that were never
built. It also reports one defect that is **not** recorded elsewhere in this
repository: `godot/ui/hud.gd:24` still computes the progress bar as
`(x - 64) / 852`, the starter's 960-wide span, so the bar saturates at x=916 of
a 1920-wide level and is uninformative for the last third of every run. The
presentation-fix pass that made `session.gd` data-driven did not reach the HUD.

The captures are scripted input and the film says so out loud; they are not a
playtest, and the absence of an external playtester is stated in the verdict.

Full reel, evidence and QC: [`youtube/claude-liam-walker-jumpman-walkthrough/`](youtube/claude-liam-walker-jumpman-walkthrough/)
(`RIFF.md`, `FACTCHECK.md`, `SHOTLIST.md`, `PROMPTS.md`, `_qc/REPORT.md`).
The YouTube URL will be recorded here and in `SUBMISSION.md` if the film is published.

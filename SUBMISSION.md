# SUBMISSION — Assignment 1

**Assignment:** Assignment 1 — Extend Walker Jumpman
**Student:** Kiran Gowda Ramanagara Jayaram
**Project name:** walker-jumpman-kiran-g
**GitHub repository URL:** https://github.com/kirangowda3101/walker-jumpman-kiran-g

---

## Revisions

**Submitted commit SHA:** the commit that adds this file. Stated in the Canvas
submission note, since a commit cannot contain its own hash.

**Game-source revision shown in the film:** `1d68ddfcc4126be601e4a2ed9f3c53c1f4cbb314`

Source snapshot of `godot/` at capture time:
`f115c6bda779d53a8531bdb2a29323a609a8b217a386893c92f848f656544771`
(SHA-256 over the sorted manifest of every tracked file under `godot/`,
excluding the engine cache. Recorded in
`youtube/claude-liam-walker-jumpman-walkthrough/SOURCES.md` and `coverage.json`.)

Commit `3dddf9e` added the film reel — evidence, beat sheet, script and QC
records. **It made no changes under `godot/`**, so the game source demonstrated
in the film is identical in the submitted revision. Verifiable by re-running the
manifest hash above against any later commit.

**Godot version:** 4.7.2.stable.official.ed1daf0bf
**Operating system:** macOS, Apple M4

---

## Film

**URL:** https://drive.google.com/file/d/1Em5TEtrmVKopzQVVNRjtT0zdUq28tFdq/view?usp=sharing
**Filename:** `claude-liam-walker-jumpman-walkthrough.mp4`
**SHA-256:** `a6a46018fdf342300cb94f5dc6886b6c0f2add217da710d8c6a17e9d4bbf329a`
**Title:** *The Fork That Wasn't.*
**Spec:** 2:47 · 3840×2160 · 30 fps · H.264 + AAC · 13.9 MB

Also attached to the Canvas submission. Link access is set to anyone with the
link, view only, and was tested in a private browser session.

The assignment refers to a designated course media storage; none was named on
the assignment page, and the course TA confirmed any location is acceptable so
long as the instructor and TA can view it. The film is therefore hosted on
Google Drive and attached to Canvas.

Produced with the course-provided Brutalist `godot-waikthrough` workflow and the
`walker` modifier. All gameplay is real engine output captured from a copy of
this repository's `godot/` project at the revision above. Every capture is
scripted input, labelled as such in the film and in `CAPTURE.md`. The film's beat
sheet, prompts, shot list, coverage contract, input logs, capture driver and QC
reports are all committed under
`youtube/claude-liam-walker-jumpman-walkthrough/`. Media files are excluded from
git per the assignment; `MEDIA.md` catalogues each with its SHA-256.

---

## Summary of my changes

**Character.** Replaced the starter's uniform 18-wide block with a ninja: a
hooded head narrower than the shoulders, a horizontal mask slit, a sash, a sword
slung diagonally across the back, and a headband that trails behind the direction
of travel. Three readable states — standing, running, and a distinct airborne
tuck. Left and right are handled by a single `draw_set_transform` canvas mirror
rather than per-line coordinate ternaries. All original geometric drawing; no
imported art. The 18×28 collider and every value in `tuning.gd` are unchanged.

**Level.** Extended from 960 to 1920 wide. A third zone offers two routes to a
finish that now sits on a raised shelf. The high route climbs two steps to a
runway and arrives directly. The ground route passes underneath, can see the flag
but cannot reach it, and must run past the east end to the only climb, then
backtrack west. The ground route is slower because it is physically longer.
Four spike clusters sit on the ground route; the original section is unchanged
and still fully playable.

**Presentation.** Several drawing coordinates in `session.gd` were hard-coded to
the old 960-wide level. The background grid, backdrop, hills and the FINISH label
now derive from the level data. A defect in the hazard drawing — which read x
from the data but hard-coded y — was fixed so the drawn spikes match the
collision triangles. Added a zone caption and a ground-level wayfinding hint.

**Verification.** Three read-only Python scripts were written for this project:

- `scripts/sim.py` — a tick-accurate replica of `player.gd::_physics_process`,
  validated against the engine before use. The engine's own test measures a jump
  rise of 56.07 px; the simulator produces 56.00. Across a full scripted route the
  engine takes 589 ticks to the simulator's 592.
- `scripts/solve.py` — breadth-first route search over that simulator. It proved
  that completion time in this game is horizontal distance divided by run speed,
  because `velocity.x` survives jumps and landings. That invalidated my own design
  premise in CHANGE-BRIEF section 2, and is why the fork had to be rebuilt around
  a forced backtrack rather than around hazards or platform count.
- `scripts/check_reachability.py` — derives the jump envelope from `tuning.gd` and
  checks standing headroom, forced-jump corridors, every platform transition, and
  whether a spawn-to-finish route exists.

The starter's suites pass at **25/25 mechanics and 9/9 keyboard**. The route
fixture failed after each level change, as predicted; it was extended and retuned
each time, and no assertion was ever deleted or weakened. Its jump marks are now
generated by `solve.py` rather than tuned by hand.

**Measured routes.** High 10.1 s, ground 13.6 s by hand. Solver optima 9.73 s and
11.87 s. Scripted input in the film 11.3 s and 12.3 s, labelled as such.

---

## Known limitations

1. **No external playtester.** Every human result is my own. Whether a first-time
   player finds the eastern climb on the ground route is untested, and it is the
   most likely usability failure in the level.
2. **No pre-change baseline.** The test suites were first run after the character
   and level were already modified. The baseline in TEST-REPORT is inferred from
   the fact that only the route-specific check failed, not recorded.
3. **The ground route has no automated coverage.** `route_driver.gd` can only hold
   the right key, so it cannot drive the backtrack. The fixture covers the high
   route. The ground route is verified by my own play, by the solver, and by a
   scripted capture in the film.
4. **The route fixture is tightly coupled to the geometry.** Every level change
   broke it. Regeneration is now cheap, but it is not robust on its own.
5. **A defect the film found that my documents had missed.** `godot/ui/hud.gd:24`
   computes progress as `(x - 64) / 852`, the starter's 960-wide span. On a
   1920-wide level the bar saturates at x=916 and is uninformative for the last
   third of every run. Inherited from the starter; my presentation-fix pass
   covered `session.gd` but never reached the HUD. It is named in the film's
   verdict. Not fixed, because it was found after the demonstrated revision was
   rendered and I did not want the submitted source to diverge from the film.
6. **Scope.** At 1920 wide the level is double the starter's, and the backtrack
   is the most complicated part of the submission. A shorter section would have
   been easier to inspect and to explain.
7. **The simulator does not model everything.** It reproduces movement, collision
   and hazards, but not the finish area's exact overlap semantics or the
   `contact_settle_ticks` logic. Its agreement with the engine is measured on one
   route, not proven in general.

Full detail in `TEST-REPORT.md` section 7 and `FRICTIONAL.md` section 11.

---

## Where to look

| File | Contents |
|---|---|
| `README.md` | Run instructions, controls, changes, limitations |
| `CHANGE-BRIEF.md` | Predictions written before implementation, with an append-only revision log. Sections 1–5 are deliberately left wrong where reality diverged. |
| `TEST-REPORT.md` | What was tested and observed, including four defects and which method found each |
| `FRICTIONAL.md` | Attempts, failures, a wrong diagnosis, and what was not done |
| `SOURCES.md` | Starter credit, tooling, and the human/AI authorship split |
| `youtube/claude-liam-walker-jumpman-walkthrough/` | Beat sheet, script, prompts, coverage contract, input logs, capture driver, QC reports |
| `evidence/` | Timestamped JSON receipts from every test run, including the failing ones |

**To run:** import `godot/project.godot` in Godot 4.7.2 and press F5.
Enter to start · A/D or arrows to move · Space to jump · R to retry · Esc/P to pause.

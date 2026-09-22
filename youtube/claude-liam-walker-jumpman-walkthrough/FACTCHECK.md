# FACTCHECK — The Fork That Wasn't.

Every factual claim spoken or shown in this film, with its source and how it was
checked. Claims are separated into **observed** (seen in this session's
captures), **source** (read out of the game's code or data), and **reported**
(taken from the author's documents and attributed as such).

---

## 1. Spoken narration

| Beat | Claim | Type | Check |
|---|---|---|---|
| B00 | "a hooded runner, two gaps, a spike field, unlimited retries and a branching last zone" | source | `first_steps.json`: gaps at 448–512 and 736–784; 5 hazard clusters; `hud.gd` "No lives. Just another try."; zone 03 caption "TWO WAYS UP" |
| B00 | "That prompt is an illustrative reconstruction, not a saved transcript" | — | Stated because it is true. No Walker transcript exists for this project; the repository is an extension of an existing starter. Also printed on screen as output line 1. |
| B00 | "a student extension of Walker Jumpman" | reported | `SOURCES.md`, `README.md`; starter is nikbearbrown/walker-jumpman |
| B01 | "one level, twice the width it started at" | source | `first_steps.json` `width: 1920`; starter was 960. **2.00×** exactly |
| B01 | "A third zone offers two ways up to the same flag" | observed | run-01 takes the climb at x=1060; run-03 declines it and reaches the same finish at (1620, 168) |
| B01 | "that fork … can only trade distance" | source + reported | `player.gd::_physics_process` never resets `velocity.x` on jump, land or height change. Author's own finding, CHANGE-BRIEF 2026-09-20 and TEST-REPORT §4 |
| B02 | "Eleven point three seconds, no retries" | observed | run-01 completion panel reads "11.3 seconds / 0 retries" at v=12.57 s |
| B03 | "position clamped, velocity not" | observed + source | run-04 log at v=1.73: `x=10.0`, `vx=-160`. `player.gd:67` `position.x = maxf(position.x, 10.0)` |
| B03 | "Jump three ticks after the ledge" | observed | run-04 log: last ground contact tick 291, jump press tick 294 → **3 ticks** |
| B03 | "Again at the apex, nothing" | observed | run-04 log at v=5.27: press while `vy=+32`, no change in `vy` |
| B03 | "Five ticks early, banked" | observed | run-04 log: press tick 441, ground contact tick 446 → **5 ticks**; `vy=-320` on the contact frame |
| B04 | "retries one … retries two" | observed | run-02 HUD reads RETRIES 01 at v=2.67 and RETRIES 02 at v=7.00 |
| B04 | "back at spawn in half a second" | source + observed | `session.gd` `retry_remaining = 0.55`; run-02 death v=2.67, playable again v≈3.22 |
| B04 | "R restarts, and the counter stays at two" | observed | run-02 log: `deaths` is 2 before and after the R at v=9.7 |
| B04 | "Escape pauses, P pauses, M exits" | observed | run-02 v=11.60 (Esc), v=13.97 (P), v=14.73 (M) |
| B05 | "Another window takes focus and the game stops itself" | observed | run-05: state PLAYING → PAUSED on the frame a second `Window` grabs focus |
| B06 | "thirty-two pixels of headroom … for a twenty-eight pixel player. Four to spare." | source | solid `[1060, 272, 56, 16]` → underside y=288; ground y=320 → **32 px**. Collider is 18×28 → **4 px margin**. Corrected during scripting: an earlier draft called 4 px "the headroom", which confuses the margin with the clearance |
| B06 | "The only way up is past the east end" | source + observed | the only solid east of the shelf is `[1790, 272, 56, 16]`; the stone above it at `[1700, 224, 56, 16]` sits 96 px over the ground, beyond the 56 px jump ceiling. run-03 climbs at x=1803 and returns west |
| B06 | "Twelve point three" | observed | run-03 completion panel reads "12.3 seconds / 0 retries" |
| BVDT | "eleven point three and twelve point three seconds under scripted input" | observed | as above. Explicitly attributed to scripted input, **not** presented as human play |
| BVDT | "the progress bar … fills up around x nine sixteen" | source + observed | `hud.gd:24` `clampf((x - 64) / 852, 0, 1)` → saturates at x = 64 + 852 = **916**. Seen full on screen at v≈6 s of run-01 with the player far short of the flag at 1620 |
| BVDT | "nobody outside the author has played this" | reported | `TEST-REPORT.md` §7.1, `FRICTIONAL.md` §11, `SOURCES.md` — stated plainly by the author |
| BVDT | "cherries, moving platforms and audio are design document only" | source | GDD MECH-03/FEAT-05, MECH-05, and §6 audio. No collectible, kinematic body, or audio node exists in the project |
| BHTF | "verified by a human and by a simulator, but not by a test" | reported | `TEST-REPORT.md` §7.3: `route_driver.gd` cannot move left, so the ground route has no automated coverage |

## 2. On-screen text

| Where | Text | Check |
|---|---|---|
| B00 output | "one level, 1920 px wide, 12 solids, 5 spike clusters" | `first_steps.json`: `width: 1920`, `solids` has **12** entries, `hazards` has **5** |
| B00 output | "nikbearbrown/walker-jumpman · extended by Kiran Gowda Ramanagara Jayaram" | `SOURCES.md` |
| BVDT | "coyote 6 ticks and input buffer 6 ticks" | `tuning.gd` `coyote_ticks = 6`, `buffer_ticks = 6` |
| BVDT | "both routes completable: 11.3 s high, 12.3 s ground" | this session's captures |
| BVDT | "progress bar divides by the old 960 level; full at x=916" | `hud.gd:24` |

## 3. Corrections applied during authoring

1. **"four pixels of headroom" → "thirty-two pixels of headroom … four to spare."**
   The clearance under the stepping stone at x=1060 is 32 px; 4 px is the margin
   left over a 28 px collider. The first draft conflated the two.

2. **A ceiling-bump claim was cut entirely.** An earlier feature entry asserted
   that the ground route's spike jumps clip the runway overhead. Two checks
   killed it: arithmetic (a free jump peaks at y=264, the ceiling stops it at
   y=268 — a 4 px difference, not visible), and a frame inspection at the apex
   of the first such jump (run-03 frame 247), which shows the player passing
   through the 24 px gap between the platforms at x=1196–1220 and not touching
   anything. Nothing in the film now claims it.

3. **Route times are this session's, not the author's.** `TEST-REPORT.md`
   records human times of 10.1 s and 13.6 s, and `solve.py` reports optima of
   9.73 s and 11.87 s. The film quotes **11.3 s and 12.3 s**, which is what the
   scripted input actually achieved, and says "under scripted input" out loud.

4. **De-sensationalised.** The film does not claim the fork "trades risk for
   time" — the author's own CHANGE-BRIEF §2 premise, which the author then
   disproved. B01 makes the correction the point of the beat.

## 4. Discrepancies found in the project's own documents

Recorded because they were found while fact-checking, not to score points.
Neither changes a conclusion.

1. **Solid count.** `CHANGE-BRIEF.md` (2026-09-20) says the final geometry has
   "ten solids". `first_steps.json` has **12**, and `TEST-REPORT.md` §3 agrees
   ("all 12 surfaces clear 28 px"). The film uses 12.

2. **The progress bar defect is unrecorded.** `hud.gd:24` still divides by the
   starter's 852 px span. `SOURCES.md` lists `hud.gd` as unchanged, and
   `TEST-REPORT.md` §5 reports "Presentation — grid, hills, zone captions, the
   wayfinding hint and the FINISH label all extend across the new section",
   which is true and does not cover the HUD progress bar. The presentation fix
   pass caught `session.gd` and missed `hud.gd`. This is the one defect the film
   contributes that was not already in the author's documents.

3. **Backdrop width.** `README.md` says the backdrop is now derived from the
   level data; `session.gd:185` still draws a literal
   `Rect2(-400, -200, 2400, 900)`. It happens to cover the 1920-wide level, so
   there is no visible defect, and the film does not raise it.

## 5. What this film does not claim

- It does not claim a human playtest. All five captures are `scripted-input`,
  labelled as such in `coverage.json` and stated in `CAPTURE.md`.
- It does not claim real-time frame rate. Capture ran under `--fixed-fps 60`;
  the simulation rate is real-time-accurate, the render is offline.
- It does not claim the feature inventory is exhaustive of every edge case.
  Duplicate-death suppression, death-over-finish precedence and the twenty-retry
  soak are asserted by the engine's own suites (`evidence/mechanics-*.json`) and
  are not staged on camera.

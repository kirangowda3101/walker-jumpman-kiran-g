# TEST-REPORT — walker-jumpman-kiran-g

**Student:** Kiran Gowda Ramanagara Jayaram
**Course:** CSYE 7270, Fall 2026 — Assignment 1
**Engine:** Godot 4.7.2.stable.official.ed1daf0bf
**OS:** macOS, Apple M4
**Source revision under test:** see SUBMISSION.md for the exact commit SHA
**Level under test:** `godot/levels/first_steps.json` — width 1920, finish at (1620, 168)

Every result below was observed. Nothing here is predicted or inferred from what
the code looks like it should do. Where a check was not performed, it says so.

---

## 1. Automated checks

Run from the repository root:

    /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_game.gd
    /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_keyboard.gd

Both suites write timestamped JSON receipts into `evidence/` on every run. All
receipts are committed, including the failing ones.

**Current state: 25 of 25 mechanics checks pass, 9 of 9 keyboard checks pass.**

The mechanics suite covers launch position, speed cap, neutral stop,
simultaneous inputs, the left wall, fixed jump height, no double jump, the
coyote window at 5/6/7 ticks, the input buffer at 5/6/7 ticks, low ceiling,
pause freeze, focus-loss pause, spike collision, duplicate-death suppression,
respawn, manual restart not counting as death, twenty consecutive retries, death
taking priority over finish, the fall boundary, the scripted route, and replay
idempotency.

### Baseline, stated honestly

I did not capture a green baseline before modifying the project. The earliest
receipt in `evidence/` already contains the ninja character and an extended
level. The baseline is therefore inferred rather than recorded: on that first
run, 24 of 25 checks passed and the single failure was `complete-real-route`,
which is route-specific. Every mechanical check has passed on every run from the
first onwards, which indicates the character and level work did not disturb
movement or collision behaviour. A recorded pre-change baseline would have been
better evidence, and this is a process mistake rather than a result.

### Confirmation that movement tuning was not altered

`fixed-jump-and-no-double` reports `rise_px: 56.07` on every run across the whole
project history. That is the engine measuring the actual height achieved by the
player body, unchanged from before my edits. Nothing in `tuning.gd` was touched.

---

## 2. Route fixture

Prediction C in CHANGE-BRIEF said the scripted route would fail once the finish
moved. It did, repeatedly — once per level redesign. No failing assertion was
ever deleted or weakened; the fixture was extended and retuned each time.

`godot/tests/route_driver.gd` holds the right key and jumps on crossing each x in
`jump_marks`. It has no ability to move left.

**Consequence for coverage.** The final ground route requires the player to
double back west after climbing at the east end. The fixture physically cannot
drive it. It therefore covers the **high route** instead. This is a deliberate
choice: the high route is entirely rightward, and it exercises the two-step climb
and the runway, which are the new geometry.

**Diagnosis history.** Each failure was read from the coordinates the test
reports, not guessed at:

| Symptom | Diagnosis |
|---|---|
| died x=993, y=435.9, 5 marks used | y past `fall_y` 430 — walked off the old ground into the new gap with no marks left |
| died x=1238, y=304.7, 8 used | y at spike height, not falling — jumped too early, landed on a cluster |
| died x=1353, y=436.1, 8 used | falling again in the last gap, out of marks |
| died x=1115, y=317.5, 6 used | mark tuned for a hazard that had since moved 40 px |
| died x=1244, y=313.7, 8 used | first cluster of the redesigned zone 3 |
| identical output across three different mark values | not caching — the mark was never firing, because the player was airborne at that x every time. Found by adding a temporary trace of x, y, `is_on_floor()` and the mark index, which showed the fixture had been on the high platforms since an earlier mark. |

That trace was the turning point. Three edits produced byte-identical results and
I assumed a stale cache; clearing `.godot` changed nothing. Printing the actual
state showed the fixture was not where I believed it was.

**Final approach.** Rather than hand-tuning a seventh time, the marks are now
derived by the simulator: `python3 scripts/solve.py marks`. Final fixture:

    [138.0, 292.0, 424.0, 548.0, 712.0, 900.0, 1010.0, 1085.0, 1175.0, 1450.0]

The first five are the starter's originals, unchanged. Five were added.

**A real failure of the generated output, worth recording.** The first
simulator-derived set completed in the simulator but died in the engine. Its
marks were tick-exact and several fired inside the coyote window, after the
player had already left the platform edge. The engine's floor detection differs
from the simulator's by a frame or two, so those jumps were missed entirely.
`solve.py` now pulls each mark progressively back off the edge and replays until
the fixture completes, which produces marks that fire while the player is
unambiguously grounded.

**Engine and simulator agreement.** With the final marks the engine completes in
**589 ticks** and the simulator predicts **592** — agreement to within 0.5% over
roughly ten seconds of play.

---

## 3. Verification tooling

Three scripts, all read-only. None can alter game behaviour and none replaces
human playtesting.

### `scripts/sim.py` — tick-accurate movement replica

Mirrors `player.gd::_physics_process` at 60 Hz: the same order of operations
(gravity applied before the jump assignment), the 18x28 collider at offset
(0, −14), axis-separated collision resolution, coyote and buffer windows,
terminal velocity, and the hazard trigger built as three triangles across each
cluster's width.

**Validated twice before being relied on.** The engine's own test reports
`rise_px: 56.07` for a single jump; the simulator produces **56.00**. Across a
full scripted route the engine takes 589 ticks and the simulator predicts 592.

Worth noting: the analytic projectile formula gives a 53.3 px apex, which is what
I had been designing against. The true discrete value is 56. That 2.7 px
discrepancy is the sort of thing that makes a jump feel inconsistent, and it is
why the simulator rather than the formula is the authority here.

### `scripts/solve.py` — route search and fixture generation

Breadth-first over game states, allowing right, left and neutral movement so the
ground route's backtrack can be modelled. Every edge costs one tick, so the first
finish reached is the fastest possible. Reports the two routes separately,
distinguished by whether the runway is touched.

    $ python3 scripts/solve.py routes
    level first-steps  width 1920  finish x=1620
      high route:   9.73s
      ground route: 11.87s
      ground route costs +2.13s with optimal play

### `scripts/check_reachability.py` — static geometry checker

Reads the constants out of `tuning.gd` and the geometry out of
`first_steps.json`, derives the jump envelope, and checks standing headroom,
forced-jump corridors, every platform-to-platform transition, and whether a route
from spawn to finish exists at all.

    headroom
      all 12 surfaces clear 28 px
    jump corridors
      13 of 13 forced-jump sites clear with margin
    jumps
      18 transitions reachable, none inside the tight band
    route
      spawn P0 -> finish P9
      P0 -> P1 -> P2 -> P5 -> P11 -> P10 -> P9   (6 moves)
    PASS  every surface is standable and the finish is reachable

**Cause and effect, demonstrable on screen:**

    $ python3 scripts/check_reachability.py --jump-velocity 190
    route
      no route from spawn P0 to finish P9
    FAIL
      - finish unreachable from spawn

One constant changed, peak rise falls from 53 to 19, and specific geometry moves
out of range. This is the mechanism shown in the film.

---

## 4. Defects found, and which method found them

Four clearance and design defects, found four different ways. None of the methods
would have found all of them.

| Defect | Found by | Missed by |
|---|---|---|
| Hazard drawing hard-coded y at 320/304 while collision read the real rectangle | reading `session.gd` | playing — both my hazards sat at ground level, so the bug was dormant |
| A high platform left 24 px of standing clearance for a 28 px player | the reachability checker | playing — the jump onto that slab always carried past the overhang |
| A spike cluster was unjumpable: 32 px of clearance is enough to stand under but not to jump in | playing | the checker — it only tested standing height |
| Route time is horizontal distance ÷ run speed, so a same-length fork can never be slower | the simulator | both playing and the checker |

**On the second and third together.** These are the same physical quantity used
for two different purposes, and treating them as one thing was my error. Standing
needs 28 px. Jumping needs the full rise plus the player's height, because the
jump is fixed-height and cannot be shortened. I extended the checker with a
jump-corridor pass that scans for a viable takeoff point at each hazard and gap,
and rejects takeoffs a running player could not realistically hit — the window is
sized from the game's own 6-tick input buffer, about 16 px of travel.

**On the fourth.** `velocity.x` is never reset by jumping, landing, or changing
height. The solver returned identical times for both routes across 27 candidate
layouts before I understood why. The design in CHANGE-BRIEF section 2 was
therefore unachievable as written, and the fix was to make the ground route
physically longer by forcing a backtrack.

---

## 5. Human playtest — my own

Full sessions played in the Godot editor at 1278x719.

| Check | Observed |
|---|---|
| Startup | Runs from a normal F5 launch, no script errors in Output |
| Controls | A/D and arrows move, Space jumps, R retries, Esc pauses, Enter starts and replays |
| Character, facing right | Sword on the back, headband trailing left, pupil on the leading side |
| Character, facing left | Whole figure mirrors; sword and headband swap sides and still trail |
| Character, standing | Legs level, headband sways gently |
| Character, running | Legs alternate, headband whips |
| Character, airborne | Front knee tucks, back leg trails — a visibly distinct third pose |
| Visual vs collision, pressed to a wall | The 12-wide hood against an 18-wide collider stops the head ~3 px short while the torso is flush. Checked facing both ways. Reads as a hooded figure, not a defect. **Prediction D closed.** |
| Headroom under the new platforms | Clear above the head; the 24 px defect is fixed |
| **High route, complete** | **10.1 s, 1 retry** |
| **Ground route, complete** | **13.6 s, 0 retries** |
| Spike death, new section | Kills, message "Watch the spikes", returns to spawn |
| Fall death, new section | Kills, message "Missed the landing", returns to spawn |
| R in the new section | Returns to spawn; retry counter does **not** increment |
| Pause and resume, new section | Freezes, resumes cleanly |
| Replay after completion | Second run starts clean, timer reset |
| Camera | Follows to the relocated finish with no code change — the limit is already derived from `level.width` |
| Presentation | Grid, hills, zone captions, the wayfinding hint and the FINISH label all extend across the new section |

**Measured against the optimum.** The solver's best possible times are 9.73s and
11.87s. My high route was 0.4s off optimal; my ground route 1.7s off. The larger
gap on the ground route is expected — it requires finding the climb, which
optimal play knows in advance.

**On the retry counter.** R returning to spawn without incrementing is the
starter's deliberate behaviour, not a regression. `restart_attempt()` is called
directly by the input handler, while `deaths += 1` lives in `resolve_contacts()`
and runs only on an actual death. The suite asserts this with
`manual-restart-not-death`, which passes.

---

## 6. Evidence-based revisions

### Revision 1 — the fork was decoration

**Observed.** First working version of the fork timed at 10.5s ground and 10.4s
high.

**Judgment.** Not a decision. The high route cost three precise jumps and a fall
risk and returned a tenth of a second.

**Changed, then changed again.** Three attempts at lengthening the ground route
and shortening the high route. All tied or broke a route.

**Resolved by measurement, not intuition.** Wrote the simulator, established that
route time is distance-bound, and redesigned around a forced backtrack instead.
Result: 9.73s versus 11.87s optimal, 10.1s versus 13.6s measured by hand.

### Revision 2 — an unjumpable hazard

**Observed.** Playing the ground route, I could not clear a spike cluster. The
ninja bumped the platform overhead every time.

**Diagnosed.** 32 px of clearance: enough to stand, not enough to jump.

**Changed.** Moved the hazard clear of the overhang, then extended the checker so
it would catch this class of defect rather than only standing clearance.

### Revision 3 — wayfinding

**Observed.** On the ground route the flag is visible on the shelf but
unreachable, and the way up is off-screen to the east. Playing it myself I
hesitated, and the 1.7s gap against optimal play is mostly that hesitation.

**Changed.** Added a ground-level hint at x=1480 reading "No way up from here.
Keep going right." Positioned clear of the platforms and hazards so it reads
during normal play.

**Still unresolved.** Whether that hint is sufficient for someone who has not
built the level. Named as a limitation below.

---

## 7. Honest limitations

1. **No external playtester.** Every human result in this report is my own. The
   assignment asks for another person's actual feedback and I was not able to
   arrange it. This is the largest gap in my verification. The specific
   consequence is that the wayfinding question in Revision 3 stays open: I know
   the eastern climb is findable because I built the level and know where it is,
   which is exactly the knowledge a first-time player does not have. I have not
   invented a playtester or presented my own sessions as anyone else's.
2. **No recorded pre-change baseline.** Covered in section 1. A process mistake.
3. **The ground route has no automated coverage.** `route_driver.gd` cannot move
   left, so it cannot drive the backtrack. The ground route is verified by my own
   play and by the solver, not by a scripted input. A driver that accepts an axis
   sequence rather than only right would fix this and is not implemented.
4. **The route fixture is tightly coupled to the geometry.** Every level change
   has broken it. It is now generated rather than hand-tuned, which makes
   regenerating cheap, but it is not robust to geometry changes on its own.
5. **Wayfinding is unproven.** See Revision 3. A first-time player may not find
   the eastern climb. This is the most likely usability failure and I have no
   external evidence either way.
6. **The simulator does not model everything.** It reproduces movement,
   collision and hazards, but not the finish area's exact overlap semantics or
   the `contact_settle_ticks` logic. Its 0.5% agreement over a full route is
   measured on one route, not proven in general.
7. **The reachability checker's margins are advisory.** The 80% safety factor is
   a judgment call, not a derived value, and the checker does not model
   acceleration over a short run-up.
8. **One TIGHT transition remains** — a long drop from the runway to the ground
   slab, at 2% margin. It is not on either intended route and I have left it
   rather than adding geometry to remove it.
9. **The sword and headband overhang the collider** by 2–3 px on the trailing
   side. Declared deliberate in CHANGE-BRIEF. Because they always trail, the
   overhang points away from the direction of travel and never leads into a wall
   the player is walking toward.
10. **The level is now 1920 wide, double the starter's 960.** That is more scope
    than the assignment asked for, and the backtrack puzzle is the most
    complicated part of the submission. A shorter section would have been easier
    to inspect and to explain.

# TEST-REPORT — walker-jumpman-kiran-g

**Student:** Kiran Gowda Ramanagara Jayaram
**Course:** CSYE 7270, Fall 2026 — Assignment 1
**Engine:** Godot 4.7.2.stable.official.ed1daf0bf
**OS:** macOS, Apple M4
**Source revision under test:** see SUBMISSION.md for the exact commit SHA
**Level under test:** `godot/levels/first_steps.json`, width 1520, finish at x=1480

Every result below was observed. Nothing in this document is predicted, assumed, or reconstructed from what the code looks like it should do. Where a check was not performed, it says so.

---

## 1. Automated checks

Run from the repository root:

    /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_game.gd
    /Applications/Godot.app/Contents/MacOS/Godot --headless --path godot --script res://tests/test_keyboard.gd

Both suites write timestamped JSON receipts into `evidence/` on every run. Those receipts are committed, including the failing ones.

### Mechanics suite — `test_game.gd`

| Run | Result | Note |
|---|---|---|
| First run, after character and level changes | 25 checks / 1 failure | `complete-real-route` FAIL |
| After adding jump mark 1230 | 25 / 1 | still FAIL, different death |
| After moving mark to 1222 | 25 / 1 | still FAIL, different death |
| After adding mark 1290 | **25 / 0** | PASS |
| After raising the first high platform 8 px | **25 / 0** | PASS, unchanged |

### Keyboard suite — `test_keyboard.gd`

9 checks, all PASS, on every run: enter-start, keyboard-move, keyboard-jump, escape-pause, enter-resume, r-retry, enter-replay, pause-main-menu, menu-start-again.

### Baseline, stated honestly

I did not capture a green baseline before modifying the project. The earliest receipt in `evidence/` already contains the ninja character and the extended level. The baseline is therefore inferred rather than recorded: on that first run, 24 of 25 checks passed and the single failure was `complete-real-route`, which is route-specific. Every mechanical check — speed cap, coyote window, jump buffer, ceiling, spike collision, respawn, twenty-retry stress, fall boundary, replay idempotency — passed on the first run and has passed on every run since, which indicates the character and level work did not disturb movement or collision behaviour. A properly recorded pre-change baseline would have been better evidence, and this is a process mistake on my part rather than a result.

### Confirmation that tuning was not altered

`fixed-jump-and-no-double` reports `rise_px: 56.07` on every run. That is the engine measuring the actual jump height achieved by the player body, and it is unchanged from before my edits. It also sits close to the 53.3 px peak that the constants predict analytically, the difference being that the measurement samples a discrete physics tick rather than the exact apex. Movement tuning is untouched.

---

## 2. Route fixture — the failure I predicted

Prediction C in CHANGE-BRIEF said the scripted route would fail once the finish moved. It did.

`godot/tests/route_driver.gd` holds a fixed input route: hold right, and jump on crossing each x in `jump_marks`. The original five marks ended at 712, which was sufficient for the 960-wide level.

I did not delete the failing assertion or weaken the expected result. I extended the fixture and diagnosed each failure from the coordinates it reported.

| Marks | Observed | Diagnosis |
|---|---|---|
| 5 original | died x=993, y=435.9, 5 marks used | y beyond `fall_y` 430 — walked off the old ground into the new gap with no jumps left |
| + 950, 1110, 1230 | died x=1238, y=304.7, 8 used | y at spike height, not falling — jumped too early and landed on the second cluster |
| mark moved 1230 → 1222 | died x=1353, y=436.1, 8 used | falling again, in the gap before the final slab — out of marks |
| + 1290 | **x=1478, y=319.9, state 4, 0 deaths, 537 ticks** | reached the finish at 1480 and completed |

Final fixture: `[138, 292, 424, 548, 712, 950, 1110, 1222, 1290]` — four marks added, none removed, no assertion changed.

**Tolerance worth recording.** The difference between landing on the spikes and clearing them was 8 pixels of jump-mark position: 1230 fails, 1222 passes. The fixture is tightly coupled to the hazard placement and will need revisiting if that cluster moves.

**Coverage limit.** The fixture drives the ground route only. The high route is verified by my own play and by the reachability checker, not by a scripted input. A second fixture covering the high route would be a genuine improvement and is not implemented.

---

## 3. Reachability checker

`scripts/check_reachability.py`. Reads the constants out of `tuning.gd` and the geometry out of `first_steps.json`, derives the jump envelope analytically, then checks headroom on every walkable surface and searches for a route from spawn to finish. It reads only; it cannot alter the game.

Derived from the shipped constants (speed 160, jump_velocity 320, gravity 960):

    peak rise   53.3 px
    airtime     0.67 s
    flat reach  106.7 px, safe budget 85.3 at an 80% margin

### It found a defect that playing did not

First run against the level I had already built, tested and declared finished:

    headroom
      P5  x 1000-1120 top 320   clearance 24 px  < player height 28   BLOCKED

The first high platform, `[1010, 280, 48, 16]`, has its underside at y=296 and sits directly over the low route whose surface is at y=320. That leaves 24 px of clearance for a player whose collider is 28 px tall. The ninja cannot walk under it.

I had not encountered this because the jump onto that slab carries the player past x=1058 and lands beyond the overhang. A player who lands short would be wedged with no way out except R — a soft-lock in a section I had already signed off.

**Fixed** by raising the platform 8 px to `[1010, 272, 48, 16]`, giving 32 px clearance. Re-verified:

    headroom
      all 12 surfaces clear 28 px
    route
      spawn P0 -> finish P7
      P0 -> P1 -> P2 -> P5 -> P6 -> P7   (5 moves)
    PASS

The jump onto that platform remains makeable: 50 px gap with a 48 px rise against a 56 px safe limit. Confirmed by play — it is noticeably tighter than before but doable.

Re-ran `test_game.gd` afterwards: still 25 / 0. The fixture takes the ground route, so it was unaffected, which is the expected result.

### Cause and effect, demonstrable

    python3 scripts/check_reachability.py --jump-velocity 190

Same geometry, weaker jump. Peak rise falls from 53.3 to 18.8 px and flat reach from 106.7 to 63.3. The 32 px block, the 40 px platform climbs and the 64 px gap all move out of range. The route search then reports:

    route
      no route from spawn P0 to finish P7
    FAIL
      - finish unreachable from spawn

One constant changed, a traceable chain of consequences, a specific failure named. This is the mechanism demonstrated in the film.

### Known limits of the checker

- It models a jump from a standing or full-speed start and does not simulate acceleration over a short run-up, so a landing marked PASS could still be missed by a player who has not reached full speed.
- It treats every solid's top as one continuous walkable surface and does not model partial obstruction along that surface.
- It ignores hazards entirely. A route it calls reachable may still be lethal.
- The 80% safety margin is a judgment call, not a derived value.

---

## 4. Human playtest — my own

Full sessions played in the Godot editor at 1278x719.

| Check | Observed |
|---|---|
| Startup | Project runs from a normal F5 launch, no script errors in Output |
| Controls | A/D and arrows move, Space jumps, R retries, Esc pauses, Enter starts and replays — all as documented |
| Character, facing right | Sword on the back, headband trailing left, pupil on the leading side |
| Character, facing left | Entire figure mirrors; sword and headband move to the other side and continue to trail |
| Character, standing | Legs level, headband sways gently |
| Character, running | Legs alternate; headband whips |
| Character, airborne | Front knee tucks, back leg trails — a visibly distinct third pose |
| Visual vs collision, pressed to a wall | The hood is 12 wide against an 18 wide collider, so the head stops ~3 px short of the block while the torso is flush. Checked facing both ways. Judged to read as a hooded figure rather than a defect. Prediction D closed. |
| Headroom under the new high platform | Clear space above the head after the 8 px fix |
| Ground route, complete | **14.5 s, 0 retries** |
| High route, complete | **9.6 s, 0 retries** |
| Spike death, new section | Kills, message "Watch the spikes", returns to spawn |
| Fall death, new section | Kills, message "Missed the landing", returns to spawn |
| R in the new section | Returns to spawn; retry counter does **not** increment |
| Pause and resume, new section | Freezes, resumes cleanly |
| Replay after completion | Second run starts clean, timer reset |
| Camera | Follows to the relocated finish at 1480 with no manual change — the limit is already derived from `level.width` |
| Presentation | Grid, background hills, zone captions and FINISH label all extend across the new section after the fixes in section 5 |

**On the retry counter.** R returning to spawn without incrementing the counter is the starter's deliberate behaviour, not a regression. `restart_attempt()` is called directly by the input handler, while `deaths += 1` lives in `resolve_contacts()` and runs only on an actual death. The suite asserts this explicitly with `manual-restart-not-death`, which passes.

---

## 5. Presentation defects found and fixed

Prediction B said hard-coded drawing coordinates would not follow the level data. Confirmed, with an evidence screenshot taken before fixing.

| Defect | Was | Now |
|---|---|---|
| Background grid stopped at the old boundary | `range(0, 961, 32)` and a literal 960 | derived from `level.width` |
| Backdrop rectangle too narrow | 1800 wide | 2400 wide |
| Background hills stopped | `[100, 470, 770]` | two further positions added |
| FINISH caption stranded at the old flag position | fixed at x=878 | positioned relative to `level.finish[0]` |
| New section unlabelled | — | zone 03 caption added, matching the existing two-line house style |

### A defect I did not predict

The hazard drawing read x from the level data but hard-coded y as 320 and 304, and always drew exactly three triangles 8 px apart regardless of the hazard's stated width. The collision triangles in `_add_area` are built from the real rectangle. A hazard placed anywhere other than ground level would therefore kill the player at its true position while drawing at the bottom of the level — precisely the visual/physics disagreement the assignment warns about.

Both of my hazards sit at y=304, so the bug is dormant in this layout. Fixed anyway: the drawing now reads y, height and width from the entry and derives triangle width as `w / 3.0`, matching what the collision code already does.

Verified as a no-op refactor for the current data — the existing spike clusters render identically to before. That was the intended result: correct for data not yet written, unchanged for data already written.

---

## 6. Evidence-based revision

**Observed.** With the first working version of the fork, I timed both routes: ground 10.5 s, high 10.4 s.

**Judgment.** The routes were not a decision. The high route cost three precise jumps and a fall risk and returned one tenth of a second. No player would choose it, so the branch was decoration.

**Changed.** Lengthened the ground route with a second gap and a third spike cluster, and gave the high route wide flat hops at a constant height so that movement along it is uninterrupted. Level width grew from 1360 to 1520.

**Re-measured.** Ground 14.5 s, high 9.6 s. A 4.9 s spread, roughly one third faster. Same player, same session, 0 retries on both.

The fork now trades time against risk as the brief claimed it would.

---

## 7. Honest limitations

1. **No recorded pre-change baseline.** Covered in section 1. A process mistake.
2. **No external playtester yet.** Every human result here is my own. The assignment asks for another person's actual feedback and I have not yet collected it.
3. **The high route has no automated coverage.** The fixture drives the ground route only.
4. **The route fixture is brittle.** An 8 px change in one jump mark is the difference between passing and landing on spikes. It is coupled to the current hazard placement.
5. **The reachability checker does not model acceleration.** A short run-up means the player may not be at 160 px/s at takeoff, so a jump it marks PASS could still be missed in play. Its margins are advisory.
6. **The checker ignores hazards.** It proves geometric reachability, not survivability.
7. **Two TIGHT transitions remain**, both long drops from a high platform to a low one. Neither lies on an intended route, and I have left them rather than adding geometry to remove them.
8. **The sword and headband overhang the collider** by 2–3 px on the trailing side. Declared deliberate in CHANGE-BRIEF. Because they always trail, the overhang points away from the direction of travel and never leads into a wall the player is walking toward.

# CHANGE-BRIEF — walker-jumpman-kiran-g

**Student:** Kiran Gowda Ramanagara Jayaram
**Course:** CSYE 7270, Fall 2026 — Assignment 1
**Starter:** [nikbearbrown/walker-jumpman](https://github.com/nikbearbrown/walker-jumpman), "First Steps" slice
**Engine:** Godot 4.7.2.stable.official.ed1daf0bf
**Written:** 2026-09-18, before any code was edited
**Baseline played:** reached the finish in 5.8s with 1 retry; confirmed spike death, R-retry, Esc-pause, and the completion screen all work before modification.

This document records predictions made *before* implementation. Later revisions are appended to the Revision Log at the end; nothing above that log is rewritten after the fact.

---

## 1. Character concept

Replacing the starter's blue block figure with a **ninja**.

The starter character is a single uniform 18-wide slab from head to hip, with a square eye patch and an orange waist stripe. It has no shape variation along its height, so its silhouette is a rectangle.

My ninja changes the silhouette rather than just the palette:

| Feature | Starter | Mine |
|---|---|---|
| Head width | 18, same as body | 12 — a hood that tapers in from the shoulders |
| Face | 5x5 square patch with a 2x3 pupil | Horizontal 8x3 mask slit with a pupil that flips with `facing` |
| Waist | Orange stripe, 20 wide | Sash in a contrasting colour, same 20 wide |
| Trailing detail | none | 4x2 headband tail that streams *behind* the head, driven by `facing` |

The headband tail is the piece I most want to get right. It uses the same `facing` variable as the eye, but inverted, so it points opposite to the direction of travel. That gives a directional read from the silhouette alone, which the starter does not have.

Planned geometry, all drawn with `draw_rect` in `godot/features/player/player.gd`, inside the existing collider bounds of x ∈ [-9, +9] and y ∈ [-28, 0]:

```
hood          (-6, -28, 12, 10)
body outline  (-9, -18, 18, 12)
robe fill     (-7, -16, 14,  8)
sash         (-10, -13, 20,  3)
mask slit     (-4, -25,  8,  3)
pupil          2x3, x flips on facing
legs          (-6, -6, 5, 6 + stride) and (2, -6, 5, 6 - stride)
headband tail  4x2, x flips on facing, trailing side
```

Note: the shipped geometry differs from this plan — see the changes below and the Revision Log. The sword was not in the original plan, and the left/right flip was implemented with a canvas transform rather than per-line coordinate ternaries.

No imported art. All original geometric drawing.

**Changes made after seeing it on screen:**

- Tried the headband sway at 0.9 and went back to 0.3. At 0.9 the cloth
  moved faster than fabric that size plausibly would; 0.3 reads as real
  weight.
- The sword was invisible in the first two attempts because I had drawn it
  in the same ink colour as the hood and torso, and along the spine, where
  the 18-wide body covered it completely. Fixed by angling it diagonally
  past the left side so it clears the silhouette, and drawing a muted grey
  blade over a darker outline for contrast. Added a gold pommel above the
  shoulder.
- Shortened the blade after a version that reached the ground and read as
  a staff rather than a sword.
- Roughly doubled the headband length and made the far tip sway 1.4x the
  near end, so it whips instead of swinging rigidly.

---

## 2. Level extension

The starter level is 960 wide: three ground slabs, two gaps (64 and 48), one 16-high step, one 32-high block, one spike cluster, finish at x=916.

I am extending past x=960 with a **branching section** that offers two routes to the same finish.

- **High route.** A 56-wide jump with a 32 rise onto a raised platform, then a 48-wide flat hop to a second raised platform, then a short drop to the final slab. Shorter, faster, but demands two accurate jumps.
- **Low route.** Two easy 40-wide flat jumps along ground level, but it is longer and carries a spike cluster the player must clear.

Both routes rejoin on a final slab. The finish flag moves to approximately x=1320 so the original finish position is no longer a winning position, and the level `width` grows to 1360.

**The decision it asks of the player:** the completion screen reports elapsed time and retry count. The high route is the faster line but risks a fall into the gap; the low route is survivable but slow and hazard-laden. A player optimising for time takes the high road; a player who has died repeatedly takes the low one. The two routes are not cosmetic variants — they trade time against risk.

Planned coordinates, in `godot/levels/first_steps.json` format `[x, y, width, height]`:

```
high platform 1   [1016, 288, 56, 16]
high platform 2   [1120, 288, 56, 16]
low slab          [1000, 320, 160, 64]
low spikes        [1080, 304, 24, 16]
final slab        [1200, 320, 160, 64]
finish            [1320, 264, 24, 56]
width             1360
fall_y            430  (unchanged)
```

**Reachability, checked against the starter's own physics before building:**

With `jump_velocity` 320, `gravity` 960 and `speed` 160, peak height is 320² / (2·960) = 53.3 px and total airtime is 0.67 s, giving a flat horizontal reach of ~107 px. Reach shrinks as the landing rises: ~87 px at +32, ~70 px at +48.

| Jump | Gap | Rise | Max reach | Margin |
|---|---|---|---|---|
| ground → high 1 | 56 | +32 | 87 | 36% |
| high 1 → high 2 | 48 | 0 | 107 | 55% |
| high 2 → final slab | 24 | −32 | > 107 | large |
| ground → low slab | 40 | 0 | 107 | 63% |
| low slab → final slab | 40 | 0 | 107 | 63% |

Every jump sits inside the envelope the starter already demonstrates (it ships a 64-wide gap and a 32-high block). No change to jump tuning is required or planned.

**Optional collectible.** If time allows, I will place one collectible from the GDD's cherry concept on the high route only, so that taking the safe line means forfeiting a reward. This converts the branch from a pure difficulty choice into a risk/reward one. This is a stretch goal; the branch works without it.

**Note (added after implementation):** the branch layout above was drafted
with AI assistance and is superseded — see the Revision Log for the three
layouts that failed and the geometry that shipped. Authorship breakdown is
in SOURCES.md.

---

## 3. What must remain unchanged

I am preserving, and will verify, all of the following:

- **Controls.** A/D and arrows to move, Space to jump, R to retry, Esc/P to pause. No new inputs.
- **Movement tuning.** Every value in `features/player/tuning.gd` stays as shipped: speed 160, acceleration 1280, deceleration 1920, jump_velocity −320, gravity 960, terminal_velocity 480, coyote_ticks 6, buffer_ticks 6.
- **Collider.** The 18x28 `RectangleShape2D` at offset (0, −14) in `player.gd::_ready()` is untouched. The new character is drawn to fit inside it rather than the collider being resized to fit the character.
- **Collision behaviour.** No collision checks removed, weakened, or bypassed.
- **Retry.** Death by spike or by falling below `fall_y` returns the player to spawn with the retry counter incremented.
- **Pause and completion.** Pause/resume and the completion panel with replay behave as shipped.
- **The original route.** The starter's section remains fully playable; the extension is appended, not substituted.

If any of these must change, the change will be stated explicitly, justified, and tested on its own rather than folded silently into another edit.

---

## 4. Predicted failure cases

### Prediction A — the camera will not follow into the new section

`first_steps.json` carries a `width` field, and the camera limit is very likely derived from it. Raising `width` may not be enough if the limit is computed once at load, clamped elsewhere, or duplicated as a constant in `game/session.gd`. I expect the player will be able to walk past x=960 while the view stops, leaving the ninja off-screen.

*How I will check:* walk to the far end of the extension and confirm both the player and the relocated finish flag stay visible. If the view stops, trace where the camera limit is set and compare it against the JSON `width`.

### Prediction B — background and label drawing will not move with the data

The assignment states that some drawing coordinates are hard-coded. The zone captions ("01 / GET MOVING", "02 / MIND THE GAP") and the pale background hills appear to be positioned independently of the solids array. I expect that after the JSON is correct, the level will be *playable* to the new end while the backdrop and captions stop at the old boundary, or a caption lands over the wrong section.

*How I will check:* compare a screenshot of the extension against the physics positions. Anything the player sees that disagrees with what the physics tests is a defect, not a cosmetic issue.

### Prediction C — the existing route test fixture will fail

`godot/tests/` holds a scripted route authored for the 960-wide layout. Moving the finish will break it, because the recorded input sequence ends at the old flag position.

*How I will check:* run the existing tests before touching anything to get a green baseline, then re-run after each change. I will extend the fixture to cover the new section rather than delete or weaken the assertion that fails, and I will state in TEST-REPORT.md exactly what I changed in the fixture and why.

### Prediction D — the ninja's narrow hood will look wrong against the collider

The hood is 12 wide while the collider is 18. When the ninja stands against a wall or under the raised platform, the collider will stop him roughly 3 px before the hood visually touches. I predict this will be unnoticeable in normal play but visible when pressed against geometry.

*How I will check:* walk into the side of the raised block and jump underneath it, facing both directions, and judge whether the gap reads as a bug. If it does, I will widen the shoulders rather than shrink the collider.

---

## 5. Verification plan

Beyond playing the game, I am writing a **reachability checker** as an independent script.

It reads the physics constants from `features/player/tuning.gd` and the geometry from `levels/first_steps.json`, derives the jump envelope from first principles, and asserts that every gap-and-rise pair in the level is inside it. It fails loudly on any jump it cannot justify.

The point is that the level's completability becomes a computed claim rather than an impression from playing. It also gives a direct cause-and-effect demonstration: altering `jump_velocity` in the input flips specific jumps from PASS to FAIL, which is a mechanism I can show on screen rather than assert.

The script only reads files. It cannot alter game behaviour, and it does not replace human playtesting.

Planned verification, in order:

1. Record a green baseline from the existing automated checks before any edit.
2. Character change; re-run checks; screenshot left, right, standing, jumping.
3. Level change; re-run checks; run the reachability checker.
4. Update the route fixture to cover the extension; document what changed.
5. My own full playtest: both routes, a real death, a retry, a completion, a replay.
6. At least two other people play it; record their actual words, not a summary.
7. At least one documented inspect-and-revise cycle driven by something observed.

---

## 6. Revision log

Append-only. Original predictions above are not edited.

### 2026-09-18 — character implemented

**Departures from the plan.** I added a sword slung across the back, which was not in the original concept. It is the strongest silhouette marker on the figure and does more to distinguish the ninja than the hood taper alone. I also replaced the per-line `facing` ternaries with a single `draw_set_transform` call that mirrors the canvas, so all geometry is authored facing right and the left-facing view is derived. That is less code and removes a class of bug where one element forgets to flip.

**Decorative overhang, declared.** The sword and the headband extend roughly 2–3 px beyond the 18-wide collider on the trailing side, and the sword's pommel sits about 1 px above the head. This is deliberate. Both read as carried equipment rather than body, and because they are drawn on the *trailing* side, the overhang always points away from the direction of travel — so the player never walks decoration into a wall ahead of them. The collider is unchanged at 18x28 with offset (0, −14). No movement tuning was altered.

**Sash colour vs hazard colour, checked.** The sash is crimson (`c0453c`) and the spikes are also red. I played the level standing beside the spike cluster to see whether the two would be confused. They were not — the spikes are a distinct shape and sit on the ground, and at no point did the sash read as a hazard. Keeping the crimson.

**Iteration record.** Three failed sword attempts before the current one: drawn in the same ink colour as the torso (invisible), drawn along the spine (covered by the 18-wide body), and drawn full-length to the ground (read as a staff). Resolved by moving it off the spine, giving it a light blade over a dark outline, and cutting the length at the hip. Details in section 1.

**Still outstanding from Prediction D.** I have not yet done the deliberate press-against-geometry test — walking into the side of the raised block and jumping underneath it, facing both ways. To be done and recorded in TEST-REPORT.md.


### 2026-09-18 — level extended

**Prediction A was wrong.** I predicted the camera would stop at the old
boundary. It did not. Reading `session.gd` showed the camera limit is
already parameterised:

    camera.position.x = clampf(player.position.x + 100, 320, float(level.width) - 320)

The right-hand invisible wall is likewise built from `level.width`. Changing
the JSON was sufficient; no camera code was touched. Confirmed by walking to
the relocated finish and completing the level.

**Prediction B was right.** The grid ran `range(0, 961, 32)`, the background
hills were a literal `[100, 470, 770]`, the FINISH caption was pinned at
x=878, and the backdrop rectangle was 1800 wide. All four stopped at the old
boundary while the level itself extended correctly. Evidence screenshot taken
before fixing. Repaired by deriving the grid and backdrop from `level.width`,
positioning the FINISH caption relative to `level.finish[0]`, and adding two
further hills.

**A defect I did not predict.** The hazard drawing took x from the level data
but hard-coded y as 320 and 304, and always drew three triangles 8px apart
regardless of the hazard's stated width. The collision triangles in
`_add_area` are built from the real rectangle. So a hazard placed anywhere
other than ground level would kill the player at its true position while
drawing at the bottom of the level. My own hazards sit at y=304 so the bug is
dormant in my layout, but it is exactly the visual/physics disagreement the
assignment warns about. Fixed by reading y, height and width from the entry
and deriving triangle width as `w / 3.0`, matching what the collision code
already does. Verified as a no-op refactor: the existing spikes render
identically.

**Three failed level layouts before the current one.**

1. *Routes stacked vertically.* High platforms sat directly above the low
   slab at +32. The player is 28 tall and the platform is 16 thick, leaving
   16px of headroom. The low route was physically unenterable. Found by
   playing, not by reading.
2. *High route out of reach.* I moved the platforms to y=256, which is 64
   above the ground. Peak jump height is 53. Unreachable by any input. Fixed
   by lowering the geometry into a three-step climb of 40 each — never by
   raising `jump_velocity`.
3. *Both routes equally fast.* Geometry worked, design did not: ground 10.5s,
   high 10.4s. The high route cost three precise jumps and a fall risk and
   returned 0.1s. Not a decision. Fixed by lengthening the ground route with
   a second gap and a third spike cluster while giving the high route wide
   flat hops.

**Measured outcome.** Ground route 14.5s, high route 9.6s, both with 0
retries, same player, same session. A 4.9s spread, roughly one third faster.
The fork now trades time against risk as the brief claimed.

**Final geometry** differs from the coordinates planned in section 2 above.
Those are left unedited as the original prediction. Current layout is in
`godot/levels/first_steps.json`; level width is now 1520 and the finish sits
at x=1480.

### 2026-09-20 — zone 3 redesigned after the time-based fork was disproved

**The claim in section 2 was wrong, and I proved it wrong myself.**

Section 2 asserts that the two routes "trade time against risk" — that the high
route would be faster and the ground route slower. After building it I measured
both and got 10.5s and 10.4s. I then rebuilt the section three more times trying
to open a gap, and each attempt either tied or broke one of the routes outright.

Rather than keep tuning by feel, I wrote a tick-accurate simulator of the game's
own movement code (`scripts/sim.py`) and a route search over it
(`scripts/solve.py`). The simulator mirrors `player.gd::_physics_process` step
for step at 60 Hz, including the order in which gravity and the jump assignment
are applied, the 18x28 collider, and axis-separated collision resolution.

**Validation before use.** The engine's own test reports `rise_px: 56.07` for a
single jump. The simulator produces 56.00 — a 0.07 px difference, which is the
gap between sampling a discrete physics tick and the true apex. I later checked
a full route: the engine completes the scripted fixture in 589 ticks and the
simulator predicts 592, agreeing to within 0.5% across ten seconds of play.

**The finding.** I searched 27 layouts with the solver. Every single one returned
an identical time for both routes. The reason is in the movement code:
`velocity.x` is never reset by jumping, landing, or changing height, so
completion time is horizontal distance divided by run speed and nothing else.
(1620 − 64) ÷ 160 matches the measured times almost exactly. A route that covers
the same x-range as another cannot be slower, however many platforms or hazards
it contains.

So the design premise in section 2 was not achievable. My earlier 14.5s versus
9.6s measurement was not the level working as intended — it was me hesitating on
an unfamiliar route.

**What I changed instead.** The only lever the engine allows is making a route
physically longer, which means forcing the player to travel ground they have
already covered. The finish was moved up onto a shelf at y=224, reachable
directly by the high route. The ground route can walk underneath and see the
flag but cannot reach it: the only way up is a step at x=1790, past the far end
of the level, and the stepping stone above it sits 96 px over the ground — beyond
the 56 px jump ceiling — so it cannot be shortcut from below. The ground player
must run to the east end, climb, then hop back west twice and walk back to the
flag at 1620.

Two earlier attempts at this failed because I placed that stone within jump
range at y=272, and the solver found the shortcut immediately. That is exactly
the kind of mistake playtesting would have taken a long time to surface.

**Verified result.** Solver: high route 9.73s, ground route 11.87s, a 2.13s cost
with optimal play, both routes proven completable. Measured by hand: high 10.1s
with 1 retry, ground 13.6s with 0 retries — a 3.5s spread, wider than the
optimum because the ground route also demands wayfinding.

**A second defect class the earlier checker missed.** While testing the ground
route I found I could not jump over a spike cluster: a high platform overhead
left 32 px of clearance, which is enough to stand under but not to jump in. The
jump in this game is fixed height — `player.gd` assigns `tuning.jump_velocity`
outright with no variable-height jump — so the player always rises the full
amount or bumps their head. Standing clearance and jump clearance are different
requirements and I had only checked the first. I extended
`scripts/check_reachability.py` with a jump-corridor check that scans for a
viable takeoff point at every hazard and gap, using the game's own 6-tick input
buffer to reject takeoffs a running player could not realistically hit.

The derived design rule, which I should have worked out before placing anything:
a ground-route jump needs roughly 110 px of clear sky, so a platform low enough
to be reachable from the ground can only sit over a flat stretch where no jump
is required.

**Final geometry** is in `godot/levels/first_steps.json`: width 1920, ten
solids, five hazard clusters, finish at (1620, 168). The coordinates planned in
section 2 above are left untouched as the original prediction and bear almost no
resemblance to what shipped.

**Route fixture.** `route_driver.gd` can only hold the right key, so it cannot
drive the ground route's backtrack. It now covers the high route instead, with
marks derived by `solve.py marks` rather than tuned by hand. The first generated
set failed in the engine because its marks fired inside the coyote-time window;
`solve.py` now pulls each mark back off the platform edge until a replay
confirms it completes. 25 of 25 mechanics checks and 9 of 9 keyboard checks pass.

**Honest note on effort.** This section was rebuilt roughly eight times. Most of
that was avoidable: I was hand-calculating projectile arcs and placing platforms
by eye when the physics were simple enough to simulate exactly. Writing the
simulator took about an hour and settled in minutes what guessing had failed to
settle all afternoon. The lesson I am taking is that when a system is small and
deterministic, simulating it is cheaper than reasoning about it.

**Verification plan status.** Items 2, 3, 4, 5 and 7 of section 5 are complete
and recorded in TEST-REPORT.md. Item 1 was not done — no pre-change baseline
was captured. Item 6, external playtesting, is still outstanding.

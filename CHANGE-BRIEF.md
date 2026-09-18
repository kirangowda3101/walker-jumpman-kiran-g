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

**[DECIDE AND EDIT: the branch layout above was drafted with AI assistance. Change the geometry — move the hazard, lengthen a route, or invert which route is risky — and record here what you changed and why. Note the same in SOURCES.md.]**

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

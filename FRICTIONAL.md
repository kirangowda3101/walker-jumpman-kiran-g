# FRICTIONAL — walker-jumpman-kiran-g

**Student:** Kiran Gowda Ramanagara Jayaram
**Course:** CSYE 7270, Fall 2026 — Assignment 1
**Period covered:** 18–20 September 2026

An honest log of what I attempted, what happened, and what I changed in
response. Entries are in the order things occurred. Where something worked
first time, it says so. Where I was wrong, it says that too.

Claude Code was used throughout, as the assignment expects. Each entry marks
what I decided and checked versus what the AI produced. A summary of that split
is in SOURCES.md.

---

## 1. Getting the starter running

**Expected:** clone, open, play. Maybe ten minutes.

**What happened:** the repository ships a `walker-jumpman.command` launcher. It
failed with "Godot was not found. Install the regular Godot 4 engine in
Applications." I had unzipped Godot into Downloads rather than Applications, so
the launcher's lookup missed it. Importing `godot/project.godot` into the editor
directly worked, and I used the editor for the rest of the project. Later, when
I needed to run the headless test suites from the terminal, I moved `Godot.app`
into `/Applications` properly, which also fixed the launcher.

**Learned:** the failure message was accurate and I ignored it for two days
because the editor route worked. Reading the error the first time would have
saved the detour.

**Human/AI:** my environment problem; the AI diagnosed the cause from the error
text.

---

## 2. Reading the character code before changing it

**Expected:** a sprite sheet to swap out.

**What happened:** there is no image anywhere in the project. The player is seven
`draw_rect` calls in `player.gd::_draw()`, and the collider is built in code in
`_ready()` as an 18x28 `RectangleShape2D` at offset (0, −14). That meant the
character replacement was arithmetic, not art: every shape had to fit inside
x ∈ [−9, +9] and y ∈ [−28, 0].

This went smoothly and I want to record that rather than invent difficulty. The
starter is legible, and the drawing order — outline first, fill on top, two
pixels inset — is a clear pattern to follow.

**Human/AI:** I read the file and worked out the collider bounds; the AI
explained the coordinate convention (y increasing downward, origin at the feet).

---

## 3. The ninja: four attempts at a visible sword

This is where I spent the most time on the character, and three of four attempts
failed.

**Attempt 1.** Sword drawn in `ink`, the same colour as the hood and torso.
Invisible. Obvious in hindsight: a dark shape drawn on top of a dark shape.

**Attempt 2.** Recoloured, but drawn along the spine. Still invisible — the
torso is 18 wide and the sword was inside that footprint, so the body covered it
completely at every frame.

**Attempt 3.** Moved off the spine and lengthened. Now visible, but it reached
the ground and read as a staff, not a sword.

**Attempt 4, kept.** Angled diagonally past the left side so it clears the
silhouette, drawn as a muted grey blade over a darker outline so it separates
from the robe, cut off at the hip, with a gold pommel above the shoulder.

**What I checked:** walked left and right after each attempt and looked at it on
screen. The test was simply whether I could see a sword.

**Learned:** at 18x28 pixels, contrast and silhouette decide whether a feature
exists. Detail that overlaps the body is wasted.

**Human/AI:** the AI wrote each version's GDScript. I rejected three of them on
sight and said what was wrong each time. The decision to move the sword off the
spine came from me noticing it was hidden behind the torso, not from the code.

---

## 4. Two smaller character decisions

**Headband sway.** The AI's version used `sin(tick * 0.3)`. I tried `0.9` to see
the difference and went back to `0.3` — at `0.9` the cloth moved faster than
fabric that size plausibly would. I then asked for the tail to be roughly twice
as long, with the far tip swaying 1.4x the near end so it whips rather than
swinging as a rigid stick.

**Sash colour.** The sash is crimson and the spikes are also red. I stood the
ninja next to a spike cluster and played that section specifically to see whether
the two would be confused. They were not — the spikes are a distinct triangular
shape sitting on the ground. I kept the crimson and recorded the check rather
than changing something that was not actually a problem.

**Learned:** a check that passes is still a check. I nearly changed the colour
because it sounded like a risk, before testing whether it was one.

**Human/AI:** both decisions mine; the AI implemented and offered alternatives I
did not take.

---

## 5. Predictions A and B: one wrong, one right

Before editing the level I predicted the camera would stop at the old boundary
and that hard-coded drawing coordinates would not follow the data.

**Prediction A was wrong.** The camera limit is already
`clampf(player.position.x + 100, 320, float(level.width) - 320)` — derived from
the JSON. Changing `width` was sufficient and I touched no camera code. The
right-hand invisible wall is parameterised the same way.

**Prediction B was right, and in four places.** The background grid ran
`range(0, 961, 32)`, the hills were a literal `[100, 470, 770]`, the FINISH
caption was pinned at x=878, and the backdrop rectangle was 1800 wide. All four
stopped at the old boundary while the level itself extended correctly. I took an
evidence screenshot before fixing anything, then derived the grid and backdrop
from `level.width` and positioned the caption relative to `level.finish[0]`.

**Learned:** I had assumed the starter was uniformly hard-coded. It is actually
split — physics and camera read the data, presentation mostly does not. Checking
which was which took one careful read of `session.gd` and would have taken much
longer by trial and error.

**Human/AI:** the AI found the camera line and the hard-coded drawing when I
asked it to search `session.gd`. I decided to fix the drawing properly, by
deriving from data, rather than typing in the new numbers.

---

## 6. A defect I did not predict

Reading the hazard drawing code, I noticed it takes **x** from the level data but
hard-codes **y** as 320 and 304, and always draws exactly three triangles 8px
apart regardless of the hazard's stated width. The collision triangles in
`_add_area` are built from the real rectangle.

So a hazard placed anywhere other than ground level would kill the player at its
true position while drawing at the bottom of the level. Both of my hazards sat at
y=304, so the bug was dormant in my layout and I would never have hit it by
playing.

I fixed it anyway: the drawing now reads y, height and width from the entry and
derives triangle width as `w / 3.0`, matching what the collision code already
does. I verified it as a no-op refactor — the existing clusters render
identically — which is the correct outcome for a fix that is right for data not
yet written and unchanged for data already written.

**Learned:** this is exactly the visual/physics disagreement the assignment
warns about, and it was findable only by reading. Playing would never have
surfaced it.

**Human/AI:** the AI spotted it while I had it walk through `session.gd`. I
decided to fix rather than document-and-leave, and I chose the no-op verification
as the way to confirm the fix.

---

## 7. The level, rebuilt about eight times

This was the hardest part of the assignment and most of the difficulty was
self-inflicted.

**Layout 1.** High platforms directly above the low slab at +32. The player is 28
tall and the platform is 16 thick, leaving 16 px of headroom. The low route was
physically unenterable. **Found by playing** — I walked into it and could not get
through.

**Layout 2.** Platforms moved to y=256, which is 64 above the ground. Peak jump
is 56. Unreachable by any input. I could not make the first jump at all. Fixed by
lowering the geometry into smaller steps, never by raising `jump_velocity`.

**Layout 3.** Both routes worked, but timed at 10.5s and 10.4s. The high route
cost three precise jumps and a fall risk and returned a tenth of a second. Not a
decision — decoration.

**Layouts 4 through 7.** Four more attempts at opening a time gap. Each either
tied again or broke one of the routes. In one of them the spikes became
unjumpable; in another the ground route was impossible entirely.

**Where I pushed back.** By roughly the sixth attempt I told the AI to stop
guessing and to simulate the physics instead of estimating arcs with projectile
formulas. That is the point the approach changed.

**Learned:** I let a loop run far too long. Every fix addressed the symptom I had
just seen rather than the underlying rule, and nobody — me or the AI — stopped to
ask why the same failure kept recurring in different clothes.

**Human/AI:** the AI generated every set of coordinates and got them wrong
repeatedly. I found two of the failures by playing, judged each result, and made
the call to change method.

---

## 8. The simulator, and what it proved

**What I asked for:** a tick-accurate replica of the game's movement rather than
an approximation, so layouts could be tested without playing them.

**What was built:** `scripts/sim.py` mirrors `player.gd::_physics_process` at
60 Hz — same order of operations, with gravity applied before the jump
assignment, the 18x28 collider, axis-separated collision resolution, coyote and
buffer windows, and the three-triangle hazard trigger. `scripts/solve.py`
searches routes over it breadth-first.

**How I checked it before trusting it.** The engine's own test reports
`rise_px: 56.07` for a single jump. The simulator produced **56.00**. Later, on a
full scripted route, the engine took 589 ticks and the simulator predicted 592 —
0.5% over ten seconds of play.

**The finding.** Across 27 candidate layouts the solver returned an identical
time for both routes every single time. The reason is in the movement code:
`velocity.x` is never reset by jumping, landing, or changing height. Completion
time is horizontal distance divided by run speed and nothing else. A route
covering the same x-range as another cannot be slower, however many platforms or
hazards it contains.

That invalidated my own design premise. CHANGE-BRIEF section 2 claims the routes
"trade time against risk." They could not. It also meant my earlier measurement
of 14.5s versus 9.6s was not the level working — it was me hesitating on a route
I did not know.

**What I changed.** The only lever available is making a route physically longer,
which means forcing a backtrack. The finish moved up onto a shelf. The ground
route can see the flag but not reach it; the only climb is past the far east end,
and the stepping stone above it sits 96 px over the ground, beyond the 56 px jump
ceiling, so it cannot be shortcut from below. Two earlier attempts at this failed
because that stone was placed within jump range at y=272 and the solver found the
shortcut immediately.

**Result.** Solver: 9.73s high, 11.87s ground. Measured by hand: 10.1s and 13.6s.

**Learned, and this is the thing I would carry forward.** The simulator took
about an hour and settled in minutes what a whole afternoon of guessing had
failed to settle. When a system is small and deterministic, simulating it is
cheaper than reasoning about it — and much cheaper than iterating against it by
hand. I should have reached for it after the second failed layout, not the sixth.

There is also a smaller lesson inside it: I had been designing against the
analytic apex of 53.3 px from the projectile formula. The engine's true discrete
value is 56. A 2.7 px error is enough to make a jump that should work feel
unreliable.

**Human/AI:** the AI wrote both scripts. I specified that the physics had to be
replicated rather than approximated, and I required validation against the
engine's own measurement before any result was used. The decision to abandon the
time-based fork rather than keep tuning was mine.

---

## 9. Two clearance bugs, found two different ways

**The one the checker found.** `scripts/check_reachability.py` reported a high
platform leaving 24 px of standing clearance for a 28 px player. The ninja could
not walk under it. I had never hit this because the jump onto that slab always
carried past the overhang — a player who landed short would have been wedged with
no way out except R. A soft-lock in a section I had already declared finished.

**The one playing found.** Later, on the ground route, I could not clear a spike
cluster. The ninja bumped the platform overhead every time. 32 px of clearance:
enough to stand under, not enough to jump in. The checker had passed that spot,
because it only tested standing height.

**Why both were the same mistake.** Standing clearance and jump clearance are
different requirements and I had treated them as one. The jump in this game is
fixed height — `player.gd` assigns `tuning.jump_velocity` outright, with no
variable-height jump — so the player always rises the full amount or bumps their
head.

**What I changed.** Extended the checker with a jump-corridor pass that scans for
a viable takeoff point at every hazard and gap, sized against the game's own
6-tick input buffer so it rejects takeoffs a running player could not realistically
hit. It now catches the bug I found by playing.

**Learned.** Neither method was sufficient alone. The checker found a defect
playing could not surface; playing found a defect the checker was blind to. The
table in TEST-REPORT section 4 lists four defects and the method that missed each
one. That table is the most useful thing I produced in this assignment.

**Human/AI:** the AI wrote and extended the checker. I found the second bug by
playing and required the tool be extended rather than the level simply patched.

---

## 10. The test fixture, and a wrong diagnosis

Prediction C said the scripted route fixture would fail once the finish moved. It
did — once per level redesign, six times in total. I never deleted the failing
assertion or weakened the expected result; each time I read the coordinates it
reported and extended the fixture.

**Where I was wrong.** At one point three different jump-mark values produced
byte-identical output — same position, same tick count. I concluded Godot was
running a cached copy of the script and deleted `godot/.godot` to clear it.
Nothing changed. My diagnosis was simply wrong.

**How I found out.** Added a temporary trace printing x, y, `is_on_floor()` and
the mark index every frame past x=1050. The trace showed `y=240` — the fixture
had been up on the high platforms since an earlier mark, and was airborne every
time it crossed the positions I was editing. The marks were never firing at all.

**Learned.** I assumed a tooling problem when the evidence only showed "no
change." Printing the actual state took two minutes and answered it immediately.
I should have done that before deleting caches.

**What changed as a result.** The marks are now generated by
`python3 scripts/solve.py marks` rather than tuned by hand. The first generated
set then failed in the engine despite completing in the simulator — its marks were
tick-exact and several fired inside the coyote window, after the player had left
the platform edge, where the engine's floor detection differs by a frame or two.
`solve.py` now pulls each mark back off the edge and replays until it completes.

**Coverage consequence, stated honestly.** `route_driver.gd` can only hold the
right key, so it cannot drive the ground route's backtrack. The fixture now
covers the high route. The ground route has no automated coverage, which is
listed as a limitation in TEST-REPORT.

**Human/AI:** the AI proposed the cache theory that turned out to be wrong, and
also wrote the trace that disproved it. I ran every test and made the call to
generate the marks rather than continue hand-tuning.

---

## 11. What I did not do

**No external playtester.** Every human result in this submission is my own. I
was not able to arrange for anyone else to play it. The consequence is specific:
I do not know whether a first-time player finds the eastern climb on the ground
route, because I know where it is and cannot un-know that. I added a ground-level
hint reading "No way up from here. Keep going right." but I have no evidence it
is sufficient. I have not invented a playtester or presented my own sessions as
anyone else's.

**No pre-change baseline.** I ran the test suites for the first time after the
character and level were already modified. The baseline in TEST-REPORT is
therefore inferred from the fact that only the route-specific check failed, not
recorded. A process mistake, and an easy one to avoid.

**Scope.** The level is now 1920 wide, double the starter's 960, and the
backtrack puzzle is the most complicated thing in the submission. The assignment
asked for scope small enough to inspect. A shorter section would have been easier
to explain and would have cost me far less of the time that went into eight
rebuilds.

---

## 12. Traceability

| Entry | Where to look |
|---|---|
| 3, 4 — character iterations | `git log` for player.gd; CHANGE-BRIEF section 1 |
| 5 — predictions A and B | CHANGE-BRIEF revision log, 2026-09-18 |
| 6 — hazard drawing defect | commit "Fix hazard drawing to read y and width from level data" |
| 7 — eight layouts | CHANGE-BRIEF revision log, both level entries |
| 8 — simulator and finding | `scripts/sim.py`, `scripts/solve.py`; TEST-REPORT section 3 |
| 9 — clearance bugs | `scripts/check_reachability.py`; TEST-REPORT section 4 |
| 10 — fixture failures | `evidence/mechanics-*.json`, including every failing run |
| 11 — what was not done | TEST-REPORT section 7 |

Every automated run in this project wrote a timestamped JSON receipt into
`evidence/`. The failing runs are committed alongside the passing ones and have
not been removed.

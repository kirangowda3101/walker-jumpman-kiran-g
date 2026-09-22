# RIFF — The Fork That Wasn't.

Commentary written after inspecting the captures, not from filenames or from the
project's documents. Each entry separates **observed** (what is on screen in the
named time range), **source** (a fact read out of the code, labelled as such),
and **untested** (a judgement with no evidence behind it, labelled as such).

Narrator: Liam, in for Bear · Kokoro `am_onyx` · Teardown register.
All five captures are **scripted input**. None of this is a human playtest, and
the only human play evidence for this project remains the author's own in
`TEST-REPORT.md` §5.

---

## run-01 → B02 · the whole level, start to finish (15.667 s)

**0.00–1.23 · the menu** — *observed.* The title panel sits over a live,
already-built level behind a dimming scrim. **Source:** `session.gd::_ready`
constructs every solid, hazard and the goal before the menu is ever shown; there
is no separate menu scene. That is why Enter costs nothing — nothing loads,
a flag flips.

**1.33–1.92 · run and stop** — *observed.* Held D accelerates to the speed cap;
the key comes off at 1.80 s and the figure travels about 5 px further before
settling, the leg cycle dropping to a level standing pose. **Source:**
`tuning.gd` — acceleration 1280, deceleration 1920. Stopping is 1.5× faster than
starting, which is the whole reason the character reads as planted rather than
slippery. *Trade-off:* it also means you cannot drift or carry a slide, so
every positioning error has to be fixed by walking, not by coasting.

**2.20–2.87 · facing** — *observed.* Pressing A flips the entire figure: sword
to the other shoulder, headband trailing the other way, pupil swapping side.
**Source:** one `draw_set_transform` canvas mirror in `player.gd::_draw`, not
per-limb ternaries. *Why it matters:* the failure mode it removes is the one
where a single element forgets to turn around, which is almost guaranteed once
a character has seven separate pieces.

**3.27 · the jump** — *observed.* A distinct airborne tuck — front knee up, back
leg trailing — reads as a third pose, not a stretched running frame.
**Source:** the jump is a single `velocity.y = tuning.jump_velocity` assignment
with no variable height. *Trade-off, and it is the load-bearing one for this
whole level:* you always rise the full 56 px or you bump your head. There is no
short hop. That is what turns a low ceiling from an awkward jump into an
impossible one, and it is why the author's reachability checker needed a
separate jump-corridor pass after a standing-height pass had already passed.

**4.23 · the spikes** — *observed.* Three red triangles pass under the airborne
figure. **Source:** the hazard trigger is three `CollisionPolygon2D` triangles
built across the cluster's real width, not an oversized box, so the near miss
you see is the near miss the physics saw. Worth saying because the drawing code
used to disagree with it: it took x from the level data and hard-coded y, which
the author found by reading and fixed.

**5.07 and 6.90 · the gaps** — *observed.* 64 px and 48 px cleared with the same
input and no change in pace. **Source:** flat reach is about 107 px, so both are
generous. *Observation that sets up the whole film:* nothing about the speed
changes across a jump — the arc costs no horizontal ground.

**8.10–11.53 · the climb and the runway** — *observed.* Ground → 272 → 224, then
a long flat run to the shelf.

**~6.0 s onward · the progress bar** — *observed defect.* The green HUD bar is
already hard against the right edge while the player is barely past the halfway
point of the course, and it stays there. **Source:** `hud.gd:24` computes
`clampf((x - 64) / 852, 0, 1)`. 852 was the starter's playable span; this level
is 1920 wide with the flag at 1620, so the bar saturates at x=916 and is dead
weight for the last third of every run. *This is the one defect the film found
that is not already in the project's documents* — `SOURCES.md` lists `hud.gd` as
unchanged, and the presentation-fix pass that repaired `session.gd` never
reached it. Cheap fix: divide by `level.finish[0] - level.spawn[0]`, the same
data-driven move already applied to the grid, the backdrop and the FINISH label.

**12.57 · completion** — *observed.* "Course complete. 11.3 seconds / 0
retries." **Untested judgement, flagged:** whether 11.3 s *feels* like a good
run is not something a scripted driver can tell you. The solver's optimum is
9.73 s, so this take is 1.6 s of conservatism, not a level being slow.

**14.57 · replay** — *observed.* Enter resets position, timer, retry counter and
the progress bar in one step.

---

## run-04 → B03 · the edges of the control model (9.233 s)

**0.90–2.40 · the west boundary** — *observed.* The figure walks into the west
edge and stops at x=10, still leaning left, and holds there. **Source, and this
is the interesting part:** `player.gd:67` ends the physics step with
`position.x = maxf(position.x, 10.0)`. It is a position clamp, not a collision —
the input log shows `velocity.x` pinned at **-160** for the entire hold while
the body does not move. There *is* an invisible wall in `session.gd`, but the
clamp fires first, at x=10, before the collider ever reaches it at x=9.
*Trade-off:* visually identical, and free. But the body is lying about its
state for as long as you hold the key, and anything that ever reads
`velocity.x` at the world edge — a footstep effect, a camera lead, a dust
particle — would read it wrong.

**4.87–5.20 · coyote time** — *observed, with tick evidence.* He runs off the
slab at x=448 with no jump pressed and is visibly already falling. The press
lands **3 ticks after the last ground contact** (log: ground tick 291, press
tick 294) and the jump fires anyway, out of mid-air, clearing the 64 px gap.
*A still frame cannot establish this* — the evidence is the gap between two
numbers in the input log, which is why this beat exists at all. Six ticks is
a tenth of a second of grace. *Trade-off:* it is invisible when it works and
indistinguishable from a bug when someone doesn't know it is there.

**5.27 · no double jump** — *observed.* A second press at the apex does
nothing; `vy` stays at +32 and the descent continues. **Source:** the jump
opportunity is consumed until the next floor contact. *Worth noting honestly:*
this press was deliberately placed at the apex, far from the ground. Inside the
last six ticks the same press would have been **banked, not discarded** — which
is the very next thing the beat shows.

**5.57–6.60 · solid collision** — *observed.* The landing puts him flush against
the left face of the 32 px block at x=576 and horizontal movement stops dead
with D still held. **Honest note about this take:** that pin was not staged. A
late coyote jump carries further than a normal one, and the driver ran straight
into the block; whether the next jump cleared it turned out to be a one-frame
coin flip, so the run-up had to be rebuilt around it. That is recorded in
`CAPTURE.md` §8 rather than hidden.

**7.33 · the input buffer** — *observed, with tick evidence.* Space is pressed
while still airborne at y=273.5, **5 ticks before** the feet reach the block
top, and the jump fires on the contact frame itself at `vy = -320`.
*The pairing is the point:* coyote time forgives a late press, the buffer
forgives an early one, and both are the same 6-tick budget on either side of
the ground contact. Symmetric forgiveness is why the control never feels like
it is arguing with you. *Trade-off:* a buffered jump can fire when you have
changed your mind, which is exactly the class of bug that killed the author's
first simulator-generated test fixture — its marks fired inside the coyote
window and the engine's floor detection disagreed by a frame.

---

## run-02 → B04 · failure, recovery, and the menus (15.867 s)

**0.90 · mouse start** — *observed.* A left click inside the green button
begins the session; no key is pressed until later in the take. **Source:** the
button is a hit-tested `Rect2` in `session.gd::_unhandled_input`, not a Control
node. *Trade-off:* it works, and it is the one input in the game the keyboard
test suite cannot reach.

**2.67 · spike death** — *observed.* The run freezes and a panel reads
**"Watch the spikes"** over "Back at the start in a moment."; RETRIES goes
00 → 01. *The riff:* the message names the cause, not the event. "You died"
teaches nothing; "watch the spikes" is a rule. It does not, however, tell us
whether a first-time player saw the danger coming — a scripted driver walked
into it on purpose.

**3.50 · auto respawn** — *observed.* About half a second later he is back at
spawn and playable, with no prompt and no keypress. **Source:**
`retry_remaining = 0.55`. *Trade-off:* short enough to keep your intent, long
enough to read the message. The cost of a mistake here is the walk back, which
is the honest cost of a level this length — and it is also why a 1920-wide
level with a backtrack puzzle is a bigger ask than the starter's 960.

**7.00 · fall death** — *observed.* Past the boundary at y=430: **"Missed the
landing"**, RETRIES 02. Two deaths, two messages, one `resolve_contacts` call.
**Source:** the fall boundary is a y threshold, not a collider — nothing to
clip through, nothing to land on by accident.

**9.70 · R restarts, and the counter does not move** — *observed.* RETRIES
stays on 02 across the restart. **Source:** `restart_attempt()` is called
straight from the input handler, while `deaths += 1` lives in
`resolve_contacts()` and only runs on a real death. *This is deliberate, not a
bug* — choosing to start over is not the same as failing, and the engine suite
asserts it with `manual-restart-not-death`. It is the sort of distinction that
is invisible until someone "fixes" it.

**11.60–13.20 · pause and resume** — *observed.* Escape freezes the run
**mid-air** and the panel reads "Take a breath." with "R: restart attempt /
M: main menu". Enter drops him back into exactly the same arc. **Source:** this
is a state flag on the player, not the engine's scene pause — which is why the
mid-air resume is seamless. It also clears the buffered jump on resume, so you
don't leap the instant you unpause. That is a small, deliberate piece of care.

**13.97 · P also pauses** — *observed.* **Trade-off:* the HUD control line
advertises only Escape, so the on-screen list is not a complete binding table.
Harmless; also the kind of thing that gets lost when someone rewrites the HUD.

**14.73 · M to menu** — *observed.* Live only from pause and from completion,
so a fumbled key cannot drop you out of a live run.

---

## run-05 → B05 · focus loss (6.067 s)

**1.90 · the window loses focus** — *observed.* A second engine window takes
focus and the game pauses itself mid-stride; the timer holds and nothing moves
again for the rest of the take. This is a genuine `focus_exited` on the root
window, not a synthesised signal.

*The riff, and it is a slightly uncomfortable one:* this is the only behaviour
the other four takes had to switch off to record reliably. `test_mode` exists in
`session.gd` precisely so the test suite can escape it. That is its own kind of
evidence — the auto-pause is aggressive enough that an unattended machine will
interrupt you. For a player alt-tabbing away from a precision platformer that is
exactly right. For anything that wants to keep running in the background it
would be wrong, and the game does not offer a choice.

---

## run-03 → B06 · the ground route and the backtrack (14.867 s)

**6.90 · the fork** — *observed.* Identical opening, identical jumps, and then
at x=1014 he simply does not take the step up at x=1060. *The riff:* the fork
is a choice not to climb. There is no wall and no door — nothing stops you going
up, so the level has to make going along cost something. That is a much harder
design problem than it sounds, and this project failed at it repeatedly before
solving it.

**7.35 · four pixels of margin** — *observed.* He walks underneath the stepping
stone with the platform passing just over the hood. **Source:** the platform's
underside is at y=288 over ground at y=320 — **32 px of clearance for a 28 px
collider**. *The riff:* standing clearance and jump clearance are different
numbers in this game, and treating them as one is the defect class that got
past the author's first reachability checker. A 28 px body fits under 32 px. A
jump needs the full 56 px rise plus the body — about 84 px — and no amount of
skill shortens it, because the jump is fixed height.

**7.93–10.33 · four clusters on the ground** — *observed.* Each one cleared
with a takeoff pulled deliberately early. **Source:** the marks for this take
were derived over the project's own simulator and required to survive ±3 px of
jitter, because `TEST-REPORT.md` §2 records tick-exact marks completing in the
simulator and then dying in the engine.

**10.33 · the flag you cannot reach** — *observed.* The finish is plainly
visible on the shelf overhead and there is no way up from the ground; the level
itself says so, in text on the ground plane: *"No way up from here. Keep going
right."* *The riff:* that line is the design admitting the puzzle is not
self-evident. **Untested, and this is the film's biggest open question:**
whether it is enough. The only person who has played this knows where the climb
is, and cannot un-know it.

**11.83–13.03 · the backtrack** — *observed.* He runs *past* the flag to the
step at x=1790 — past the east end of the course — climbs it, turns west, and
hops back along the shelf to finish at x=1620 in 12.3 s.

*The riff, and the reason the film is called what it is.* The author's original
design premise was that the two routes would trade time against risk. They
cannot. **Source:** `velocity.x` is never reset by jumping, landing or changing
height, so completion time in this game is horizontal distance over run speed
and nothing else — a route that covers the same x-range as another cannot be
slower, however many platforms or hazards you pile onto it. The author found
this by writing a tick-accurate simulator and searching 27 layouts that all
returned identical times, and then redesigned around the only lever the engine
left: force the player to walk ground they have already covered.

*The trade-off that buys:* the fork is now real — 11.3 s against 12.3 s here,
2.13 s at optimal play. *The trade-off it costs:* the level is 1920 px wide,
double the starter, and the interesting decision is a wayfinding puzzle rather
than a control challenge. The author says as much in `FRICTIONAL.md` §11. It is
a good solution to a problem that a smaller scope would not have had.

---

## Suggested next experiments

1. **Fix the progress bar and watch what it changes.** Divide by
   `level.finish[0] - level.spawn[0]` instead of 852. Then play the ground route
   and see whether a truthful bar makes the backtrack legible — it is the only
   HUD element that could tell a lost player they are going the right way.
2. **Give the route fixture a second axis.** This is the film's Your Turn
   prompt. The ground route currently has no automated coverage at all.
3. **Put the level in front of one person who has never seen it** and say
   nothing. Time how long they spend under the shelf before they go east. That
   single number answers the one question neither the simulator nor the checker
   nor this film can.

# QC REPORT — The Fork That Wasn't.

Master: `exports/landscape/claude-liam-walker-jumpman-walkthrough.mp4`
3840×2160 · 30 fps · 5022 frames · 167.40 s · H.264 + AAC 48 kHz stereo
SHA-256 `a6a46018fdf342300cb94f5dc6886b6c0f2add217da710d8c6a17e9d4bbf329a`

Two layers of QC: the automated Gate V pass (verbatim in
`_qc/GATE-V-REPORT.md`) and this human review of the actual rendered film.
Machine checks cannot judge whether a described action occurs or whether an
inventory is complete; that part is below.

---

## 1. Automated gates

| Gate | Result |
|---|---|
| `godot-waikthrough --check` | **PASS** — 28 implemented features, 4 planned, 31 evidence intervals, all five captures 3840×2160 16:9 |
| Gate V (frame-level visual) | **PASS** — 20 frames, 0 BLOCKER, 0 MAJOR |
| Gate T (type-lock, §8.1–8.6) | **PASS** — 10 beats, 0 FAILs (`TYPECHECK.md`) |
| `beat_lint` / `gate_shape` | clean |
| Export receipt | `build-state.json` and `.verified.json` both `ready`, hashes match the delivered file |

Gate T initially reported **skipped** because the default interpreter had
numpy 2.2.6 with a scipy built against numpy 1.x. That is a missing-dependency
condition, not a pass. It was resolved by running the export under an isolated
interpreter with numpy 2.5.3 / scipy 1.18.1, and Gate T then ran for real and
passed. No gate was disabled, downgraded or bypassed to obtain this master.

## 2. Timing — no gameplay was retimed

Every slot's compositor ratio is exactly **1.000000**, verified per beat by
matching each `media/<beat>.mp4` frame count against `render_duration_s` at
30 fps. No clip was slowed, sped up, centre-cut or trimmed.

Stronger evidence: the five gameplay slots are **byte-identical** to the hashed
captures in `coverage.json`.

| Beat | media SHA-256 | capture | identical |
|---|---|---|---|
| B02 | `ff0f0c31…` | run-01 | ✓ |
| B03 | `b3eabef6…` | run-04 | ✓ |
| B04 | `b498f0d0…` | run-02 | ✓ |
| B05 | `5e716543…` | run-05 | ✓ |
| B06 | `26d89e7f…` | run-03 | ✓ |

## 3. Frames inspected

Sampled at 15 / 50 / 85 % of every beat from the **delivered master** (not the
review cut) and read as images.

| Beat | Checked | Finding |
|---|---|---|
| B00 | prompt legibility, disclaimer, no fake receipts | Clean. Full Walker prompt readable; "Illustrative reconstruction of the ask. Not a saved transcript." is the first output line and plainly legible. No invented progress bar or file-write log. |
| B01 | the correction lands before the cut | **Fixed during QC — see §5.** Now: `risk` deleted at ≈10.4 s, `distance` typed by ≈11.2 s, held to 12.6 s. |
| B02 | framing, HUD, completion panel | Clean, full frame, no crop. Completion panel reads "11.3 seconds / 0 retries". |
| B03 | west clamp, coyote, apex press, buffer | Clean. All four events visible in sequence. |
| B04 | death panels, retry counter, pause panel | Clean. "Watch the spikes" / "Missed the landing" / "Take a breath." all legible at 4K. |
| B05 | pause on focus loss | Clean. Panel appears mid-stride, timer holds. |
| B06 | the traverse, the hint, the backtrack | Clean. At 85 % the figure is on the stepping stone, **mirrored and facing west**, heading back to the flag at 12.0 s — the film's thesis shot. |
| BVDT | all 8 verdict lines | Clean and legible; WORKS / DEFECT / UNTESTED / NOT BUILT clearly separated. |
| BHTF | prompt legibility | Clean. |
| BOUT | outro lock | Clean — see §4. |

## 4. Outro lock (`OUTRO-LOCK.md`)

- ✓ exact title restated: **"The Fork That Wasn't."**
- ✓ handle `@NikBearBrown`, hardcoded by the component
- ✓ one crisp-safe mascot, slug-seeded, **below** the handle
- ✓ **no subline**
- ✓ spoken, never scored: narration is "The Fork That Wasn't. At Nik Bear Brown."
- ✓ the final 1.0 s of the file measures **−91.0 dB mean / −76.3 dB peak** —
  a genuine silent tail hold. No jingle, no music, no sound effect, no gameplay
  audio on the card.

## 5. Defects found and fixed during QC

**BLOCKER — B01's correction never appeared (fixed).** The first render of the
hesitant-writer beat was truncated: at 85 % of the beat the writer was still
mid-line-2 ("…up to the same fg"), so the `risk` → `distance` swap — the entire
point of the beat and the film's thesis — was cut off. Cause: the composition's
natural performance ran past the 11.03 s beat window and `-t` clipped it.
Fixed at the source, not by relabelling: type raised 88 → 104, `charMs`
34, `mistakeRate` 3, `hesitateBetween` 10, text tightened, `durationSeconds`
12.6, and the beat window extended to 12.60 s. Re-rendered and re-verified by
sampling frames at 7.0 / 8.5 / 9.5 / 10.5 / 11.5 / 12.4 s. The correction now
lands at ≈10.4–11.2 s, which is also when Liam speaks it.

**Cut from the film before render — a ceiling-bump claim that was false.** An
earlier feature entry asserted the ground route's spike jumps clip the runway
overhead. Arithmetic said the difference was 4 px, and a frame inspection at
the apex (run-03 frame 247) showed the player passing through the 24 px gap
between platforms and touching nothing. The claim was removed rather than
softened. Logged in `FACTCHECK.md` §3.

## 6. Two heuristic flags, inspected rather than suppressed

Both were declared per-beat in the beat sheet using the gate's own sanctioned
mechanism, each with a written reason visible in the diff. Neither disarms a
check globally, and no gameplay was relabelled as a source report.

**`edge-bleed` on B02–B06 → `qc.full_bleed`.** These are unmodified engine
captures. The game draws its backdrop, ground plane and HUD bands edge to edge,
so content crossing the 5 % title-safe inset is a video game filling the screen,
not a card overflowing. Verified by eye on all five beats: nothing is clipped,
nothing is cut off, no text runs off frame.

**`low-contrast` on B02 / B05 → `qc.contrast_regions`.** Whole-frame average
contrast measured 0.25 against a 0.30 floor. Cause identified by inspecting the
pixels: `hud.gd` draws a translucent scrim over the *play area* behind its menu,
pause and completion panels, which drags the frame average down. The panels
themselves are dark navy `#25354a` on near-white `#fffdf7` — high contrast, and
confirmed legible at 4K (see the B05 pause panel and the B02 completion panel).
Two regions are declared and measured instead: the HUD title/control band and
the HUD retry/timer band, both of which sit outside the scrim and carry text in
every frame of every gameplay beat. All declared regions pass.

**`underfill` on B01 → `qc.sparse_by_design`.** The hesitant writer accumulates
its overview token by token, so a mid-beat frame is mostly cream by design —
this is the case the gate's own documentation names. Type was also raised to
104 px so the finished sentence reads from across a room.

## 7. Audio

Per-beat levels are consistent across the film (mean −25.9 to −28.2 dB, peaks
−5.3 to −8.6 dB); no beat is missing narration and none is clipped. The game
itself has no audio at all, so nothing was muted and no sound effects were
invented. Narration is the only track.

## 8. What this QC does not certify

- That the scripted input represents how a human plays. It does not; all five
  captures are `scripted-input` and the film says so.
- That the feature inventory is exhaustive. Three engine-suite edge cases
  (duplicate-death suppression, death-over-finish precedence, the twenty-retry
  soak) are asserted by `evidence/mechanics-*.json` and are not staged on camera.
- That the game is fun, fair or finished. Those are human judgements, and the
  film's largest open question — whether a first-time player finds the eastern
  climb — is stated out loud in the verdict rather than answered.

# SHOTLIST — The Fork That Wasn't.

10 beats · 167.400 s (2:47) · 3840×2160 · 30 fps · Liam (Kokoro `am_onyx`)

Every slot is native 3840×2160 and every slot's compositor ratio is exactly
`1.000000`, so no gameplay is sped up, slowed down, trimmed or centre-cut.
Gameplay beats are clocked by their capture; narration sits inside that window
with silence on either side.

| # | Beat | Slot | Source | Frames | Length | Lead sil. | Voice | Tail sil. |
|---|---|---|---|---|---|---|---|---|
| 1 | B00 | `ClaudeComposerAsk` | Remotion | 627 | 20.900 s | — | 20.89 | 0.01 |
| 2 | B01 | `BrutalistHesitantWriter` | Remotion | 378 | 12.600 s | 0.80 | 10.22 | 1.58 |
| 3 | B02 | capture | `run-01.mp4` | 470 | 15.667 s | 0.40 | 12.33 | 2.94 |
| 4 | B03 | capture | `run-04.mp4` | 277 | 9.233 s | 0.30 | 8.17 | 0.76 |
| 5 | B04 | capture | `run-02.mp4` | 476 | 15.867 s | 1.00 | 11.97 | 2.90 |
| 6 | B05 | capture | `run-05.mp4` | 182 | 6.067 s | 0.20 | 5.48 | 0.38 |
| 7 | B06 | capture | `run-03.mp4` | 446 | 14.867 s | 1.20 | 12.14 | 1.53 |
| 8 | BVDT | `ClaudeVerdictArtifact` | Remotion | 1107 | 36.900 s | — | 36.86 | 0.04 |
| 9 | BHTF | `ClaudeComposerAsk` | Remotion | 939 | 31.300 s | — | 31.29 | 0.01 |
| 10 | BOUT | `ClaudeTitleOutro` | Remotion | 120 | 4.000 s | — | 2.99 | 1.01 |

Gameplay: **61.700 s** across 5 beats. Bookends: **105.700 s** across 5 beats.

**Each gameplay beat is one unbroken take.** `media/Bxx.mp4` is a byte copy of
the corresponding `capture/run-0x.mp4`; nothing is concatenated, and there are
no cuts inside a beat. The lead-in silences above were chosen so each spoken
claim lands on the action it describes, and were checked against the rendered
film (see `_qc/REPORT.md`).

---

## Beat by beat

### B00 — cold open · the Walker ask · 20.900 s
Claude composer on cream. Greeting `Namaste, Liam`. The reconstructed Walker
prompt types itself; the running indicator reads `reading GDD.md — first-steps
slice…`; three output lines land, the first of which labels the prompt an
illustrative reconstruction. Footer chip `@NikBearBrown`.

### B01 — what was actually built · 12.600 s
The hesitant writer types three lines on the cream page, ending
"The fork trades time for **risk**." It stops, deletes `risk` in terracotta and
types `distance` at ≈10.4–11.2 s — which is when Liam says it — then holds the
corrected sentence to the cut. Seed `walker-jumpman-fork-2026`: same seed, same
performance, every render. 0.8 s of lead silence so the typing starts before the
voice does. The first render of this beat was truncated before the correction
landed; see `_qc/REPORT.md` §5.

### B02 — the whole level, start to finish · 15.667 s · `run-01`
| at | on screen |
|---|---|
| 0.00 | title panel "First steps. Real jumps." over the dimmed level |
| 1.23 | Enter — panel clears, timer starts |
| 1.33–1.92 | runs right, key released at 1.80, glides to a standing stop |
| 2.20–2.87 | faces left; sword, headband and pupil swap sides |
| 3.27 | jumps the 16 px step at x=160 |
| 4.23 | clears the zone-01 spike cluster |
| 5.07 / 6.90 | crosses the 64 px and 48 px gaps |
| 8.10–9.80 | the third-zone climb: ground → 272 → 224 |
| 11.53 | the long runway |
| 12.57 | flag — "Course complete. 11.3 seconds / 0 retries" |
| 14.57 | Enter — timer, retries and progress bar reset |

### B03 — the edges of the control model · 9.233 s · `run-04`
| at | on screen |
|---|---|
| 0.90–2.40 | holds left into the west boundary; stops dead at x=10 and stays leaning |
| 4.87 | runs off the slab edge, no jump pressed, already falling |
| 4.90 | Space — 3 ticks after the last ground contact; the jump fires from mid-air |
| 5.27 | Space again at the apex — nothing; still falling at +32 |
| 5.57 | lands flush against the 32 px block at x=576 and stops |
| 6.60 | backs off west for a run-up |
| 7.33 | Space 5 ticks before touchdown; the jump fires on the contact frame |

### B04 — failure, recovery, and the menus · 15.867 s · `run-02`
| at | on screen |
|---|---|
| 0.90 | the START button is clicked, not keyed |
| 2.67 | spike death — "Watch the spikes", RETRIES 01 |
| 3.50 | unprompted respawn at the start |
| 7.00 | fall death — "Missed the landing", RETRIES 02 |
| 9.70 | R — back at spawn, RETRIES still 02 |
| 11.60 | Escape — "Take a breath." / "ENTER / RESUME" |
| 13.20 | Enter — resumes into the same mid-air position |
| 13.97 | P — pauses as well |
| 14.73 | M — back to the title panel |

### B05 — focus loss · 6.067 s · `run-05`
Playing and moving right at 1.90 s a second engine window takes focus; the pause
panel appears mid-stride and the timer holds for the rest of the take. This is
the only take with the game's focus-loss auto-pause left enabled.

### B06 — the ground route and the backtrack · 14.867 s · `run-03`
| at | on screen |
|---|---|
| 0.73–6.20 | the same opening and the same jumps as B02 |
| 6.90 | at x=1014 he does **not** take the climb at x=1060 |
| 7.35 | walks underneath it — 32 px of clearance over a 28 px collider |
| 7.93–10.33 | four spike clusters cleared on the ground slab |
| 10.33 | the flag is visible overhead; the level reads "No way up from here. Keep going right." |
| 11.83 | climbs the step at x=1790, past the east end of the course |
| 12.03–12.80 | turns west and hops back along the shelf |
| 13.03 | flag — "12.3 seconds / 0 retries" |

### BVDT — verdict · 36.900 s
Claude artifact page, "Walker Jumpman — extended slice". Eight lines: five
WORKS, one DEFECT (the progress bar), one UNTESTED (no external playtester),
one NOT BUILT (cherries, moving platform, audio).

### BHTF — your turn · 31.300 s
Composer returns, greeting `Your turn.`, running indicator `paste this into
Claude…`. The prompt asks Walker to replace the route fixture's right-only
driver with a timed axis sequence and prove it by failing on a weakened
`jump_velocity`. Liam reads it aloud in full, discusses why the failure clause
is the point, and signs off "Liam, in for Bear."

### BOUT — outro · 4.000 s
`ClaudeTitleOutro`: the exact title "The Fork That Wasn't.", `@NikBearBrown`
beneath it, one slug-seeded crisp-safe mascot below the handle, no subline.
Spoken, never scored — "The Fork That Wasn't. At Nik Bear Brown." over 2.99 s,
then a 1.01 s silent tail hold. No jingle, no music, no gameplay audio.

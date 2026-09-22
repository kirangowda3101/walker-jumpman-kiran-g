# CHECKS-REPORT — The Fork That Wasn't.

Written before the first compile, per the PROOF GATE.

## Beat classification

    10 SHOW / 0 justified-HOLD / 0 PUNT-flagged

| Beat | Class | Artifact named in `shot.show` |
|---|---|---|
| B00 | SHOW | Claude composer; prompt types itself; three output lines land |
| B01 | SHOW | the hesitant writer types, stops, deletes `risk`, types `distance` |
| B02 | SHOW | real gameplay — menu, start, character, all three zones, completion, replay |
| B03 | SHOW | real gameplay — west clamp, coyote jump, dead apex press, buffered jump |
| B04 | SHOW | real gameplay — mouse start, two deaths, respawn, R, pause, P, M |
| B05 | SHOW | real gameplay — focus steal, pause panel, frozen timer |
| B06 | SHOW | real gameplay — the fork, 32 px traverse, the hint, the backtrack, the flag |
| BVDT | SHOW | verdict artifact page; eight lines land as the voice names them |
| BHTF | SHOW | composer; the Your Turn prompt types itself while it is read aloud |
| BOUT | SHOW | title card, handle, slug-seeded mascot |

No beat could be exported as a static slide. The five gameplay beats are moving
evidence; the five bookends all animate their `show` events. No slates.

## Teaching arc

    FRAMEWORK ✓   B01 states the whole idea before any specific: two routes,
                  and the fork can only trade distance.
    WORKED EXAMPLE ✓  B02 plays the entire level start to finish before the
                  film takes anything apart.
    FALSIFIABILITY ✓  B03 carries tick evidence for two claims a still frame
                  cannot establish; BVDT names a defect found on screen, an
                  untested question, and four features that were never built.
    SCAFFOLDED TASK ✓  BHTF gives a prompt that closes the project's own
                  largest coverage gap, read aloud and discussed, ending in one
                  concrete experiment the viewer can run.
    BOOKENDS ✓    B00 ask · B01 overview · body · BVDT verdict · BHTF handoff ·
                  BOUT title outro.
    NO-SOURCE-NO-VERDICT ✓  Every verdict line traces to `FACTCHECK.md`.

## Walker-mode order (godot-waikthrough §3)

1. ✓ B00 `ClaudeComposerAsk` — prompt begins "Please use Walker to convert my
   game design document about …", describes this game's actual idea, asks for a
   playable Godot project. No literal `X` placeholder. Declared an illustrative
   reconstruction on screen, in narration, in `PROMPTS.md` and in `SOURCES.md`.
   No fictional build or progress receipts.
2. ✓ B01 — what was actually built, in plain language, with the slice's real
   limits. Hesitant-writer overview with a meaningful correction
   (`risk` → `distance`), 12.60 s window, `lead_silence_s: 0.8`. The correction is
   on screen from ≈11.2 s and holds to the cut — verified frame by frame after
   the first render truncated it (`_qc/REPORT.md` §5).
3. ✓ B02–B06 — the feature walkthrough and synchronized riffs.
4. ✓ BVDT verdict → BHTF Your Turn (Liam signs off here) → BOUT regular outro.

## Outro lock

- ✓ `ClaudeTitleOutro`, exact title "The Fork That Wasn't."
- ✓ `@NikBearBrown`, hardcoded by the component
- ✓ one slug-seeded crisp-safe mascot below the handle
- ✓ no subline
- ✓ spoken, never scored: "The Fork That Wasn't. At Nik Bear Brown." + 1.01 s
  silent tail hold. No jingle, no music, no gameplay audio, no invented voice.

## Gates, as run

    ./art godot-waikthrough --check   PASS · 28 implemented · 4 planned · 31 intervals
    Gate V (visual)                   PASS · 20 frames · 0 BLOCKER · 0 MAJOR
    Gate T (type-lock)                PASS · 10 beats · 0 FAILs
    beat_lint / gate_shape            clean
    export receipt                    ready; hashes match the delivered file

Gate T first reported *skipped* on a broken numpy/scipy pair. That is a missing
dependency, not a pass; the export was re-run under an interpreter where the
gate actually executes. No gate was disabled or downgraded.

## Timing contract

Every slot's compositor ratio is exactly `1.000000` — verified per beat by
matching each `media/<beat>.mp4` frame count to `render_duration_s` at 30 fps.
No gameplay is retimed, slowed, trimmed or centre-cut. Narration is fitted
inside each capture's window with silence, never by stretching the action.

## Known limitations of these checks

Machine checks cannot certify that a described action occurs, that an input log
is truthful, or that the feature inventory is complete. Those were done by
reading the source, inspecting frames, and are recorded in `RIFF.md`,
`FACTCHECK.md` and `_qc/REPORT.md`.

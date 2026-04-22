<!-- Mirror of /v2-artifacts/undrmnd_content_rubric_v2.md — update both together -->

# undrmnd v2 content rubric (editorial)

Canonical copy for the repo also lives at `v2-artifacts/undrmnd_content_rubric_v2.md` (duplicated for Windows-friendly paths).

## North star

Content should **lower barriers to inquiry** without **maximizing time-on-app**. There are no streaks, karma, levels, or fake urgency. Citations and links must point to real sources—never fabricate a DOI or URL.

## Ten merge gates (PR checklist)

1. **Open question** — The card is framed as a genuine open question (not a statement disguised as a poll). `is_open_question` is `true` only when it passes this gate.
2. **Pillar** — `topic` is one of: `cosmos`, `living_world`, `mind_and_brain`, `how_we_know`.
3. **Interaction** — `interaction_type` is exactly one of: `read`, `reflect`, `observe`, `contribute`. The verb matches the actual affordance in the app.
4. **Sources** — `source_citation` and `source_url` (when `read`/`observe`/`contribute` need a reading) are real; if you cannot find a citable line, the card is not ready.
5. **Action URL** — For `contribute` (and `observe` / `read` when “do the thing” differs from the reading), `action_url` is non-null and points at the handoff. No invented tracking links.
6. **No dark patterns** — No streak language, no leaderboards, no “one more for free,” no guilt framing, no false scarcity.
7. **Byline** — `contributed_by` is a valid handle; no impersonation. Path-level “single author” is avoided—authorship is per card/node where relevant.
8. **Time honest** — `estimated_time_minutes` reflects a calm read/do, not a speed-run.
9. **Body length** — Enough context to be fair; not an endless feed chunk. Stopping is visible.
10. **Activation** — New rows land with `is_active = false` until a human has read the live line on-device and flips the flag (two-person rule optional but encouraged).

## Anti-patterns (reject in review)

- Gamification, badges for completion, haptic “rewards” for finishing.
- Pull-to-refresh without friction on feeds (not this PR, but if referenced).
- Conflating `source_url` and `action_url`—they are distinct columns.

## Proposal flow

Proposals arrive as `content_proposals.sql` in a PR, never a direct `INSERT` into `content_items` in production. On merge, maintainers run with `is_active = false`, read once in staging, then flip on.

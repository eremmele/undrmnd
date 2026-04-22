## Summary

What changed and why (1–3 sentences).

## How to test

- [ ] Build **undrmnd** scheme, run on simulator
- [ ] `⌘U` / CI unit tests (if you touched logic)

## Affects content or database?

- [ ] **No** — app-only / tooling
- [ ] **Yes** — I attached `content_proposals.sql` (or similar) and updated docs if needed

## Content merge gates (from [`docs/CONTENT_RUBRIC.md`](../docs/CONTENT_RUBRIC.md))

Skip if this PR has no content/schema impact.

- [ ] **Open question** — genuine question framing; `is_open_question` only when it passes
- [ ] **Pillar** — `topic` in `cosmos` | `living_world` | `mind_and_brain` | `how_we_know`
- [ ] **Interaction** — `interaction_type` is `read` | `reflect` | `observe` | `contribute` and matches the affordance
- [ ] **Sources** — `source_citation` / `source_url` real when required
- [ ] **Action URL** — `action_url` set when “do the thing” differs; no fake tracking links
- [ ] **No dark patterns** — no streak/leaderboard/guilt/scarcity copy
- [ ] **Byline** — `contributed_by` is a real handle, no impersonation
- [ ] **Time honest** — `estimated_time_minutes` is a calm read/do
- [ ] **Body length** — fair context, visible stopping point
- [ ] **Activation** — new rows with `is_active = false` until human verification

## Schema / Swift alignment

If you changed `v2-artifacts/undrmnd_schema_v2.sql` or app models, confirm decoding still matches the RPCs (`get_path`, `get_random_cards`, etc.).

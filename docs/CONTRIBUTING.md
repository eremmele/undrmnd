# Contributing to Undrmnd

## Build and test

- Open `undrmnd/undrmnd.xcodeproj` in Xcode (or the workspace in your layout).
- Run the **undrmnd** scheme on a simulator: **Product → Test** (⌘U) for unit tests.

## Content and Supabase

- **Editorial source of truth:** [`docs/CONTENT_RUBRIC.md`](CONTENT_RUBRIC.md) (kept in sync with `v2-artifacts/undrmnd_content_rubric_v2.md`).
- **Schema source of truth:** `v2-artifacts/undrmnd_schema_v2.sql` — the app’s Swift model types should match it; if they drift, fix Swift and document the change.
- **Proposing new cards or paths:** add a `content_proposals.sql` (or matching name) in your PR with `INSERT` statements for review. Do not edit production `content_items` directly; new rows should land with `is_active = false` until a human has verified the live line on a staging build and flips the flag, per the rubric.
- The app does not run database migrations; apply SQL in your Supabase project as documented in the v2 artifacts.

## Pull requests

Use the [pull request template](../.github/PULL_REQUEST_TEMPLATE.md), including the ten merge gates from the content rubric when the change affects editorial or schema.

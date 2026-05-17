# Undrmnd

A SwiftUI iOS app with a modular architecture, designed to lower the barriers to scientific inquiry and make curiosity-driven exploration feel as welcoming as social media. Instructions live at [undrmnd.com](https://undrmnd.com) · iOS 17+ · Built with SwiftUI + Supabase

<img width="2736" height="1041" alt="preview" src="https://github.com/user-attachments/assets/44d4a4e7-8397-486c-a001-54fb24d162d9" />


---

## Design North Star

- **Lower barriers to inquiry**: Lower the psychological and cultural barriers to scientific inquiry so anyone, at any age, can ask questions, explore interests, and contribute without credentials or fear of backlash.
- **Delight without addiction**: Feel as delightful and welcoming as social media, with polished mobile UX, but use finite sessions, clear stopping points, and e-ink visuals instead of addictive feeds.
- **From doomscrolling to contribution**: Replace passive doomscrolling with micro-interactions that foster curiosity, reflection, and any-sized but real contributions to shared projects and research efforts.
- **Beginner-friendly communities**: Create safe, semi-moderated community spaces where “beginner” questions and diverse lived experiences are treated as assets, not liabilities.
- **Open-source infrastructure**: Ship and maintain everything as open-source infrastructure that communities can fork and adapt, proving that ethical, counter-algorithmic learning platforms can exist outside extractive business models.

---

## What's built

- **Onboarding** — Comet-style onboarding flow with goal clarification
- **Three-Card Sessions** — finite, bounded learning loops (3 cards, then done)
- **Spatial Paths** — graph/tree navigation through connected science topics
- **Article reader** — clean reading experience with remote-only image sourcing
- **Contribute flow** — micro-contribution interactions tied to open questions
- **Community** — semi-moderated spaces for beginner-safe discussion
- **Alerts** — notification layer for session and community events

**Backend:** Supabase (PostgreSQL + RLS) with semantic on-device ranking via Apple's NaturalLanguage framework.

---

## Project structure

```
undrmnd/
├── App/                    # App entry point and configuration
│   └── UndrmndApp.swift   # @main app struct
├── Features/               # Feature modules and views
│   └── ContentView.swift  # Main content view
├── Patterns/               # Reusable patterns (MVVM, Coordinator, etc.)
├── Models/                 # Data models
├── Services/               # Business logic, API, networking
├── Resources/              # Assets, localization, configuration
│   └── Assets.xcassets
└── Info.plist
```

## Tests

```
undrmndTests/
└── UndrmndTests.swift     # Unit tests
```

## Requirements

- Xcode 15.0+
- iOS 17.0+
- Swift 5.0+
- A Supabase project (see `SupabaseService.swift` for config)

## Getting Started

```bash
# 1. Clone the repo
git clone https://github.com/eremmele/undrmnd.git

# 2. Open in Xcode
open undrmnd.xcodeproj

# 3. Set your Supabase URL and anon key in SupabaseService.swift

# 4. Apply the v2 schema to your Supabase project (v2-artifacts/undrmnd_schema_v2.sql)

# 5. Seed content (optional — v2-artifacts/undrmnd_content_seed_v2.sql)

# 6. Build and run (⌘R)
```

For contributing, build flags, and content proposals, see [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md).

## Design Constraints

- **Photos**: Do not use the device photo library (PhotosUI, UIImagePickerController, PHPicker). Photos must come from remote sources (APIs, URLs) or other non-local sources.

## Engineering constraints

- **No local photo library** — images must come from remote URLs or APIs (no `PhotosUI`, `PHPicker`, or `UIImagePickerController`)
- **On-device semantic ranking** — `SemanticSearchRanker` uses Apple NaturalLanguage; no external ML API calls for ranking

## Architecture

- **App/**: Application bootstrap and root configuration
- **Features/**: Screen-level views and feature-specific logic
- **Patterns/**: Shared architectural patterns and utilities
- **Models/**: Domain and data transfer objects
- **Services/**: External integrations, APIs, and business logic
- **Resources/**: Images, colors, strings, and other assets

---

## v2 Content model

v2 introduces a **graph-based content system**: open-question cards are nodes, connected by directional edges into paths. Cards are gated behind a short open question to encourage reflection before proceeding ("fog of war").

| File | Purpose |
|---|---|
| [`v2-artifacts/undrmnd_schema_v2.sql`](v2-artifacts/undrmnd_schema_v2.sql) | Supabase tables, RPCs, RLS policies |
| [`v2-artifacts/undrmnd_content_seed_v2.sql`](v2-artifacts/undrmnd_content_seed_v2.sql) | 30 seed cards (open-question gated) |
| [`v2-artifacts/undrmnd_content_seed_v2.csv`](v2-artifacts/undrmnd_content_seed_v2.csv) | Same titles (CSV for review) |
| [`v2-artifacts/undrmnd_paths_seed.sql`](v2-artifacts/undrmnd_paths_seed.sql) | Example paths / nodes / edges |
| [`v2-artifacts/undrmnd_path_models.swift`](v2-artifacts/undrmnd_path_models.swift) | Original monolithic Swift reference |
| [`docs/CONTENT_RUBRIC.md`](docs/CONTENT_RUBRIC.md) | Editorial standards for card content |

> Apply SQL migrations manually in Supabase — the app does not run migrations at runtime.

---

| Location | Purpose |
|----------|---------|
| [`v2-artifacts/undrmnd_schema_v2.sql`](v2-artifacts/undrmnd_schema_v2.sql) | Supabase migrations (tables, RPCs, RLS) |
| [`v2-artifacts/undrmnd_content_seed_v2.sql`](v2-artifacts/undrmnd_content_seed_v2.sql) | 30 seed cards (open-question gated) |
| [`v2-artifacts/undrmnd_content_seed_v2.csv`](v2-artifacts/undrmnd_content_seed_v2.csv) | Same titles (CSV export for review) |
| [`v2-artifacts/undrmnd_paths_seed.sql`](v2-artifacts/undrmnd_paths_seed.sql) | Example paths / nodes / edges |
| [`v2-artifacts/undrmnd_path_models.swift`](v2-artifacts/undrmnd_path_models.swift) | Original monolithic Swift reference (split under `undrmnd/Models/v2/`) |
| [`docs/v2-artifacts/`](docs/v2-artifacts/) | Copy of the above for docs browsing on GitHub |

**Canonical editorial rubric:** [`docs/CONTENT_RUBRIC.md`](docs/CONTENT_RUBRIC.md) (mirrors [`v2-artifacts/undrmnd_content_rubric_v2.md`](v2-artifacts/undrmnd_content_rubric_v2.md)).

## License

MIT — see [LICENSE](LICENSE).

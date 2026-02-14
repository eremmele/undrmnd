# undrmnd

**Mindful citizen science iOS app with anti-doomscroll patterns**

Connects student researchers to authentic STEM exploration through intentional, session-based engagement.

---

## 🎯 Project Vision

undrmnd reimagines social-scientific apps for students and amateur researchers by:
- **Replacing endless feeds** with intentional, time-boxed exploration sessions
- **Prioritizing deep engagement** over algorithmic engagement metrics
- **Making STEM accessible** through community-driven research and discovery
- **Protecting attention** through friction, reflection, and mindful UX patterns

---

## 🧠 Core Anti-Doomscroll UX Patterns

### 1. **Session Capsule**
Users open into a session chooser rather than a feed. Each session has:
- Clear time or content limits (e.g., "15 min exploration," "Review 5 projects")
- Progress indicators and gentle friction at boundaries
- Post-session reflection prompts to build metacognition

**iOS Implementation:**
- `UISheetPresentation` for session cards
- Local notifications for session end
- Widgets showing remaining attention budget

---

### 2. **Intent-First Launcher**
App starts with an intent board:
- "Explore projects" / "Check messages" / "Contribute data" / "Learn"
- Each intent scopes the experience to avoid distraction
- Defaults to exit or low-stimulus summary after task completion

**iOS Implementation:**
- Segmented controls for intents
- Deep links for Shortcuts/Focus integration
- Focus Filters to hide specific intents during work/study modes

---

### 3. **Load-More Gate (Infinite-Scroll Brake)**
Replace true infinite scroll with:
- Chunked content (N items per load)
- Progressive friction: "You've seen 30 items—continue or wrap up?"
- Micro-prompts at gates: "Save something?" "Reflect on what you learned?"

**iOS Implementation:**
- `UICollectionView` with manual batch loading
- Custom footer for "Load more" / "I'm done" buttons
- Haptic feedback at gates

---

### 4. **Reflective Interrupts**
Timed overlays that prompt awareness:
- "How are you feeling?" / "Is this helping?"
- Links to alternative activities (journaling, stretching, breathing)
- Lightweight logs showing patterns over time

**iOS Implementation:**
- Semi-modal overlays (`.overCurrentContext`)
- HealthKit/Screen Time integration for insights
- Home Screen widgets with mood/scroll summaries

---

### 5. **Algorithm Tuner & Contract**
User-governed discovery:
- "Why this?" explanations on recommended content
- Quick "More/Less like this" and topic sliders
- Hard filters (e.g., "No crisis content after 9pm," "Max 10% politics")

**iOS Implementation:**
- Context menus for "More/Less" on feed cells
- Settings with sliders, toggles, schedule pickers
- Inline banners reflecting active constraints

---

### 6. **End-of-Feed Horizon**
Explicit "You're caught up" states when healthy dose is consumed:
- Replace further feed with saved items, long-form reads, or offline tasks
- Clean exits: "Close app," "Set next check-in time"
- Distinct horizon UI with calming visuals

**iOS Implementation:**
- Separate view controller for horizon state
- Notification scheduler for next check-in
- App Shortcuts for non-feed entry points

---

### 7. **Focal Mode (Grayscale + Quiet)**
Low-dopamine visual theme:
- Grayscale or muted palettes scheduled for evenings/focus blocks
- Notifications batched into digests
- Minimal animations

**iOS Implementation:**
- Alternate `UIAppearance` triggered by time or Focus status
- Notification Summary integration
- Respect system accessibility preferences

---

### 8. **Intentional Discovery Deck**
Topic-based exploration as swipeable cards:
- Small sets per deck (e.g., "5 biology research ideas")
- Built-in caps with completion states
- Externalization prompts: write notes, share insights, schedule revisit

**iOS Implementation:**
- `UIPageViewController` for card stacks
- Core Data / CloudKit for deck progress
- Share sheets & Reminders integration

---

## 🔬 Citizen Science Features

### Research Areas
- **Ecology & Environment:** Species observation, pollution tracking, phenology studies
- **Astronomy:** Light pollution mapping, meteor counts, satellite spotting
- **Health & Behavior:** Sleep patterns, mood tracking, nutrition experiments
- **Physics & Engineering:** DIY sensor data, sound/vibration analysis
- **Social Science:** Community surveys, language documentation

### Contribution Types
- **Data Collection:** Upload observations, photos, sensor readings
- **Data Validation:** Review/verify submissions from other users
- **Analysis Assistance:** Classify images, tag patterns, identify anomalies
- **Protocol Design:** Propose new research questions and methods

### Learning Integration
- **Skill Trees:** Progress through research methods, statistics, data literacy
- **Micro-Lessons:** Short explainers on scientific concepts and tools
- **Mentorship:** Connect with advanced students and professional researchers

---

## 🛠 Tech Stack

- **Platform:** iOS 17+ (SwiftUI + UIKit hybrid)
- **Backend:** Firebase / Supabase (TBD)
- **Data Storage:** Core Data + CloudKit for sync
- **Analytics:** Privacy-preserving on-device metrics only
- **Dependencies:** Swift Package Manager

---

## 📂 Project Structure

```
undrmnd/
├── App/
│   ├── undrmndApp.swift          # App entry point
│   ├── ContentView.swift          # Root view
│   └── Environment/               # Dependency injection, settings
├── Features/
│   ├── Session/                   # Session Capsule pattern
│   ├── Discovery/                 # Intent-first launcher, discovery decks
│   ├── Research/                  # Project browsing, contribution flows
│   ├── Profile/                   # User progress, reflections, settings
│   └── Shared/                    # Reusable components
├── Patterns/
│   ├── LoadMoreGate.swift         # Infinite-scroll brake
│   ├── ReflectiveInterrupt.swift  # Awareness prompts
│   ├── FocalMode.swift            # Grayscale theme + quiet notifications
│   └── AlgorithmTuner.swift       # User-controlled recommendations
├── Models/                        # Data models (Core Data, Codable)
├── Services/                      # Networking, auth, analytics
├── Resources/                     # Assets, localization
└── Tests/
```

---

## 🚀 Getting Started with Cursor

### Prerequisites
- **Xcode 15.2+** with iOS 17 SDK
- **Cursor IDE** ([cursor.sh](https://cursor.sh))
- **Git** for version control

### Setup Steps

1. **Clone the repo:**
   ```bash
   git clone https://github.com/eremmele/undrmnd.git
   cd undrmnd
   ```

2. **Open in Cursor:**
   ```bash
   cursor .
   ```

3. **Install dependencies:**
   - Open `undrmnd.xcodeproj` in Xcode
   - Resolve Swift Package Manager dependencies (if any)

4. **Configure Cursor AI:**
   - See `.cursorrules` in the repo root for project-specific AI context
   - Includes: SwiftUI best practices, anti-pattern guidance, accessibility requirements

5. **Build & Run:**
   - Select a simulator or device in Xcode
   - Press `Cmd+R` to build and run

---

## 📐 Development Principles

### Anti-Doomscroll by Design
- **No dark patterns:** No hidden scroll triggers, no fake urgency, no intermittent rewards
- **Friction is a feature:** Small pauses and reflection points are intentional
- **Defaults protect users:** Quiet modes, caps, and safe content filters enabled by default

### Accessibility First
- VoiceOver support for all interactive elements
- Dynamic Type for text scaling
- High-contrast modes compatible with Focal Mode
- Haptic feedback for non-visual cues

### Privacy Preserving
- All analytics on-device only (no tracking SDKs)
- User data encrypted at rest and in transit
- Minimal data collection (email + username only)
- Explicit consent for any sharing or research use

### Open Science
- All research protocols open and citable
- Data contributed by users is CC-BY licensed
- Algorithm transparency: users see and control recommendation logic

---

## 🤝 Contributing

This is currently a student research project. Contributions welcome after initial prototype phase!

**Planned contribution areas:**
- New UX anti-patterns for testing
- Citizen science protocol ideas
- Accessibility improvements
- Localization (i18n)

---

## 📜 License

MIT License - see [LICENSE](LICENSE) for details.

Open-source, permissive. Build on this, remix it, learn from it.

---

## 🙏 Acknowledgments

**Inspiration:**
- [Mindful Scroll](https://www.mindfulscroll.org/) - slow, embodied interactions
- [Zooniverse](https://www.zooniverse.org/) - citizen science at scale
- [One Sec](https://one-sec.app/) - intentional app opening
- [BeReal](https://bere.al/) - anti-algorithmic social
- Time Well Spent / Center for Humane Technology

**Research:**
- Ledger & Fischer (2024) on counter-algorithmic design
- Lyngs et al. (2019) on digital self-control tools
- Dourish (2022) on slow computing

---

## 📧 Contact

**Maintainer:** Erica Remmele (GitHub: [@eremmele](https://github.com/eremmele))  
**Project:** School research project, NYU (TBD affiliation)

---

**Status:** 🚧 Early prototype phase - expect breaking changes!

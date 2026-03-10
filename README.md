# Undrmnd

A SwiftUI iOS app with a modular architecture, designed to lower the barriers to scientific inquiry and make curiosity-driven exploration feel as welcoming as social media.

## Design North Star

- **Lower barriers to inquiry**: Lower the psychological and cultural barriers to scientific inquiry so anyone, at any age, can ask questions, explore interests, and contribute without credentials or fear of backlash.
- **Delight without addiction**: Feel as delightful and welcoming as social media, with polished mobile UX and Comet-style onboarding, but use finite sessions, clear stopping points, and calm visuals instead of addictive feeds.
- **From doomscrolling to contribution**: Replace passive doomscrolling with micro-interactions that foster curiosity, reflection, and tiny but real contributions to shared projects and citizen science efforts.
- **Beginner-friendly communities**: Create safe, semi-moderated community spaces where “beginner” questions and diverse lived experiences are treated as assets, not liabilities.
- **Open-source infrastructure**: Ship and maintain everything as open-source infrastructure that communities can fork and adapt, proving that ethical, counter-algorithmic learning platforms can exist outside extractive business models.

## Project Structure

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

## Getting Started

1. Open `undrmnd.xcodeproj` in Xcode
2. Select a simulator or device
3. Build and run (⌘R)

## Design Constraints

- **Photos**: Do not use the device photo library (PhotosUI, UIImagePickerController, PHPicker). Photos must come from remote sources (APIs, URLs) or other non-local sources.

## Architecture

- **App/**: Application bootstrap and root configuration
- **Features/**: Screen-level views and feature-specific logic
- **Patterns/**: Shared architectural patterns and utilities
- **Models/**: Domain and data transfer objects
- **Services/**: External integrations, APIs, and business logic
- **Resources/**: Images, colors, strings, and other assets

# Using VS Code with undrmnd

Use **VS Code** for day-to-day editing; use **Xcode** when you need to add Swift packages, run on simulator/device, or manage signing.

## Recommended extension

- **Swift** (`sswg.swift-lang`) – Swift language support and formatting.

## Workflow

1. **Edit in VS Code** – Open the `undrmnd` folder in VS Code. Edit Swift, config, and docs here.
2. **Build and run** – Use Xcode:
   - Open `undrmnd.xcodeproj` in Xcode.
   - Select a simulator or device, then ⌘R.
   - Or from terminal: `xcodebuild -scheme undrmnd -destination 'platform=iOS Simulator,name=iPhone 16' build`.
3. **Adding Swift packages** – Do this in Xcode: File → Add Package Dependencies. The project already includes `supabase-swift`.

## Supabase anon key

Set your Supabase anon key via environment variable so it is never committed:

- In **Xcode**: Edit Scheme → Run → Arguments → Environment Variables → add `SUPABASE_ANON_KEY` = your key.
- Or create a gitignored `undrmnd/SupabaseSecrets.xcconfig` and source it (advanced).

The app uses `https://ajxvmmdlqiijziveqaps.supabase.co`; the key is read from `SUPABASE_ANON_KEY` or a placeholder at runtime.

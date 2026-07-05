# Keyboo

Keyboo is a native macOS menu bar app that plays mechanical keyboard sound effects when you type anywhere on the system.

Built with Swift, SwiftUI, AppKit, AVFoundation, and CGEventTap.

## Features

- Menu bar UI with Control / Configure / App sections, Sound volume submenu, and grouped Switches picker (Keychron, Durock, NovelKeys)
- Floating typing speed HUD (WPM/KPM) with configurable position; Settings window (`⌘,`) for Launch at Login and permissions
- Global keyDown listening via CGEventTap (keyCode only — never captures typed text)
- Low-latency AVFoundation playback with random samples and 3D spatial audio (keyboard-position mapped)
- Spatial rendering adapts to your output device (HRTF on headphones, virtual surround on built-in speakers)
- Four sound profiles: Default, Thock, Clicky, Typewriter

## Running in Xcode

1. Open `Keyboo.xcodeproj`
2. Select the **Keyboo** scheme and **My Mac** as the destination
3. Press **Run** (Cmd+R)
4. The Keyboo keyboard icon appears in the menu bar — no Dock window

## Input Monitoring Permission

Keyboo needs **Input Monitoring** to detect key presses globally.

1. Run the app once from Xcode
2. When prompted, click **Open System Settings** and enable **Keyboo**
3. If no prompt appears: **System Settings → Privacy & Security → Input Monitoring → enable Keyboo**
4. Return to the app and toggle **Enable Keyboo**, or restart the app

The app only reads virtual key codes to choose sounds. It never records, stores, or transmits what you type.

## Adding Sound Files

Add short `.wav` files to each profile folder using this naming convention:

```
Keyboo/Resources/Sounds/default/default_key_01.wav
Keyboo/Resources/Sounds/default/default_key_02.wav
Keyboo/Resources/Sounds/default/default_space_01.wav
Keyboo/Resources/Sounds/default/default_enter_01.wav
Keyboo/Resources/Sounds/default/default_backspace_01.wav
Keyboo/Resources/Sounds/default/default_modifier_01.wav
```

Use the profile name as a prefix (`thock_key_01.wav`, `clicky_key_01.wav`, etc.) so multiple profiles can coexist when Xcode flattens bundled resources.

The loader also checks `Sounds/{profile}/key_01.wav` paths if folder structure is preserved.

Rebuild in Xcode. Sounds are preloaded at launch and when you switch profiles. Use **mono** `.wav` files — spatial audio requires mono sources.

## Project Structure

```
Keyboo/
  KeybooApp.swift            App entry, MenuBarExtra
  MenuBarView.swift          Sectioned menu bar UI
  SwitchSwatchView.swift     Switch color swatch icons
  SettingsView.swift         Settings window (⌘,)
  KeyboardEventMonitor.swift CGEventTap listener
  SoundEngine.swift          AVAudioEngine spatial playback
  SoundProfile.swift         Profile and asset paths
  KeyCodeMapper.swift        Key code → category, 3D position, and speed counting
  TypingVisualizer.swift     Floating speed HUD panel controller
  TypingVisualizerView.swift WPM/KPM overlay UI
  PermissionManager.swift    Input Monitoring permission
  AppSettings.swift          UserDefaults state
  Resources/Sounds/          Sound assets per profile
```

## Releasing

Cut a release with the one-command script:

```bash
# explicit version
Scripts/release.sh 1.1.0

# or bump the current version
Scripts/release.sh --bump patch      # major | minor | patch
```

It bumps the version in the project, runs `Scripts/production-checklist.sh`, builds
and packages a versioned `.dmg`, inserts a `CHANGELOG.md` section, then commits and
creates an annotated `v<version>` git tag.

For a signed & notarized build suitable for public distribution, export your
Developer ID and notary credentials first:

```bash
export CODE_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export NOTARY_PROFILE="meecanico"   # created via: xcrun notarytool store-credentials

Scripts/release.sh 1.1.0 --release  # also pushes the tag and publishes a GitHub release (needs gh)
```

Run `Scripts/release.sh --help` for all flags (`--push`, `--no-git`, `--allow-dirty`, `-y`, …).

## Privacy

- Reads **keyCode only** from keyDown events
- No network calls
- No analytics
- No logging of key presses

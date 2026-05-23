# App Settings Window PRD

Date: 2026-05-23  
Product: Keyboo  
Status: Draft  
Owner: Keyboo

## Summary

The App Settings window is Keyboo’s dedicated configuration surface, opened with **⌘,** or **Settings…** from the menu bar. Today it is a small, single-page form with placeholder Launch at Login, permission status, and privacy copy. Most real controls — switch profile, visualizer, enable/disable — live only in the menu bar.

This PRD defines a redesigned settings window that matches the reference design: a tabbed layout (**General**, **Sound**, **Visualizer**), card-style grouped sections, an app header with version, and consolidated controls that mirror menu bar behavior without replacing quick menu access.

The first release should feel native, trustworthy, and complete enough that users rarely need to hunt through the menu for basic setup.

## Problem

Keyboo’s settings window under-delivers compared to the rest of the app:

- It looks like a stub (disabled toggles, no branding, no tabs).
- Important controls are split between a minimal settings form and the menu bar, so users cannot discover volume, visualizer, or switch options in one place.
- Permission and install-location guidance is scattered between onboarding, settings, and dev-only notes.
- README and product docs mention volume and launch-at-login, but neither is wired up in settings.

Users expect a macOS utility’s settings window to be the canonical place for app identity, permissions, sound preferences, and optional HUD behavior.

## Goals

- Provide a polished, tabbed settings window that matches the reference UI (General / Sound / Visualizer).
- Consolidate configuration that already exists in code into logical tabs without removing menu bar shortcuts.
- Surface permission status clearly with visual status indicators and actionable recovery when denied.
- Explain install location and why `/Applications` is recommended for predictable Input Monitoring setup.
- Implement real **output volume** control backed by `SoundEngine`.
- Wire **Launch at Login** to `SMAppService` (or document deferral if blocked by entitlements).
- Keep all settings local, offline, and privacy-respecting.

## Non-Goals

- Replacing the menu bar as the primary quick-control surface.
- Custom sound pack import or profile marketplace.
- Per-app sound profiles or quiet-hours scheduling.
- Advanced audio (EQ, per-category volume, key-up sounds).
- Notch overlay or dock icon settings.
- Analytics, accounts, or cloud sync.
- Full About panel with licenses, update checker, or feedback form (future).
- Renaming the product from Keyboo to another brand unless explicitly decided separately.

## Target Users

- A new user finishing permission onboarding who wants to confirm Keyboo is set up correctly.
- A user who prefers **⌘,** and a settings window over digging through menu submenus.
- A developer or beta tester running from Xcode who needs install-location context (“Debug” vs “Applications”).
- A user adjusting volume or visualizer position without re-opening the menu bar each time.

## User Stories

- As a user, I want to open settings with **⌘,** and see which tab I need without reading a long form.
- As a user, I want to see the app name, icon, and version so I know I opened the right utility.
- As a user, I want to turn on Launch at Login from settings.
- As a user, I want to see whether Input Monitoring is granted at a glance and fix it if not.
- As a user, I want to know where Keyboo is installed and why Applications is recommended.
- As a user, I want to adjust keyboard sound volume in settings.
- As a user, I want to pick a switch profile in settings with the same options as the menu bar.
- As a user, I want to enable the typing HUD and choose its screen position from settings.
- As a user, I want my choices to persist across relaunches.

## Reference Design

The target UI (reference screenshot) includes:

- Dark, grouped **card sections** on a scrollable body.
- Top **segmented control**: General | Sound | Visualizer.
- **General tab**
  - App header card: icon, “Keyboo”, version string (e.g. `Version 1.1.0`).
  - General card: Launch at Login toggle; Input Monitoring row with colored status dot + label (“Granted” / “Required”).
  - Install Location card: “Current Folder” value (e.g. “Applications”, “Debug”); helper text explaining Applications is more predictable for Input Monitoring.
- **Sound** and **Visualizer** tabs: not fully shown in reference but implied by navigation; content defined below.

Window should feel like a modern macOS settings panel: ~480pt wide, scrollable height, native controls.

---

## MVP Requirements

### Shell & Navigation

- Settings must use a **tabbed layout** with three tabs: **General**, **Sound**, **Visualizer**.
- Tab selection may be persisted in session only (default: General); persisting last tab is optional.
- Content must be **scrollable** when it exceeds window height.
- Default window size: approximately **480 × 520** pt (minimum height may shrink on smaller displays).
- Settings remain opened via SwiftUI `Settings { SettingsView() }` scene (**⌘,**).
- Menu bar **Settings…** link continues to open the same window.

### Shared UI Components

- **Settings card**: rounded rectangle grouping related rows; section title above the card (e.g. “Install Location”).
- **Status row**: leading label, trailing status text, optional **colored dot** (green = granted, orange = required/denied).
- **App header row**: app icon (from asset catalog), bold app name, secondary version line from bundle metadata.

### General Tab

#### App Header

- Display app icon from `Assets.xcassets`.
- Display product name **Keyboo**.
- Display version: `Version {CFBundleShortVersionString}` (build number optional, not required for MVP).

#### Launch at Login

- Toggle bound to `AppSettings.launchAtLogin`.
- On toggle ON: register with `SMAppService.mainApp`.
- On toggle OFF: unregister.
- On appear: sync toggle with actual login-item registration state (avoid UI drift).
- If registration fails: revert toggle, show non-blocking inline error or alert with reason.
- Requires appropriate entitlement (`com.apple.security.application-groups` not needed; uses `SMAppService`).

#### Input Monitoring

- Show label **Input Monitoring** with status:
  - **Granted** + green dot when `PermissionManager.hasInputMonitoringAccess`.
  - **Required** + orange dot when not granted.
- Refresh status on appear and when the settings window becomes key / app becomes active.
- When not granted, show:
  - **Open System Settings** button (existing `PermissionManager.openInputMonitoringSettings()`).
  - **Request Permission** button (existing `requestAccess()`).
  - `PermissionXcodeDevNote` in Debug builds when relevant.
- Do not gate settings navigation on permission; only gate actions that require monitoring (see Visualizer).

#### Install Location

- New **Install Location** section with:
  - Row: **Current Folder** → human-readable location label.
  - Helper text (fixed copy): *“Keeping Keyboo in Applications makes Input Monitoring setup more predictable.”*
- Location detection rules:

| Condition | Display label |
|-----------|---------------|
| Bundle path under `/Applications/` | `Applications` |
| Xcode DerivedData or `.build` debug path | `Debug` |
| Other known dev paths (optional) | `Development` |
| Else | Last path component or `Other` |

- **Move to Applications** button: **out of scope for MVP** (future enhancement); read-only display only.

#### Privacy

- Retain existing privacy copy on General tab (below Install Location or in its own card):
  - *“Keyboo only reads virtual key codes to play sounds. It never captures, stores, or transmits typed text.”*
- Caption/secondary style; multi-line, fixed size vertically.

### Sound Tab

#### Output Volume

- Slider: **0% – 100%** (or continuous 0.0–1.0), default **100%**.
- New persisted key: `AppSettings.outputVolume` (`Double`, default `1.0`).
- Changes apply immediately to `SoundEngine` (environment output volume or equivalent).
- Volume affects:
  - Live typing sounds when monitoring is active.
  - Profile preview playback from settings and menu bar.
- Display current value as percentage or use native slider label.

#### Switch Profile

- Reuse brand-grouped profile list from menu bar (`SoundProfileID.profilesGroupedByBrand`).
- Each row: swatch icon + switch name; native selection indicator for active profile.
- Selecting a profile:
  - Updates `AppSettings.selectedProfile`.
  - Reloads `SoundEngine`.
  - Plays short preview (`SoundEngine.playPreview()`).
- Preview and selection work **without** Input Monitoring permission.
- Invalid stored profile falls back to default (existing behavior).

#### Enable Sounds (optional row)

- **Non-goal for MVP** if menu bar remains the primary enable toggle.
- If included: mirror **Enable Keyboo** toggle, disabled when permission missing.

### Visualizer Tab

#### Show While Typing

- Toggle bound to `AppSettings.enableVisualizer`.
- Disabled when Input Monitoring is not granted (same rule as menu bar).

#### Position

- Segmented control or picker: **Left**, **Center**, **Right** (`MenuBarPosition`).
- Bound to `AppSettings.menuBarPosition`.
- Disabled when visualizer is off or permission is missing.

#### Preview (optional)

- Static or simplified preview of HUD capsule with accent color from `selectedProfile.swatchColor`.
- **Nice-to-have for MVP**; not blocking if time-constrained.

---

## State & Data Flow

### Existing settings (unchanged keys)

| Setting | Key / property | Default |
|---------|----------------|---------|
| Enabled | `isEnabled` | `true` |
| Profile | `selectedProfile` | `default` |
| Launch at login | `launchAtLogin` | `false` |
| Visualizer | `enableVisualizer` | `false` |
| HUD position | `menuBarPosition` | `center` |

### New settings

| Setting | Key | Default |
|---------|-----|---------|
| Output volume | `keyboo.outputVolume` | `1.0` |

### Service sync (`KeybooApp`)

- On `outputVolume` change → `SoundEngine.setOutputVolume(_:)`.
- On `enableVisualizer` / `menuBarPosition` / `isEnabled` / permission change → existing `syncVisualizer()` (unchanged).
- On `selectedProfile` change → existing reload + preview (unchanged).
- On `launchAtLogin` change → `SMAppService` register/unregister.

### New types / files (implementation hint)

- `InstallLocation.swift` — bundle path → display label.
- `SettingsView.swift` — refactor into tab shell + subviews.
- Optional: `SettingsCard`, `SettingsStatusRow` small view helpers in same file or `SettingsComponents.swift`.

---

## UX Flow

### Open settings

1. User presses **⌘,** or chooses **Settings…** from the menu bar.
2. Settings window opens on **General** tab with app header and permission status visible.

### Fix permission

1. User sees **Required** on Input Monitoring.
2. User taps **Open System Settings**, grants permission, returns to Keyboo.
3. Status updates to **Granted** (green dot) via existing polling / foreground observers.

### Adjust sound

1. User switches to **Sound** tab.
2. User drags volume slider; typing and previews reflect new level immediately.
3. User selects a switch profile; preview plays; choice persists.

### Configure visualizer

1. User switches to **Visualizer** tab.
2. User enables **Show While Typing**.
3. User picks **Left** / **Center** / **Right**; floating HUD moves accordingly.

---

## Visual Design

- **Dark-mode-first** appearance consistent with reference; respect system light/dark automatically.
- **Card sections**: subtle elevated background, corner radius ~10–12 pt, internal padding consistent with macOS grouped settings patterns.
- **Segmented tab bar** centered at top of window content (General | Sound | Visualizer).
- **Typography**: system font; section headers semibold; helper text `.secondary` caption size.
- **Status dots**: 8 pt circle, green (`#34C759` or system green) / orange (system orange).
- **No custom chrome** beyond cards; use standard toggles, sliders, buttons.
- App icon size in header: ~48–64 pt.

---

## Edge Cases

| Scenario | Expected behavior |
|----------|-------------------|
| Input Monitoring denied | General shows Required + actions; Sound volume/profile still work; Visualizer toggle/position disabled |
| Launch at Login registration fails | Toggle reverts; user sees error message |
| Stored volume missing or invalid | Default to 100% |
| Sound files missing for profile | Selection still works; preview skipped silently |
| App running from Xcode Debug | Install Location shows **Debug** |
| App in `/Applications/Keyboo.app` | Install Location shows **Applications** |
| User changes settings while typing | Volume/profile/visualizer apply on next sync without crash |
| Settings open while onboarding window open | Both can coexist; no modal blocking |

---

## Success Criteria

- A user can complete first-time setup (permission check, launch at login, volume, profile) entirely from the settings window.
- Permission status is understandable within 2 seconds (dot + label).
- Volume change is audible within one slider interaction.
- Selected profile and visualizer settings match menu bar state at all times (single source of truth: `AppSettings`).
- Install location correctly reflects Debug vs Applications in QA builds.

---

## Acceptance Criteria

### Shell

- [ ] Settings window shows three tabs: General, Sound, Visualizer.
- [ ] Window is scrollable and approximately 480 pt wide.
- [ ] App header shows icon, “Keyboo”, and bundle version string.

### General

- [ ] Launch at Login toggle registers/unregisters login item via `SMAppService`.
- [ ] Toggle state matches system registration on appear.
- [ ] Input Monitoring shows Granted/Required with colored dot.
- [ ] Denied state shows Open System Settings and Request Permission.
- [ ] Install Location shows correct label for Applications vs Debug builds.
- [ ] Privacy copy is visible on General tab.

### Sound

- [ ] Volume slider persists `outputVolume` and updates `SoundEngine` immediately.
- [ ] Volume affects typing sounds and profile preview.
- [ ] Switch profile picker lists all bundled profiles grouped by brand with swatches.
- [ ] Selecting a profile updates settings, reloads engine, and plays preview.

### Visualizer

- [ ] Show While Typing toggle persists and syncs HUD via existing `syncVisualizer()`.
- [ ] Position control persists and updates HUD position.
- [ ] Controls disabled when permission missing or visualizer off (position only when off).

### Integration

- [ ] **⌘,** opens settings; menu **Settings…** opens same window.
- [ ] Changes in settings reflect in menu bar state without duplicate persistence.
- [ ] No network calls; no new analytics.

---

## Testing

### Manual

- Open settings from menu and **⌘,**.
- Toggle each tab; verify layout in light and dark mode.
- Deny/grant Input Monitoring; verify dot, buttons, and visualizer disabled states.
- Run from Xcode → Install Location **Debug**; install to Applications → **Applications**.
- Adjust volume; type and preview profile; relaunch and confirm volume persists.
- Enable Launch at Login; log out/in or restart; confirm Keyboo launches (QA environment permitting).
- Change visualizer position with HUD enabled; confirm panel moves.

### Build

- Xcode build Keyboo scheme succeeds.
- No new warnings in `SettingsView` / `SoundEngine` public API.

---

## Future Enhancements

- **Move to Applications** assistant button with `NSWorkspace` copy + reveal.
- About tab: credits, open-source licenses, website link.
- Keyboard shortcuts reference inside settings.
- HUD live preview on Visualizer tab.
- Enable Keyboo master toggle on General or Sound tab.
- Per-category volume (modifier quieter).
- Quiet hours schedule.
- Export/import settings file.
- Sparkle / in-app update channel settings.

---

## Dependencies & Risks

| Item | Notes |
|------|-------|
| `SMAppService` | Requires macOS 13+; test on target OS 26.x; may need Developer ID for distribution |
| Volume API | Must not regress spatial audio or polyphony in `SoundEngine` |
| Login item UX | User may need to approve in System Settings → Login Items on first register |
| Menu bar parity | Menu redesign PRD may add volume to menu; settings and menu must share `AppSettings.outputVolume` |

---

## Related Documents

- [Switch Profile Picker PRD](./switch-profile-picker-prd.md)
- [Menu Bar Redesign Design](../superpowers/specs/2026-05-23-menu-bar-redesign-design.md)
- [KEYBOO_CONTEXT.md](../../KEYBOO_CONTEXT.md)

---

## Implementation Phases (Suggested)

1. **Phase 1 — Shell**: TabView, cards, header, scroll, General layout (permission dot, install location read-only, privacy); Launch at Login still disabled if needed.
2. **Phase 2 — Visualizer tab**: Wire existing toggles/pickers.
3. **Phase 3 — Sound tab**: Volume persistence + `SoundEngine` API; profile picker + preview.
4. **Phase 4 — Launch at Login**: `SMAppService` wiring and error handling.
5. **Phase 5 — Polish**: Light mode pass, optional HUD preview, QA on Applications vs Debug paths.

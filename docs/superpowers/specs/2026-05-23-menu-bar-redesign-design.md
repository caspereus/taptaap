# Keyboo Menu Bar Redesign

## Goal

Redesign Keyboo's menu bar extra so it feels closer to the provided reference: a compact dark macOS-style control menu with clear sections, quick enable/disable state, sound controls, configuration entries, and app actions.

The first implementation should stay inside SwiftUI `MenuBarExtra` with `.menu` style. This keeps native macOS keyboard behavior, submenu behavior, shortcuts, and accessibility while improving the structure and labels.

## Current Context

Keyboo is a native macOS menu bar app. The current menu lives in `Keyboo/MenuBarView.swift` and is wired through `Keyboo/KeybooApp.swift`.

Current menu behavior:

- Permission warning appears when Input Monitoring is missing.
- `Enable Keyboo` toggles `AppSettings.isEnabled`.
- `Switch` opens a brand-grouped picker using switch swatch icons.
- `Visualizer` opens a submenu with show/hide and position picker.
- `Settings...` and `Quit Keyboo` are app actions.

Known relevant gap to close in this redesign:

- `README.md` and `KEYBOO_CONTEXT.md` mention volume control, but no persisted volume setting or `SoundEngine` volume API exists yet.

## Chosen Approach

Use a native menu redesign rather than a fully custom popover.

Reasons:

- It is the lowest-risk path for a menu bar utility.
- It preserves native menu keyboard navigation, checkmarks, submenu arrows, and shortcuts.
- It matches the screenshot's structure without forcing custom drawing into a surface that should behave like a macOS menu.

Rejected alternatives:

- Fully custom popover: more control over rounded card visuals and sliders, but higher complexity and more custom accessibility work.
- Minimal label-only rearrangement: fast, but it would not deliver the reference-like control menu or current switch clarity.

## Menu Structure

The redesigned menu should use these sections:

### Control

- Primary enabled row: `Enable Keyboo` or `Disable Keyboo`, depending on `settings.isEnabled`.
- The row should keep native toggle/checkmark behavior where possible.
- If Input Monitoring permission is missing, the enable row remains disabled and a permission action appears above it.

### Volume

- Add a top-level volume row below the enable row, matching the reference menu's quick-access sound control.
- Back the control with real playback volume, not a decorative slider.
- Persist the value so Keyboo keeps the same volume after relaunch.

### Configure

- Do not add a separate `Sound` submenu in the first pass, because the only real sound control is the top-level volume row and the switch picker.
- `Switches`: opens the existing brand-grouped picker.
- `Disable Visualizer` or `Enable Visualizer`, depending on `settings.enableVisualizer`.
- `Disable Notch Overlay` should not be added yet because Keyboo does not currently have a notch overlay feature.
- `Position`: opens the existing left, center, right picker and is disabled when the visualizer is off or permission is missing.

### App

- `Settings...` uses the existing `SettingsLink`.
- `Quit Keyboo` keeps the `Command-Q` shortcut.

## Selected Switch Behavior

Use native checkmarks inside the switch submenu, and make the parent row show the selected switch more clearly.

Expected behavior:

- The `Switches` row should show the current switch swatch and current switch name in the parent label, for example `Switches: Holy Panda`.
- The submenu keeps the existing brand grouping.
- The selected profile remains represented by the native picker checkmark inside the submenu.

This avoids a heavy checklist look in the top-level menu while keeping standard macOS selection feedback where users expect it.

## State And Data Flow

Existing settings remain the source of truth:

- `AppSettings.isEnabled`
- `AppSettings.selectedProfile`
- `AppSettings.enableVisualizer`
- `AppSettings.menuBarPosition`
- `PermissionManager.hasInputMonitoringAccess`

Add volume state:

- Add `AppSettings.outputVolume` with a default value of `1.0`.
- Add a small public API on `SoundEngine` to apply volume to playback, preferably by setting the audio environment output volume.
- Sync volume changes from `KeybooApp` or directly from menu bindings, following the existing settings-to-service pattern.

## Error Handling And Disabled States

- Permission-dependent rows should remain disabled when Input Monitoring is not granted.
- The menu should still offer a clear action to open Input Monitoring settings when permission is missing.
- Visualizer position should be disabled when visualizer is off.
- The volume control should never appear as functional unless it actually changes playback volume.

## Visual Rules

- Prefer native menu typography, spacing, dividers, checkmarks, and submenu arrows.
- Use SF Symbols where SwiftUI menu labels support them cleanly.
- Keep labels short: `Sound`, `Switches`, `Position`, `Settings...`, `Quit Keyboo`.
- Avoid adding visible explanatory text inside the menu.
- Preserve switch swatch icons because they are already part of Keyboo's product identity.

## Testing

Manual verification:

- Open the app from Xcode and confirm the menu structure matches the planned sections.
- Toggle Keyboo enabled state and confirm sound monitoring starts and stops.
- Change switch profile and confirm preview sound still plays.
- Toggle visualizer and position settings.
- Remove or deny Input Monitoring and confirm permission disabled states remain clear.

Build verification:

- Run an Xcode build for the Keyboo scheme.
- If available, run any existing unit or UI tests.

## Scope Boundaries

In scope:

- Menu organization and labels.
- Selected switch presentation.
- Real volume support for keyboard playback and preview playback.
- README update if the menu behavior changes.

Out of scope:

- Custom popover rendering.
- Notch overlay feature.
- Launch-at-login implementation.
- New sound profile assets.
- Changes to keyboard capture or privacy model.

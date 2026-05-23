# Switch Profile Picker PRD

Date: 2026-05-23
Product: Keyboo
Status: Draft
Owner: Keyboo

## Summary

The Switch Profile Picker lets users choose what their keyboard sounds like. It should make Keyboo feel immediately useful: users can open the menu bar app, browse available switch profiles, hear a quick preview, and select the sound they want without opening a full settings window.

For the first MVP, the picker should stay simple, local, and reliable. It should use the bundled switch profiles only, persist the selected profile, and make the current choice obvious.

## Problem

Keyboo ships multiple mechanical keyboard sound profiles, but users need a fast way to understand and switch between them. Profile names alone are not enough because the difference between switches is mostly auditory. Without preview, users must select a profile, type somewhere, judge the sound, then reopen the menu and try another profile.

That loop is too slow for the main product moment.

## Goals

- Help users quickly discover the available switch sounds.
- Let users change the active sound profile from the menu bar.
- Make the selected profile clear at a glance.
- Play a short preview when the user selects or previews a profile.
- Persist the selected profile across app launches.
- Keep the experience private and offline.

## Non-Goals

- Custom sound pack import.
- Downloadable profile marketplace.
- Per-app sound profiles.
- Cloud sync.
- Accounts or analytics.
- Advanced EQ, per-category volume, or sound editing.

## Target Users

- A MacBook user who wants their built-in keyboard to sound more fun.
- A mechanical keyboard fan who wants to switch between different sound styles.
- A casual user trying Keyboo from a free release who needs the app to make sense immediately.

## User Stories

- As a user, I want to see all available switch profiles grouped clearly so I can browse them quickly.
- As a user, I want to know which switch profile is currently active.
- As a user, I want to hear a preview before committing to a profile.
- As a user, I want my selected profile to stay selected after restarting Keyboo.
- As a user, I want the picker to work without internet access.

## MVP Requirements

### Profile List

- The picker must live in the menu bar UI.
- Profiles must be grouped by switch brand or category.
- Each profile row must show:
  - A small visual swatch.
  - A human-readable switch name.
  - Native selected state from the menu picker.
- The picker must include all bundled profiles:
  - K2 Max / Gateron Red
  - K2 Max / Gateron Brown
  - MX Blue
  - MX Speed Silver
  - Box Jade
  - Alpaca
  - Banana Split / Lubed
  - Cream
  - Topre Purple Hybrid / PBT
  - Lavender Purple
  - Oreo

### Selection Behavior

- Selecting a profile must immediately update the active sound profile.
- The selected profile must be stored in user defaults.
- The selected profile must be restored on app launch.
- If the stored profile is invalid, Keyboo must fall back to the default profile.

### Preview Behavior

- When a user selects a profile, Keyboo should play a short preview sound.
- The preview should use the selected profile's normal key sample.
- Preview must respect the app's master volume once volume control exists.
- Preview must not require Input Monitoring permission because it is triggered by the app UI, not global typing.
- If a preview sound cannot be loaded, profile selection should still work.

### Visual Design

- The picker should use native macOS menu behavior.
- The menu should feel compact and fast, not like a large settings panel.
- Switch swatches should provide quick visual identity, but the sound remains the primary decision point.
- Labels should be short enough to fit cleanly inside a menu item.

### Privacy

- The picker must not collect typed text.
- The picker must not send profile choice or usage data anywhere.
- All profile data and sound assets must be bundled locally.

## UX Flow

1. User clicks the Keyboo menu bar icon.
2. User opens the Switch menu.
3. User browses brand-grouped switch profiles.
4. User selects a profile.
5. Keyboo immediately:
   - Updates the active profile.
   - Persists the choice.
   - Plays a quick preview sound.
6. User continues typing anywhere on macOS with the new profile active.

## Edge Cases

- Input Monitoring is not granted:
  - The user can still choose and preview profiles.
  - Global typing sounds remain disabled until permission is granted.
- Sound file missing:
  - Do not crash.
  - Keep the selected profile.
  - Skip preview if needed.
- Audio engine fails to start:
  - Do not block profile selection.
  - Fail silently in release builds.
- User changes profile while typing:
  - New key presses should use the new profile after reload completes.

## Success Criteria

- A new user can find and select a switch profile within 10 seconds.
- A user can understand the sound difference without leaving the menu bar flow.
- The selected profile persists after quitting and reopening Keyboo.
- The picker works fully offline.
- The app does not crash if profile preview fails.

## Acceptance Criteria

- The Switch menu displays all bundled profiles grouped by brand.
- The selected profile shows native menu selection state.
- Selecting a profile updates `AppSettings.selectedProfile`.
- Selecting a profile reloads `SoundEngine` with the chosen profile.
- Selecting a profile plays one short preview sound from that profile.
- Profile selection works even when Input Monitoring permission is missing.
- The selected profile persists across app restarts.

## Future Enhancements

- Dedicated preview button per profile.
- Hover-to-preview, if feasible with native menu limitations.
- Favorite profiles.
- Recently used profiles.
- Custom sound pack import.
- Per-app profile rules.
- Profile search if the list grows beyond bundled MVP profiles.


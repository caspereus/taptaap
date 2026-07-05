# Changelog

All notable changes to Meecanico are documented here.

## [1.0.0] - 2026-07-04

First public release of **Meecanico** (formerly Keyboo).

### Added

- Global mechanical keyboard sounds via CGEventTap (keyCode only, privacy-first)
- 19 switch sound profiles across 11 brands with profile preview on selection
- 3D spatial audio with optional HRTF positioning toggle in Settings
- Menu bar controls for enable, volume, switches, and visualizer
- Tabbed Settings window (General, Sound, Visualizer) with Launch at Login
- Floating WPM/KPM typing visualizer with themes and position controls
- Input Monitoring onboarding and install-to-Applications guidance
- Global hotkeys: toggle Meecanico and cycle sound profiles
- Drag-to-Applications install flow for DMG distribution

### Distribution

- Release build and versioned DMG via `Scripts/create-dmg.sh`
- Production verification via `Scripts/production-checklist.sh`

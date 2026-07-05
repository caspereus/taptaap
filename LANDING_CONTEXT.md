# Meecanico — Landing Page Context Brief

> Paste this into another AI chat to design, write copy, or build the marketing website.
> Intended for a **separate repo** from the macOS app. Keep in sync with the app repo when features or branding change.

---

## One-liner

**Meecanico** is a native **macOS menu bar app** that makes any keyboard sound like a mechanical one — thocky, clicky, or linear — whenever you type **anywhere on the system**.

---

## Brand & naming

| Item | Value |
|------|--------|
| **Public product name** | Meecanico |
| **Former name** | Keyboo (internal repo / bundle ID still use this) |
| **Bundle ID** | `com.Keyboo` |
| **Copyright** | Copyright © 2026 Meecanico |
| **Current version** | 1.0.0 |
| **Platform** | macOS only (menu bar app, no Dock icon) |
| **Suggested domain** | `meecanico.app` or `getmeecanico.com` (pick one; update placeholders below) |

**Tone:** Craft-obsessed but approachable — mechanical keyboard culture without gatekeeping. Confident on privacy. Native Mac utility, not a toy web app.

**Voice:** Short sentences. Concrete benefits. Never vague “AI-powered” fluff. Privacy claims must be precise (key codes, not keystrokes).

---

## What to sell (user-facing features)

| Feature | Marketing angle |
|---------|-----------------|
| Global typing sounds | Works in every app — Mail, Slack, Xcode, Safari |
| 19 switch sound profiles | Real switch names across 11 brands (Cherry, Kailh, Topre, …) |
| Profile preview | Hear a sample before you commit in the menu |
| 3D spatial audio | Each key has position on a virtual keyboard; HRTF on headphones |
| Menu bar control | Always one click away; no Dock clutter |
| Typing visualizer | Optional floating WPM/KPM HUD with themes and position |
| Global hotkeys | Toggle Meecanico; cycle sound profiles |
| Privacy-first | Key codes only — never typed text, never network |
| DMG install | Drag to Applications; familiar Mac download flow |

**Do not over-promise on the site:**

- Requires **Input Monitoring** permission (not Accessibility alone)
- **US QWERTY** assumed for spatial key mapping
- **Menu bar only** — no Dock icon (`LSUIElement`)
- No Mac App Store listing yet — direct download
- No iOS / Windows version

---

## Switch profiles (for feature grid / carousel copy)

19 profiles, grouped by brand:

| Brand | Profiles |
|-------|----------|
| Keychron | Default (Gateron Red), Thock (Gateron Brown) |
| Cherry | MX Blue, MX Black, MX Brown, MX Red, Speed Silver |
| Kailh | Box Jade, Box White |
| Durock | Clicky (Alpaca) |
| C³Equalz | Holy Panda, Banana Split (stock) |
| NovelKeys | Typewriter (Cream) |
| Topre | Topre Purple Hybrid |
| Akko | Lavender Purple |
| Everglide | Oreo, Crystal Purple |
| Razer | Razer Green |
| SteelSeries | Apex Pro |

Use swatch colors and switch names from the app for visual consistency. Do **not** imply official partnerships with these brands unless you add disclaimers (“inspired by…”).

---

## Privacy (primary differentiator — lead with this)

**Headline territory:** “Hears keys, not words.” / “Mechanical sounds. Zero keystroke logging.”

**Approved copy (from app, safe to reuse):**

> Meecanico only reads virtual key codes to play sounds. It never captures, stores, or transmits typed text.

> Meecanico reads key codes system-wide to play mechanical keyboard sounds. It never captures or records what you type.

**Bullets for a Privacy section:**

- Listens to **virtual key codes** from key-down events only
- **Never** reads characters, clipboard, or passwords
- **No network** requests from the app
- **No analytics** or telemetry
- **No cloud** — settings stay in local UserDefaults
- Requires **Input Monitoring** — explain honestly why (global key detection for sounds)

**FAQ answer — “Is this a keylogger?”**

> No. Meecanico uses the same low-level API category as accessibility tools, but it only reads numeric key codes to pick a sound file. It never reconstructs what you typed, never saves events, and never sends data off your Mac.

---

## Competitive positioning

Similar space: Mechvibes, Clickey, Klack, etc.

**Meecanico angles:**

1. **Native macOS** — Swift, menu bar, AVFoundation, not Electron
2. **Spatial 3D audio** — keys feel placed on a keyboard, not flat stereo
3. **Switch-collector branding** — 19 named profiles, brand-grouped picker
4. **Privacy-first** — no network; keyCode-only architecture
5. **Typing HUD** — optional WPM/KPM visualizer for streamers / enthusiasts

---

## Suggested site structure

```
/                     Home (hero + primary CTA)
/#features            Feature sections (anchor on home)
/#switches            Profile showcase
/#privacy             Privacy promise (or dedicated /privacy page)
/download             Redirect or direct DMG link
/changelog            Version history (mirror app CHANGELOG)
/privacy              Privacy policy (legal)
/terms                Terms of use (if selling later)
```

### Home page sections (top → bottom)

1. **Hero**
   - Headline + subhead + “Download for macOS” CTA
   - Hero visual: menu bar mockup, or short looped demo video/GIF
   - Secondary line: “Free · macOS 14+ · No account required” (adjust minimum OS to match app target)

2. **Social proof / one-liner strip** (optional at launch)
   - “Built for Mac typists who miss their thock at the café”

3. **How it works** (3 steps)
   - Download & drag to Applications
   - Grant Input Monitoring
   - Pick a switch profile and type

4. **Features grid** (4–6 cards)
   - 19 switch profiles
   - 3D spatial audio
   - Menu bar control
   - Typing visualizer
   - Global hotkeys
   - Privacy by design

5. **Switch showcase**
   - Carousel or grid with brand, switch name, short descriptor (Thock / Clicky / Linear vibe)
   - Optional: embedded audio samples (host short MP3/WAV clips — not the full app bundle)

6. **Privacy block**
   - Lock icon, approved copy, link to full policy

7. **FAQ**
   - Permission requirements
   - “Does it work with my keyboard?” (yes — any keyboard)
   - “Does it slow my Mac?” (low-latency local audio)
   - “App Store?” (direct download for now)
   - “What data do you collect?” (none)

8. **Footer**
   - Download · Changelog · Privacy · Terms · GitHub (if open) · Contact email

---

## Hero copy drafts

**Option A (benefit-first)**

- **Headline:** Your Mac keyboard, finally mechanical.
- **Subhead:** Meecanico plays low-latency switch sounds everywhere you type — with 19 profiles, 3D spatial audio, and zero keystroke logging.

**Option B (privacy-first)**

- **Headline:** Thocky typing. Zero surveillance.
- **Subhead:** A native macOS menu bar app that turns key codes into mechanical sounds — never your words.

**Option C (enthusiast)**

- **Headline:** 19 switches. One menu bar icon.
- **Subhead:** From Holy Panda to MX Blue — pick a profile, enable Input Monitoring, and type anywhere on your Mac.

**Primary CTA:** `Download for macOS`  
**Secondary CTA:** `See how it works` (scroll) or `Watch demo`

---

## Elevator pitch (reuse anywhere)

> Meecanico is a privacy-respecting macOS menu bar utility that makes any keyboard sound like a mechanical one. It listens globally for key codes (never typed text), plays low-latency 3D-spatial switch sounds from 19 themed profiles, and optionally shows a floating WPM/KPM HUD. Built in Swift with CGEventTap and AVAudioEngine. No network. Menu bar only. Requires Input Monitoring permission.

---

## Visual & brand direction

**Feel:** Native macOS — dark UI, glass/material surfaces, restrained accent color. Not gamer RGB. Not generic SaaS purple gradient.

**Reference from app:**

- Glass cards (`GlassEffect`, ~10pt corner radius)
- Switch **swatch colors** per profile (use for accents and showcase cards)
- Menu bar keyboard icon (light/dark variants in app assets)
- App icon at `Keyboo/Assets.xcassets/AppIcon.appiconset/1024.png`

**Site typography (suggestions):**

- Display: SF Pro / system stack, or **Inter** for web parity with Apple-like feel
- Monospace accent for WPM/HUD demos: SF Mono / JetBrains Mono

**Imagery needs (create for launch):**

- [ ] Hero: MacBook with menu bar + optional visualizer HUD
- [ ] Menu bar dropdown screenshot
- [ ] Settings window screenshot (permission + privacy copy visible)
- [ ] Switch picker with swatches
- [ ] 15–30s screen recording (typing in Notes with sound — note: autoplay muted on web)
- [ ] OG image 1200×630 (`Meecanico — mechanical keyboard sounds for Mac`)
- [ ] Favicon from app icon

**Assets to copy from app repo (don't submodule the whole app):**

```
Keyboo/Assets.xcassets/AppIcon.appiconset/1024.png
Keyboo/Assets.xcassets/MenuBarIcon.imageset/*
```

---

## Download & release flow

**Build artifact:** `Meecanico-{version}.dmg` via `Scripts/create-dmg.sh` in the app repo.

**Recommended hosting:**

1. **GitHub Releases** on the app repo — stable URL pattern for each version
2. Landing site CTA links to **latest release** URL (update on each ship, or use a redirect)

**Post-download journey (match app UX):**

1. Open DMG → drag **Meecanico** to Applications
2. Launch from Applications (not DMG — site should mention this)
3. Complete Input Monitoring onboarding
4. Pick a switch profile

**System requirements copy (draft):**

> macOS 14 or later · Apple Silicon or Intel · Input Monitoring permission required

(Verify against Xcode deployment target before publishing.)

---

## Recommended tech stack (website repo)

| Layer | Recommendation | Why |
|-------|----------------|-----|
| Framework | **Astro** or **Next.js** (static export) | Fast, simple deploy, great SEO |
| Styling | **Tailwind CSS** | Speed; easy dark theme |
| Hosting | **Vercel**, **Netlify**, or **Cloudflare Pages** | Free tier, custom domain |
| Analytics | **Plausible** or **none** at launch | Aligns with privacy brand; avoid Google Analytics unless necessary |
| Fonts | Self-host or system fonts | Performance + privacy |

**Repo layout (starter):**

```
meecanico-website/
  LANDING_CONTEXT.md      ← this file
  README.md
  public/
    og.png
    favicon.ico
    samples/              ← optional short audio previews
  src/
    pages/
      index.astro
      privacy.astro
      changelog.astro
    components/
      Hero.astro
      FeatureGrid.astro
      SwitchShowcase.astro
      PrivacyBlock.astro
      FAQ.astro
      DownloadButton.astro
    data/
      switches.json       ← 19 profiles metadata
      faq.json
  astro.config.mjs
  package.json
```

**Do not** embed the macOS app, WAV libraries, or Xcode project in the website repo.

---

## SEO & metadata

**Title:** Meecanico — Mechanical Keyboard Sounds for Mac

**Meta description (≤160 chars):**

> Native macOS menu bar app. 19 switch profiles, 3D spatial audio, optional WPM HUD. Key codes only — never your typed text. Free download.

**Keywords (natural use only):** mechanical keyboard sounds mac, typing sound app macOS, thocky keyboard sound, menu bar utility, WPM visualizer mac

**Open Graph:** og:title, og:description, og:image, og:url

**Structured data:** `SoftwareApplication` schema with `operatingSystem: macOS`, `applicationCategory: UtilitiesApplication`, `offers.price: 0` if free.

---

## Legal pages (minimum for direct download)

**Privacy policy must state:**

- Website may use minimal analytics (if any) — separate from the app
- App collects no personal data
- Contact email for requests
- No sale of data

**Terms (lightweight for free utility):**

- Software provided as-is
- Not affiliated with Cherry, Razer, etc.
- User responsible for granting system permissions

---

## Links to maintain

| Link | Placeholder |
|------|-------------|
| App source repo | `https://github.com/YOUR_ORG/Keyboo` |
| Latest DMG | `https://github.com/YOUR_ORG/Keyboo/releases/latest` |
| Support email | `hello@meecanico.app` |
| Changelog | `/changelog` or link to app `CHANGELOG.md` |

---

## Monetization (future — don't block v1)

Possible later paths (pick one when ready; v1 can be **free + direct download**):

- Free core + paid switch packs
- One-time purchase
- “Typewriter” or premium profiles
- Affiliate links to switch vendors (disclose clearly)

Landing v1 should not imply pricing unless decided.

---

## Launch checklist

- [ ] Domain + HTTPS
- [ ] Download button works (test DMG on clean Mac)
- [ ] Privacy policy live before sharing widely
- [ ] OG image previews correctly in iMessage / Slack / Twitter
- [ ] Mobile-readable (many users will open link on phone, then switch to Mac)
- [ ] `CHANGELOG` synced for 1.0.0
- [ ] Permission FAQ accurate (Input Monitoring, not Accessibility)
- [ ] Notarization / Gatekeeper note if users see “unidentified developer” (link to right-click → Open)

---

## Brainstorm prompts

### Copy & design

- Should the hero lead with **sound** or **privacy**?
- How do we demo sound on a website without annoying autoplay?
- Switch grid vs. interactive “try a profile” audio picker?

### Growth

- Product Hunt / Hacker News launch page variants
- Short demo for Mastodon / X (visualizer WPM as social hook)
- Keyboard subreddit messaging (r/MechanicalKeyboards, r/macapps)

### Technical

- `/download` redirect vs. hardcoded GitHub release URL
- Automate changelog from app repo on release
- Hosted audio samples vs. silent GIF only

---

## Short system prompt (for AI chats)

```
You are building the marketing website for Meecanico, a native macOS menu bar app that plays mechanical keyboard sounds system-wide. Product was formerly called Keyboo. The app uses CGEventTap (keyCode only, never typed text), AVAudioEngine with 3D spatial audio, 19 switch profiles across 11 brands, an optional WPM/KPM visualizer, and global hotkeys. No network, no analytics in the app. Distribution is direct DMG download; requires Input Monitoring permission. Site tone: native Mac craft, keyboard enthusiast-friendly, privacy-forward. Help me with [YOUR TOPIC].
```

---

## Sync with app repo

When the app ships a new version, update on the website:

1. Version number and download URL
2. Changelog entries
3. Feature list if capabilities changed
4. Screenshots if UI changed materially
5. Minimum macOS version if deployment target changes

**Source of truth for product facts:** app repo `CHANGELOG.md`, `Keyboo/Sound/SoundProfile.swift`, `SettingsView.swift`, `PermissionOnboardingView.swift`.

**Companion doc in app repo:** `KEYBOO_CONTEXT.md` (technical / architecture brief for the macOS app).

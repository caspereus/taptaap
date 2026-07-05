#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Meecanico"
DERIVED_DATA="$ROOT/build/DerivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Release/Meecanico.app"
PLIST="$APP_PATH/Contents/Info.plist"

pass=0
fail=0
warn=0

ok()   { echo "  ✓ $1"; pass=$((pass + 1)); }
bad()  { echo "  ✗ $1"; fail=$((fail + 1)); }
note() { echo "  ! $1"; warn=$((warn + 1)); }

echo "Meecanico production checklist"
echo "=============================="
echo

echo "Build"
echo "-----"
cd "$ROOT"
if xcodebuild \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}" \
  > /tmp/meecanico-build.log 2>&1; then
  ok "Release build succeeded"
else
  bad "Release build failed (see /tmp/meecanico-build.log)"
  tail -20 /tmp/meecanico-build.log >&2 || true
  exit 1
fi

echo
echo "Versioning"
echo "----------"
marketing=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST")
build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST")
pbx_marketing=$(grep -m1 'MARKETING_VERSION = ' "$ROOT/Keyboo.xcodeproj/project.pbxproj" | sed 's/.*= //;s/;//')
pbx_build=$(grep -m1 'CURRENT_PROJECT_VERSION = ' "$ROOT/Keyboo.xcodeproj/project.pbxproj" | sed 's/.*= //;s/;//')

echo "  Version: $marketing ($build)"
if [[ "$marketing" == "$pbx_marketing" && "$build" == "$pbx_build" ]]; then
  ok "Bundle version matches project.pbxproj ($pbx_marketing / $pbx_build)"
else
  bad "Version mismatch: bundle=$marketing/$build, pbx=$pbx_marketing/$pbx_build"
fi

echo
echo "Bundle metadata"
echo "---------------"
display_name=$(/usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" "$PLIST")
bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$PLIST")
lsui=$(/usr/libexec/PlistBuddy -c "Print :LSUIElement" "$PLIST")

[[ "$display_name" == "Meecanico" ]] && ok "Display name is Meecanico" || bad "Display name is '$display_name', expected Meecanico"
[[ "$bundle_id" == "com.Keyboo" ]] && ok "Bundle ID is com.Keyboo" || note "Bundle ID is '$bundle_id'"
[[ "$lsui" == "true" ]] && ok "LSUIElement enabled (menu bar only)" || bad "LSUIElement is not true"

if /usr/libexec/PlistBuddy -c "Print :NSListenEventUsageDescription" "$PLIST" > /dev/null 2>&1; then
  ok "NSListenEventUsageDescription present"
else
  bad "Missing NSListenEventUsageDescription"
fi

echo
echo "Sound assets"
echo "------------"
profiles=(
  default thock mxBlue mxBlack mxBrown mxRed speedSilver boxJade boxWhite
  clicky holyPanda bananaStock typewriter topre lavender oreo crystalPurple
  razerGreen apexPro
)
missing_profiles=0
for profile in "${profiles[@]}"; do
  count=$(find "$ROOT/Keyboo/Resources/Sounds/$profile" -name "*.wav" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$count" -lt 6 ]]; then
    bad "Profile '$profile' has $count/6 source WAV files"
    missing_profiles=$((missing_profiles + 1))
  fi
done
if [[ "$missing_profiles" -eq 0 ]]; then
  ok "All ${#profiles[@]} profiles have 6 source WAV files"
fi

bundled_wav=$(find "$APP_PATH/Contents/Resources" -name "*.wav" | wc -l | tr -d ' ')
expected_wav=$((${#profiles[@]} * 6))
if [[ "$bundled_wav" -eq "$expected_wav" ]]; then
  ok "$bundled_wav WAV files bundled in Release app"
else
  bad "Expected $expected_wav bundled WAV files, found $bundled_wav"
fi

for profile in "${profiles[@]}"; do
  if ! find "$APP_PATH/Contents/Resources" -name "${profile}_key_01.wav" | grep -q .; then
    bad "Missing bundled sample for profile '$profile'"
  fi
done

echo
echo "Distribution"
echo "------------"
if [[ -x "$ROOT/Scripts/create-dmg.sh" ]]; then
  ok "create-dmg.sh is executable"
else
  bad "Scripts/create-dmg.sh is missing or not executable"
fi

if [[ -f "$ROOT/Scripts/dmg/installation-background.png" ]]; then
  ok "DMG installation background is present"
else
  bad "Scripts/dmg/installation-background.png is missing"
fi

if [[ -n "${CODE_SIGN_IDENTITY:-}" && "$CODE_SIGN_IDENTITY" != "-" ]]; then
  ok "Developer ID signing configured ($CODE_SIGN_IDENTITY)"
else
  note "Using ad-hoc signing — set CODE_SIGN_IDENTITY for notarized distribution"
fi

echo
echo "Summary"
echo "-------"
echo "  Passed:   $pass"
echo "  Failed:   $fail"
echo "  Warnings: $warn"
echo

if [[ "$fail" -gt 0 ]]; then
  echo "Production checklist FAILED."
  exit 1
fi

echo "Production checklist passed (version $marketing, build $build)."
if [[ "$warn" -gt 0 ]]; then
  echo "Review warnings before shipping outside local testing."
fi

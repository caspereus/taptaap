#!/usr/bin/env bash
#
# release.sh — one-command release for Meecanico.
#
# Orchestrates a full, repeatable release:
#   1. Preflight    — clean working tree, expected branch, tooling present
#   2. Version      — bump MARKETING_VERSION + CURRENT_PROJECT_VERSION in the project
#   3. Verify       — run the production checklist (Release build + asset/metadata checks)
#   4. Package      — build and package a versioned .dmg (Scripts/create-dmg.sh)
#   5. Notarize     — (optional) Developer ID sign + notarize + staple the .dmg
#   6. Changelog    — insert a dated section for the new version
#   7. Tag          — commit the version bump and create an annotated git tag
#   8. Publish      — (optional) push the tag and create a GitHub release with the .dmg
#
# Usage:
#   Scripts/release.sh <version>            e.g. Scripts/release.sh 1.1.0
#   Scripts/release.sh --bump <part>        part = major | minor | patch
#
# Common flags:
#   --bump <part>        Derive the next version from the current one (major|minor|patch)
#   --notarize           Force notarization (otherwise auto when signing + creds exist)
#   --no-checklist       Skip the production checklist
#   --no-git             Skip the version-bump commit and git tag
#   --push               Push the commit and tag to origin
#   --release            Create a GitHub release with the .dmg asset (requires gh, implies --push)
#   --allow-dirty        Skip the clean-working-tree check
#   --yes, -y            Do not prompt for confirmation
#   --help, -h           Show this help
#
# Code signing / notarization (set these in the environment to sign & notarize):
#   CODE_SIGN_IDENTITY   e.g. "Developer ID Application: Your Name (TEAMID)"
#   NOTARY_PROFILE       A notarytool keychain profile created with:
#                          xcrun notarytool store-credentials <profile> \
#                            --apple-id <id> --team-id <TEAMID> --password <app-specific-pw>
#   — or —
#   NOTARY_APPLE_ID, NOTARY_TEAM_ID, NOTARY_PASSWORD
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Meecanico"
APP_NAME="Meecanico"
PBXPROJ="$ROOT/Keyboo.xcodeproj/project.pbxproj"
CHANGELOG="$ROOT/CHANGELOG.md"
EXPECTED_BRANCH="main"

# ── options ──────────────────────────────────────────────────────────────────
VERSION=""
BUMP_PART=""
FORCE_NOTARIZE=0
RUN_CHECKLIST=1
RUN_GIT=1
DO_PUSH=0
DO_RELEASE=0
ALLOW_DIRTY=0
ASSUME_YES=0

# ── helpers ──────────────────────────────────────────────────────────────────
info() { printf '\033[1;34m==>\033[0m %s\n' "$1"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m  !\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$1" >&2; exit 1; }

usage() { sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

confirm() {
  [[ "$ASSUME_YES" -eq 1 ]] && return 0
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ── parse args ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --bump)         BUMP_PART="${2:-}"; shift 2 ;;
    --notarize)     FORCE_NOTARIZE=1; shift ;;
    --no-checklist) RUN_CHECKLIST=0; shift ;;
    --no-git)       RUN_GIT=0; shift ;;
    --push)         DO_PUSH=1; shift ;;
    --release)      DO_RELEASE=1; DO_PUSH=1; shift ;;
    --allow-dirty)  ALLOW_DIRTY=1; shift ;;
    --yes|-y)       ASSUME_YES=1; shift ;;
    --help|-h)      usage 0 ;;
    -*)             die "unknown flag: $1 (use --help)" ;;
    *)              VERSION="$1"; shift ;;
  esac
done

cd "$ROOT"

# ── resolve the target version ───────────────────────────────────────────────
current_marketing() {
  grep -m1 'MARKETING_VERSION = ' "$PBXPROJ" | sed 's/.*= //;s/;//'
}
current_build() {
  grep 'CURRENT_PROJECT_VERSION = ' "$PBXPROJ" \
    | sed 's/.*= //;s/;//' | sort -n | tail -1
}

CURRENT_VERSION="$(current_marketing)"

if [[ -n "$BUMP_PART" && -n "$VERSION" ]]; then
  die "pass either an explicit version or --bump, not both"
fi

if [[ -n "$BUMP_PART" ]]; then
  IFS='.' read -r major minor patch <<< "$CURRENT_VERSION"
  case "$BUMP_PART" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
    *)     die "--bump expects major, minor, or patch" ;;
  esac
  VERSION="${major}.${minor}.${patch}"
fi

[[ -n "$VERSION" ]] || { warn "no version given"; usage 1; }
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must look like X.Y.Z (got '$VERSION')"

NEW_BUILD=$(( $(current_build) + 1 ))
TAG="v${VERSION}"

info "Releasing ${APP_NAME} ${VERSION} (build ${NEW_BUILD})  —  was ${CURRENT_VERSION}"

# ── preflight ────────────────────────────────────────────────────────────────
info "Preflight"

command -v xcodebuild >/dev/null 2>&1 || die "xcodebuild not found"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
[[ "$BRANCH" == "$EXPECTED_BRANCH" ]] && ok "on branch $BRANCH" \
  || warn "on branch '$BRANCH' (expected '$EXPECTED_BRANCH')"

if [[ "$ALLOW_DIRTY" -eq 0 ]]; then
  git diff-index --quiet HEAD -- 2>/dev/null \
    && ok "working tree is clean" \
    || die "working tree has uncommitted changes (commit/stash them, or pass --allow-dirty)"
else
  warn "skipping clean-working-tree check (--allow-dirty)"
fi

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
  die "tag ${TAG} already exists"
fi
ok "tag ${TAG} is available"

# Decide whether we will notarize.
SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-}"
DO_NOTARIZE=0
if [[ "$FORCE_NOTARIZE" -eq 1 || ( -n "$SIGN_IDENTITY" && "$SIGN_IDENTITY" != "-" ) ]]; then
  [[ -n "$SIGN_IDENTITY" && "$SIGN_IDENTITY" != "-" ]] \
    || die "notarization requires CODE_SIGN_IDENTITY to be a Developer ID identity"
  if [[ -z "${NOTARY_PROFILE:-}" ]] \
     && [[ -z "${NOTARY_APPLE_ID:-}" || -z "${NOTARY_TEAM_ID:-}" || -z "${NOTARY_PASSWORD:-}" ]]; then
    die "notarization needs NOTARY_PROFILE or NOTARY_APPLE_ID + NOTARY_TEAM_ID + NOTARY_PASSWORD"
  fi
  DO_NOTARIZE=1
  ok "will sign & notarize with: $SIGN_IDENTITY"
else
  warn "ad-hoc signing (set CODE_SIGN_IDENTITY to produce a notarized, distributable build)"
fi

if [[ "$DO_RELEASE" -eq 1 ]]; then
  command -v gh >/dev/null 2>&1 || die "--release needs the GitHub CLI (gh); install it or drop --release"
  ok "gh available for GitHub release"
fi

echo
confirm "Proceed with release ${VERSION}?" || { warn "aborted"; exit 1; }

# ── 1. bump version in the project ───────────────────────────────────────────
info "Bumping version to ${VERSION} (${NEW_BUILD})"
/usr/bin/sed -i '' -E "s/MARKETING_VERSION = [^;]+;/MARKETING_VERSION = ${VERSION};/g" "$PBXPROJ"
/usr/bin/sed -i '' -E "s/CURRENT_PROJECT_VERSION = [^;]+;/CURRENT_PROJECT_VERSION = ${NEW_BUILD};/g" "$PBXPROJ"
ok "project.pbxproj updated"

# ── 2. production checklist (also builds Release) ────────────────────────────
if [[ "$RUN_CHECKLIST" -eq 1 ]]; then
  info "Running production checklist"
  CODE_SIGN_IDENTITY="${SIGN_IDENTITY:--}" bash "$ROOT/Scripts/production-checklist.sh"
else
  warn "skipping production checklist (--no-checklist)"
fi

# ── 3. build + package DMG ───────────────────────────────────────────────────
info "Building and packaging DMG"
CODE_SIGN_IDENTITY="${SIGN_IDENTITY:--}" bash "$ROOT/Scripts/create-dmg.sh"
DMG_PATH="$ROOT/build/${APP_NAME}-${VERSION}.dmg"
[[ -f "$DMG_PATH" ]] || die "expected DMG not found: $DMG_PATH"
ok "packaged $(basename "$DMG_PATH")"

# ── 4. notarize + staple ─────────────────────────────────────────────────────
if [[ "$DO_NOTARIZE" -eq 1 ]]; then
  info "Signing DMG"
  codesign --force --sign "$SIGN_IDENTITY" --timestamp "$DMG_PATH"

  info "Submitting to Apple notary service (this can take a few minutes)"
  notary_args=(--wait)
  if [[ -n "${NOTARY_PROFILE:-}" ]]; then
    notary_args+=(--keychain-profile "$NOTARY_PROFILE")
  else
    notary_args+=(--apple-id "$NOTARY_APPLE_ID" --team-id "$NOTARY_TEAM_ID" --password "$NOTARY_PASSWORD")
  fi
  xcrun notarytool submit "$DMG_PATH" "${notary_args[@]}"

  info "Stapling notarization ticket"
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
  ok "DMG notarized and stapled"
fi

# ── 5. changelog ─────────────────────────────────────────────────────────────
info "Updating CHANGELOG"
if grep -q "## \[${VERSION}\]" "$CHANGELOG" 2>/dev/null; then
  ok "CHANGELOG already has a ${VERSION} section"
else
  DATE="$(date +%Y-%m-%d)"
  TMP="$(mktemp)"
  awk -v ver="$VERSION" -v date="$DATE" '
    !done && /^## \[/ {
      print "## [" ver "] - " date "\n\n### Changed\n\n- _TODO: summarize changes for this release_\n"
      done = 1
    }
    { print }
    END {
      if (!done) print "\n## [" ver "] - " date "\n\n### Changed\n\n- _TODO: summarize changes for this release_\n"
    }
  ' "$CHANGELOG" > "$TMP"
  mv "$TMP" "$CHANGELOG"
  warn "added a ${VERSION} section to CHANGELOG.md — edit the notes before publishing"
fi

# ── 6. commit + tag ──────────────────────────────────────────────────────────
if [[ "$RUN_GIT" -eq 1 ]]; then
  info "Committing version bump and tagging ${TAG}"
  git add "$PBXPROJ" "$CHANGELOG"
  git commit -m "Release ${VERSION} (build ${NEW_BUILD})"
  git tag -a "$TAG" -m "${APP_NAME} ${VERSION}"
  ok "committed and tagged ${TAG}"

  if [[ "$DO_PUSH" -eq 1 ]]; then
    info "Pushing commit and tag to origin"
    git push origin "$BRANCH"
    git push origin "$TAG"
    ok "pushed ${BRANCH} and ${TAG}"
  fi
else
  warn "skipping git commit and tag (--no-git)"
fi

# ── 7. GitHub release ────────────────────────────────────────────────────────
if [[ "$DO_RELEASE" -eq 1 ]]; then
  info "Creating GitHub release ${TAG}"
  NOTES="$(awk -v ver="$VERSION" '
    $0 ~ "^## \\[" ver "\\]" { grab = 1; next }
    grab && /^## \[/ { exit }
    grab { print }
  ' "$CHANGELOG")"
  gh release create "$TAG" "$DMG_PATH" \
    --title "${APP_NAME} ${VERSION}" \
    --notes "${NOTES:-Release ${VERSION}}"
  ok "GitHub release published"
fi

echo
info "Release ${VERSION} complete"
echo "  DMG:  $DMG_PATH"
[[ "$RUN_GIT" -eq 1 ]] && echo "  Tag:  $TAG"
if [[ "$DO_NOTARIZE" -eq 0 ]]; then
  echo "  Note: ad-hoc signed — set CODE_SIGN_IDENTITY + notary creds for public distribution."
fi
if [[ "$RUN_GIT" -eq 1 && "$DO_PUSH" -eq 0 ]]; then
  echo "  Next: git push origin $BRANCH && git push origin $TAG"
fi

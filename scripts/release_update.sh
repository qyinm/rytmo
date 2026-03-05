#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PROJECT_PATH="${APP_REPO_DIR}/rytmo.xcodeproj"
SCHEME="rytmo"
CONFIGURATION="Release"
UPDATE_DIR="${APP_REPO_DIR}/sparkle"
BASE_DOWNLOAD_URL="https://qyinm.github.io/rytmo/sparkle"
DMG_NAME="Rytmo.dmg"
SKIP_DMG=0
SIGN_UPDATE_BIN="${SPARKLE_SIGN_UPDATE_BIN:-}"
LOCAL_SIGN_UPDATE_BIN="${APP_REPO_DIR}/sparkle/tools/sign_update"
LEGACY_FEED_SYNC=0
LEGACY_UPDATE_DIR="${APP_REPO_DIR}/../Rytmo-update"
LEGACY_BASE_DOWNLOAD_URL="https://qyinm.github.io/rytmo-update"
GITHUB_RELEASE=0
GITHUB_DRY_RUN=0
GITHUB_DRAFT=0
GITHUB_PRERELEASE=0
GITHUB_REPO=""
GITHUB_TAG_PREFIX="v"
GITHUB_NOTES_FILE=""
GITHUB_TARGET=""
APPCAST_RETAIN_COUNT=1

print_help() {
  cat <<'EOF'
Usage: scripts/release_update.sh [options]

Automates release packaging for Rytmo:
1) xcodebuild archive (Release)
2) export .app from archive
3) zip update payload into sparkle/
4) sign zip and update Sparkle appcast.xml
5) create DMG in sparkle/

Options:
  --update-dir <path>      Override sparkle output directory
  --base-url <url>         Base URL used in appcast enclosure/release-notes links
  --sign-update-bin <path> Path to Sparkle sign_update binary
  --legacy-feed-sync       Also sync Sparkle artifacts to legacy feed path
  --legacy-update-dir <path>
                           Legacy mirror directory (default: ../Rytmo-update)
  --legacy-base-url <url>  Legacy base URL (default: https://qyinm.github.io/rytmo-update)
  --scheme <name>          Xcode scheme (default: rytmo)
  --project <path>         Xcode project path (default: rytmo.xcodeproj)
  --configuration <name>   Build configuration (default: Release)
  --dmg-name <name>        Output DMG name (default: Rytmo.dmg)
  --skip-dmg               Skip DMG creation
  --github-release         Create or update GitHub release via gh CLI
  --github-dry-run         Print GitHub release commands without executing them
  --github-repo <owner/repo>
                           Override target GitHub repo (default: current repo)
  --github-tag-prefix <prefix>
                           Tag prefix for release tag (default: v)
  --github-target <target> Commit/branch for new tag (default: HEAD)
  --retain-appcast-items <n>
                           Keep newest N items in appcast (default: 1)
  --github-notes-file <path>
                           Markdown/HTML file for GitHub release notes
  --github-draft           Create GitHub release as draft (new releases only)
  --github-prerelease      Create GitHub release as prerelease (new releases only)
  -h, --help               Show this help

Notes:
- Release notes file defaults to release_notes/release_notes_<shortVersion>.html.
- If release notes file does not exist, a placeholder file is created.
- sign_update is resolved in this order: --sign-update-bin, SPARKLE_SIGN_UPDATE_BIN env, ./sparkle/tools/sign_update, PATH(sign_update).
- Legacy feed sync is optional and disabled by default.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --update-dir)
      UPDATE_DIR="$2"
      shift 2
      ;;
    --base-url)
      BASE_DOWNLOAD_URL="$2"
      shift 2
      ;;
    --sign-update-bin)
      SIGN_UPDATE_BIN="$2"
      shift 2
      ;;
    --legacy-feed-sync)
      LEGACY_FEED_SYNC=1
      shift
      ;;
    --legacy-update-dir)
      LEGACY_UPDATE_DIR="$2"
      shift 2
      ;;
    --legacy-base-url)
      LEGACY_BASE_DOWNLOAD_URL="$2"
      shift 2
      ;;
    --scheme)
      SCHEME="$2"
      shift 2
      ;;
    --project)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --configuration)
      CONFIGURATION="$2"
      shift 2
      ;;
    --dmg-name)
      DMG_NAME="$2"
      shift 2
      ;;
    --skip-dmg)
      SKIP_DMG=1
      shift
      ;;
    --github-release)
      GITHUB_RELEASE=1
      shift
      ;;
    --github-dry-run)
      GITHUB_DRY_RUN=1
      shift
      ;;
    --github-repo)
      GITHUB_REPO="$2"
      shift 2
      ;;
    --github-tag-prefix)
      GITHUB_TAG_PREFIX="$2"
      shift 2
      ;;
    --github-target)
      GITHUB_TARGET="$2"
      shift 2
      ;;
    --retain-appcast-items)
      APPCAST_RETAIN_COUNT="$2"
      shift 2
      ;;
    --github-notes-file)
      GITHUB_NOTES_FILE="$2"
      shift 2
      ;;
    --github-draft)
      GITHUB_DRAFT=1
      shift
      ;;
    --github-prerelease)
      GITHUB_PRERELEASE=1
      shift
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      print_help
      exit 1
      ;;
  esac
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_command xcodebuild
require_command ditto
require_command stat
require_command python3
if [[ "$GITHUB_RELEASE" -eq 1 ]]; then
  require_command gh
  require_command git
fi

if [[ -z "$SIGN_UPDATE_BIN" ]]; then
  if [[ -x "$LOCAL_SIGN_UPDATE_BIN" ]]; then
    SIGN_UPDATE_BIN="$LOCAL_SIGN_UPDATE_BIN"
  elif command -v sign_update >/dev/null 2>&1; then
    SIGN_UPDATE_BIN="$(command -v sign_update)"
  fi
fi

if [[ -z "$SIGN_UPDATE_BIN" ]]; then
  cat >&2 <<EOF
Sparkle sign_update binary not found.
Provide it via one of the following:
- --sign-update-bin <path>
- SPARKLE_SIGN_UPDATE_BIN environment variable
- place executable at ${LOCAL_SIGN_UPDATE_BIN}
- install sign_update in PATH
EOF
  exit 1
fi

if [[ ! -x "$SIGN_UPDATE_BIN" ]]; then
  echo "Sparkle sign_update binary is not executable: $SIGN_UPDATE_BIN" >&2
  exit 1
fi

mkdir -p "$UPDATE_DIR"
if [[ "$LEGACY_FEED_SYNC" -eq 1 ]]; then
  mkdir -p "$LEGACY_UPDATE_DIR"
fi

if [[ ! -e "$PROJECT_PATH" ]]; then
  echo "Project not found: $PROJECT_PATH" >&2
  exit 1
fi

if [[ -n "$GITHUB_NOTES_FILE" && ! -f "$GITHUB_NOTES_FILE" ]]; then
  echo "GitHub notes file not found: $GITHUB_NOTES_FILE" >&2
  exit 1
fi

if [[ ! "$APPCAST_RETAIN_COUNT" =~ ^[0-9]+$ ]] || [[ "$APPCAST_RETAIN_COUNT" -lt 1 ]]; then
  echo "--retain-appcast-items must be an integer >= 1" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/rytmo-release-XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

ARCHIVE_PATH="${TMP_DIR}/${SCHEME}.xcarchive"
EXPORT_DIR="${TMP_DIR}/export"

echo "Using sign_update binary: ${SIGN_UPDATE_BIN}"
echo "[1/5] Archiving app..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_PATH" \
  archive

APP_PATHS=("$ARCHIVE_PATH"/Products/Applications/*.app)
if [[ ${#APP_PATHS[@]} -ne 1 || ! -d "${APP_PATHS[0]}" ]]; then
  echo "Unable to detect exported .app in archive at $ARCHIVE_PATH/Products/Applications" >&2
  exit 1
fi

ARCHIVED_APP_PATH="${APP_PATHS[0]}"
APP_NAME="$(basename "$ARCHIVED_APP_PATH")"
EXPORTED_APP_PATH="${EXPORT_DIR}/${APP_NAME}"

echo "[2/5] Exporting .app from archive..."
mkdir -p "$EXPORT_DIR"
ditto "$ARCHIVED_APP_PATH" "$EXPORTED_APP_PATH"

APP_INFO_PLIST="${EXPORTED_APP_PATH}/Contents/Info.plist"
if [[ ! -f "$APP_INFO_PLIST" ]]; then
  echo "Info.plist not found: $APP_INFO_PLIST" >&2
  exit 1
fi

SHORT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_INFO_PLIST")"
BUILD_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$APP_INFO_PLIST")"
MIN_SYSTEM_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$APP_INFO_PLIST" 2>/dev/null || true)"

ARCHIVE_BASE_NAME="${APP_NAME%.app}-${SHORT_VERSION}-${BUILD_VERSION}"
ZIP_NAME="${ARCHIVE_BASE_NAME}.zip"
ZIP_PATH="${UPDATE_DIR}/${ZIP_NAME}"
LEGACY_ZIP_PATH=""
LEGACY_APPCAST_PATH=""
LEGACY_RELEASE_NOTES_FILE=""
LEGACY_DMG_PATH=""

echo "[3/5] Creating update archive: ${ZIP_NAME}"
ditto -c -k --sequesterRsrc --keepParent "$EXPORTED_APP_PATH" "$ZIP_PATH"

ZIP_LENGTH="$(stat -f%z "$ZIP_PATH")"
ED_SIGNATURE="$("$SIGN_UPDATE_BIN" -p "$ZIP_PATH")"

SPARKLE_RELEASE_NOTES_DIR="${UPDATE_DIR}/release_notes"
SPARKLE_RELEASE_NOTES_FILE="${SPARKLE_RELEASE_NOTES_DIR}/release_notes_${SHORT_VERSION}.html"
mkdir -p "$SPARKLE_RELEASE_NOTES_DIR"

if [[ ! -f "$SPARKLE_RELEASE_NOTES_FILE" ]]; then
  TODAY="$(date +%Y-%m-%d)"
  cat > "$SPARKLE_RELEASE_NOTES_FILE" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rytmo ${SHORT_VERSION}</title>
</head>
<body>
  <h1>Rytmo ${SHORT_VERSION}</h1>
  <p>${TODAY}</p>
  <ul>
    <li>Update details go here.</li>
  </ul>
</body>
</html>
EOF
  echo "Created placeholder release notes: $SPARKLE_RELEASE_NOTES_FILE"
fi

APPCAST_PATH="${UPDATE_DIR}/appcast.xml"
APPCAST_ENCLOSURE_URL="${BASE_DOWNLOAD_URL%/}/${ZIP_NAME}"
APPCAST_RELEASE_NOTES_URL="${BASE_DOWNLOAD_URL%/}/release_notes/$(basename "$SPARKLE_RELEASE_NOTES_FILE")"

echo "[4/5] Updating Sparkle appcast.xml..."
python3 "$SCRIPT_DIR/update_appcast.py" \
  --appcast "$APPCAST_PATH" \
  --title "$SHORT_VERSION" \
  --version "$BUILD_VERSION" \
  --short-version "$SHORT_VERSION" \
  --minimum-system-version "$MIN_SYSTEM_VERSION" \
  --release-notes-url "$APPCAST_RELEASE_NOTES_URL" \
  --enclosure-url "$APPCAST_ENCLOSURE_URL" \
  --enclosure-length "$ZIP_LENGTH" \
  --ed-signature "$ED_SIGNATURE" \
  --retain-item-count "$APPCAST_RETAIN_COUNT"

if [[ "$LEGACY_FEED_SYNC" -eq 1 ]]; then
  echo "[4b/5] Syncing legacy Sparkle feed..."

  LEGACY_ZIP_PATH="${LEGACY_UPDATE_DIR}/${ZIP_NAME}"
  if [[ "$LEGACY_ZIP_PATH" != "$ZIP_PATH" ]]; then
    cp "$ZIP_PATH" "$LEGACY_ZIP_PATH"
  fi

  LEGACY_RELEASE_NOTES_DIR="${LEGACY_UPDATE_DIR}/release_notes"
  mkdir -p "$LEGACY_RELEASE_NOTES_DIR"
  LEGACY_RELEASE_NOTES_FILE="${LEGACY_RELEASE_NOTES_DIR}/$(basename "$SPARKLE_RELEASE_NOTES_FILE")"
  if [[ "$LEGACY_RELEASE_NOTES_FILE" != "$SPARKLE_RELEASE_NOTES_FILE" ]]; then
    cp "$SPARKLE_RELEASE_NOTES_FILE" "$LEGACY_RELEASE_NOTES_FILE"
  fi

  LEGACY_ZIP_LENGTH="$(stat -f%z "$LEGACY_ZIP_PATH")"
  LEGACY_APPCAST_PATH="${LEGACY_UPDATE_DIR}/appcast.xml"
  LEGACY_APPCAST_ENCLOSURE_URL="${LEGACY_BASE_DOWNLOAD_URL%/}/${ZIP_NAME}"
  LEGACY_APPCAST_RELEASE_NOTES_URL="${LEGACY_BASE_DOWNLOAD_URL%/}/release_notes/$(basename "$LEGACY_RELEASE_NOTES_FILE")"

  python3 "$SCRIPT_DIR/update_appcast.py" \
    --appcast "$LEGACY_APPCAST_PATH" \
    --title "$SHORT_VERSION" \
    --version "$BUILD_VERSION" \
    --short-version "$SHORT_VERSION" \
    --minimum-system-version "$MIN_SYSTEM_VERSION" \
    --release-notes-url "$LEGACY_APPCAST_RELEASE_NOTES_URL" \
    --enclosure-url "$LEGACY_APPCAST_ENCLOSURE_URL" \
    --enclosure-length "$LEGACY_ZIP_LENGTH" \
    --ed-signature "$ED_SIGNATURE" \
    --retain-item-count "$APPCAST_RETAIN_COUNT"
fi

if [[ "$SKIP_DMG" -eq 0 ]]; then
  echo "[5/5] Creating DMG..."
  INSTALLER_SOURCE_DIR="${UPDATE_DIR}/installer_source"
  mkdir -p "$INSTALLER_SOURCE_DIR"
  rm -rf "${INSTALLER_SOURCE_DIR}/${APP_NAME}"
  ditto "$EXPORTED_APP_PATH" "${INSTALLER_SOURCE_DIR}/${APP_NAME}"

  DMG_PATH="${UPDATE_DIR}/${DMG_NAME}"
  rm -f "$DMG_PATH"

  if command -v create-dmg >/dev/null 2>&1; then
    (
      cd "$UPDATE_DIR"
      if [[ -f "./dmg-background.png" ]]; then
        create-dmg \
          --volname "Rytmo Installer" \
          --window-pos 200 120 \
          --window-size 600 400 \
          --background "./dmg-background.png" \
          --icon-size 100 \
          --icon "$APP_NAME" 170 195 \
          --hide-extension "$APP_NAME" \
          --app-drop-link 430 190 \
          --no-internet-enable \
          "./${DMG_NAME}" \
          "installer_source/"
      else
        echo "dmg-background.png not found. Creating DMG without custom background."
        create-dmg \
          --volname "Rytmo Installer" \
          --window-pos 200 120 \
          --window-size 600 400 \
          --icon-size 100 \
          --icon "$APP_NAME" 170 195 \
          --hide-extension "$APP_NAME" \
          --app-drop-link 430 190 \
          --no-internet-enable \
          "./${DMG_NAME}" \
          "installer_source/"
      fi
    )
  else
    hdiutil create \
      -volname "Rytmo Installer" \
      -srcfolder "$INSTALLER_SOURCE_DIR" \
      -ov \
      -format UDZO \
      "$DMG_PATH"
  fi

  if [[ "$LEGACY_FEED_SYNC" -eq 1 ]]; then
    LEGACY_DMG_PATH="${LEGACY_UPDATE_DIR}/${DMG_NAME}"
    if [[ "$LEGACY_DMG_PATH" != "$DMG_PATH" ]]; then
      cp "$DMG_PATH" "$LEGACY_DMG_PATH"
    fi
  fi
else
  echo "[5/5] Skipped DMG creation (--skip-dmg)"
fi

GITHUB_RELEASE_URL=""
if [[ "$GITHUB_RELEASE" -eq 1 ]]; then
  echo "[6/6] Publishing GitHub release..."

  RELEASE_TAG="${GITHUB_TAG_PREFIX}${SHORT_VERSION}"
  RELEASE_TITLE="Rytmo ${SHORT_VERSION} (${BUILD_VERSION})"

  if [[ -z "$GITHUB_TARGET" ]]; then
    GITHUB_TARGET="$(git rev-parse HEAD)"
  fi

  REPO_ARGS=()
  if [[ -n "$GITHUB_REPO" ]]; then
    REPO_ARGS=(--repo "$GITHUB_REPO")
  fi

  GITHUB_RELEASE_NOTES_FILE="$GITHUB_NOTES_FILE"
  if [[ -z "$GITHUB_RELEASE_NOTES_FILE" ]]; then
    GITHUB_RELEASE_NOTES_FILE="${TMP_DIR}/github_release_notes.md"
    {
      echo "# Rytmo ${SHORT_VERSION}"
      echo
      echo "- Build: ${BUILD_VERSION}"
      if [[ -n "$MIN_SYSTEM_VERSION" ]]; then
        echo "- Minimum macOS: ${MIN_SYSTEM_VERSION}"
      fi
      echo "- Sparkle appcast: ${BASE_DOWNLOAD_URL%/}/appcast.xml"
      echo "- Sparkle archive: ${APPCAST_ENCLOSURE_URL}"
      echo "- Detailed notes: ${APPCAST_RELEASE_NOTES_URL}"
    } > "$GITHUB_RELEASE_NOTES_FILE"
  fi

  RELEASE_ASSETS=("$ZIP_PATH")
  if [[ "$SKIP_DMG" -eq 0 ]]; then
    RELEASE_ASSETS+=("${UPDATE_DIR}/${DMG_NAME}")
  fi

  if [[ "$GITHUB_DRY_RUN" -eq 1 ]]; then
    echo "[GitHub dry-run] tag=${RELEASE_TAG} target=${GITHUB_TARGET}"
    echo "[GitHub dry-run] assets: ${RELEASE_ASSETS[*]}"
    echo "[GitHub dry-run] notes file: ${GITHUB_RELEASE_NOTES_FILE}"
    if [[ ${#REPO_ARGS[@]} -gt 0 ]]; then
      echo "[GitHub dry-run] repo override: ${GITHUB_REPO}"
    fi
  else
    if gh release view "$RELEASE_TAG" "${REPO_ARGS[@]}" >/dev/null 2>&1; then
      echo "GitHub release ${RELEASE_TAG} exists. Updating notes and assets..."
      gh release edit "$RELEASE_TAG" "${REPO_ARGS[@]}" --title "$RELEASE_TITLE" --notes-file "$GITHUB_RELEASE_NOTES_FILE"
      for asset_path in "${RELEASE_ASSETS[@]}"; do
        gh release upload "$RELEASE_TAG" "${REPO_ARGS[@]}" "$asset_path" --clobber
      done
    else
      CREATE_ARGS=()
      if [[ "$GITHUB_DRAFT" -eq 1 ]]; then
        CREATE_ARGS+=(--draft)
      fi
      if [[ "$GITHUB_PRERELEASE" -eq 1 ]]; then
        CREATE_ARGS+=(--prerelease)
      fi

      gh release create "$RELEASE_TAG" "${RELEASE_ASSETS[@]}" "${REPO_ARGS[@]}" "${CREATE_ARGS[@]}" --target "$GITHUB_TARGET" --title "$RELEASE_TITLE" --notes-file "$GITHUB_RELEASE_NOTES_FILE"
    fi

    GITHUB_RELEASE_URL="$(gh release view "$RELEASE_TAG" "${REPO_ARGS[@]}" --json url -q .url)"
  fi
fi

echo
echo "Release artifacts created:"
echo "- ZIP: $ZIP_PATH"
echo "- Appcast: $APPCAST_PATH"
echo "- Release notes: $SPARKLE_RELEASE_NOTES_FILE"
if [[ "$SKIP_DMG" -eq 0 ]]; then
  echo "- DMG: ${UPDATE_DIR}/${DMG_NAME}"
fi
if [[ "$LEGACY_FEED_SYNC" -eq 1 ]]; then
  echo "- Legacy ZIP: ${LEGACY_ZIP_PATH}"
  echo "- Legacy Appcast: ${LEGACY_APPCAST_PATH}"
  echo "- Legacy release notes: ${LEGACY_RELEASE_NOTES_FILE}"
  if [[ "$SKIP_DMG" -eq 0 ]]; then
    echo "- Legacy DMG: ${LEGACY_DMG_PATH}"
  fi
fi
if [[ "$GITHUB_RELEASE" -eq 1 ]]; then
  if [[ "$GITHUB_DRY_RUN" -eq 1 ]]; then
    echo "- GitHub Release: dry-run only (no publish)"
  else
    echo "- GitHub Release: ${GITHUB_RELEASE_URL}"
  fi
fi
echo
echo "Done. Verify files in $UPDATE_DIR and commit/push in this repo as needed."

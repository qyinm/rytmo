#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="rytmo"
PROJECT_NAME="rytmo.xcodeproj"
SCHEME_NAME="rytmo"
CONFIGURATION="${CONFIGURATION:-Debug}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/.build/xcode}"
LOCAL_FIREBASE_PLIST="$ROOT_DIR/rytmo/GoogleService-Info.plist"
LEGACY_FIREBASE_PLIST="$ROOT_DIR/rondo/GoogleService-Info.plist"

usage() {
  echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
}

firebase_plist() {
  if [[ -f "$LOCAL_FIREBASE_PLIST" ]]; then
    printf '%s\n' "$LOCAL_FIREBASE_PLIST"
  elif [[ -f "$LEGACY_FIREBASE_PLIST" ]]; then
    printf '%s\n' "$LEGACY_FIREBASE_PLIST"
  else
    echo "Missing GoogleService-Info.plist. Add it to rytmo/GoogleService-Info.plist." >&2
    exit 1
  fi
}

copy_firebase_plist_if_needed() {
  local source_plist="$1"

  if [[ "$source_plist" != "$LOCAL_FIREBASE_PLIST" ]]; then
    cp "$source_plist" "$LOCAL_FIREBASE_PLIST"
  fi
}

plist_value() {
  local plist="$1"
  local key="$2"

  /usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null || true
}

development_signing_identity() {
  if [[ -n "${RYTMO_CODE_SIGN_IDENTITY:-}" ]]; then
    printf '%s\n' "$RYTMO_CODE_SIGN_IDENTITY"
    return
  fi

  security find-identity -p codesigning -v 2>/dev/null \
    | awk -F '"' '/"Apple Development:/ { print $2; exit }'
}

resign_app() {
  local identity="$1"
  local entitlements_path
  local sign_cmd

  entitlements_path="$DERIVED_DATA_PATH/Build/Intermediates.noindex/$SCHEME_NAME.build/$CONFIGURATION/$SCHEME_NAME.build/$APP_NAME.app.xcent"
  if [[ ! -f "$entitlements_path" ]]; then
    echo "Missing generated entitlements at $entitlements_path" >&2
    exit 1
  fi

  sign_cmd=(codesign
    --force \
    --options runtime \
    --sign "$identity" \
    --entitlements "$entitlements_path" \
    "$APP_BUNDLE")

  if ! "${sign_cmd[@]}" >/dev/null 2>&1; then
    "${sign_cmd[@]}"
  fi

  if ! codesign --verify --strict --deep --verbose=2 "$APP_BUNDLE" >/dev/null 2>&1; then
    codesign --verify --strict --deep --verbose=4 "$APP_BUNDLE"
    exit 1
  fi
}

build_app() {
  local source_plist
  local bundle_id
  local signing_identity

  source_plist="$(firebase_plist)"
  copy_firebase_plist_if_needed "$source_plist"

  bundle_id="${RYTMO_BUNDLE_ID:-$(plist_value "$LOCAL_FIREBASE_PLIST" BUNDLE_ID)}"
  if [[ -z "$bundle_id" ]]; then
    bundle_id="dievas.rytmo"
  fi

  signing_identity="$(development_signing_identity)"
  if [[ -z "$signing_identity" ]]; then
    echo "No Apple Development signing identity found. Set RYTMO_CODE_SIGN_IDENTITY to run the app with Keychain entitlements." >&2
    exit 1
  fi

  /usr/bin/pkill -x "$APP_NAME" >/dev/null 2>&1 || true

  xcodebuild \
    -quiet \
    -project "$ROOT_DIR/$PROJECT_NAME" \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    PRODUCT_BUNDLE_IDENTIFIER="$bundle_id" \
    build

  APP_BUNDLE="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
  APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
  BUNDLE_ID="$bundle_id"

  if [[ ! -x "$APP_BINARY" ]]; then
    echo "Build succeeded, but app binary was not found at $APP_BINARY" >&2
    exit 1
  fi

  if [[ ! -f "$APP_BUNDLE/Contents/Resources/GoogleService-Info.plist" ]]; then
    echo "Build succeeded, but GoogleService-Info.plist was not bundled." >&2
    exit 1
  fi

  resign_app "$signing_identity"
}

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

wait_for_process() {
  local attempts=40

  while (( attempts > 0 )); do
    if /usr/bin/pgrep -x "$APP_NAME" >/dev/null; then
      return 0
    fi

    sleep 0.25
    attempts=$((attempts - 1))
  done

  return 1
}

wait_for_stable_process() {
  wait_for_process || return 1

  local attempts=12

  while (( attempts > 0 )); do
    sleep 0.25

    if ! /usr/bin/pgrep -x "$APP_NAME" >/dev/null; then
      return 1
    fi

    attempts=$((attempts - 1))
  done

  return 0
}

build_app

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    wait_for_stable_process
    if ! codesign --verify --strict --deep --verbose=2 "$APP_BUNDLE" >/dev/null 2>&1; then
      codesign --verify --strict --deep --verbose=4 "$APP_BUNDLE"
      exit 1
    fi
    ;;
  *)
    usage
    exit 2
    ;;
esac

---
title: Releasing Sparkle builds when Xcode archive signing fails
date: 2026-06-28
category: docs/solutions/workflow-issues
module: release-pipeline
problem_type: workflow_issue
component: tooling
severity: high
applies_when:
  - "A macOS release needs Sparkle artifacts, but `xcodebuild archive` fails during signing or provisioning resolution"
symptoms:
  - "Release archives fail even though the app can compile, usually because package targets inherit an unusable signing identity"
  - "Sparkle ZIP, appcast, and DMG generation are blocked behind archive-time signing instead of the actual packaging steps"
root_cause: incomplete_setup
resolution_type: workflow_improvement
related_components:
  - release automation
  - Sparkle updates
  - codesigning
tags:
  - macos-release
  - sparkle
  - codesign
  - xcodebuild
  - developer-id
  - packaging
---

# Releasing Sparkle builds when Xcode archive signing fails

## Context

The Pace release flow needed fresh Sparkle artifacts after the rename, but the existing `scripts/release_update.sh` path assumed `xcodebuild archive` could complete with normal Xcode signing. In practice, archive signing failed before packaging because Swift package targets and provisioning resolution pulled the build into certificate mismatches that were unrelated to the final distributable app bundle.

## Guidance

Treat archive creation and distribution signing as separate steps when Xcode cannot produce a signed archive cleanly.

The working fallback is:

1. Archive the app without Xcode signing.
2. Export the `.app` from that archive.
3. Re-sign the exported bundle with the Developer ID certificate that will actually ship.
4. Verify the signed app bundle.
5. Continue normal Sparkle packaging from the signed export.

That flow is now supported directly by `scripts/release_update.sh`:

```bash
scripts/release_update.sh \
  --unsigned-archive \
  --post-sign-identity "Developer ID Application: dievas (MCP4D3M7XK)"
```

Inside the script, the archive step now opts out of Xcode signing:

```bash
if [[ "$UNSIGNED_ARCHIVE" -eq 1 ]]; then
  XCODEBUILD_ARGS+=(CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO)
fi
```

After export, the script resolves entitlements for the real team and bundle ID, then performs Developer ID signing on the app that will actually be zipped and distributed:

```bash
codesign \
  --force \
  --deep \
  --options runtime \
  --sign "$POST_SIGN_IDENTITY" \
  --entitlements "$RESOLVED_ENTITLEMENTS_PATH" \
  "$EXPORTED_APP_PATH"
codesign --verify --deep --strict --verbose=2 "$EXPORTED_APP_PATH"
```

Once that verification passes, the rest of the release pipeline can stay unchanged:

- zip the exported app for Sparkle
- generate the `sparkle:edSignature`
- update `sparkle/appcast.xml`
- build `sparkle/Pace.dmg`

## Why This Matters

The failure point was not "the app cannot be signed." The failure point was "Xcode archive signing tries to solve more signing state than the release artifact actually needs." If those are treated as the same problem, release work stops at provisioning noise instead of moving forward with a valid Developer ID signed app.

Separating archive production from distribution signing keeps the release pipeline usable when:

- package dependencies drag in signing behavior Xcode cannot satisfy
- the app target can be signed, but archive-time provisioning selection is unstable
- the urgent requirement is to refresh Sparkle artifacts, not to debug Xcode's archive signing model

This also makes the release process more explicit. The script now documents which identity signs the distributable app, instead of hiding that decision inside Xcode project state.

## When to Apply

- When `xcodebuild archive` fails on signing or provisioning before packaging starts
- When the archive succeeds only with ad-hoc or unsigned outputs, but a valid Developer ID certificate is available locally
- When Sparkle ZIP, appcast, and DMG generation need to continue without rewriting the entire project signing setup
- When the release pipeline should be resilient to package-level signing drift

## Examples

Before:

- `scripts/release_update.sh` always relied on a fully signed `xcodebuild archive`
- a signing failure in archive blocked all Sparkle artifacts, even though the exported app could be re-signed successfully afterward

After:

- `scripts/release_update.sh` supports `--unsigned-archive`
- `scripts/release_update.sh` supports `--post-sign-identity`
- the 2026-06-28 release run produced:
  - `sparkle/Pace-1.0.8-17.zip`
  - `sparkle/appcast.xml`
  - `sparkle/Pace.dmg`

## Related

- [Coordinating the Pace rename across app, repo, and hosting](../workflow-issues/renaming-app-brand-across-xcode-github-and-vercel.md)

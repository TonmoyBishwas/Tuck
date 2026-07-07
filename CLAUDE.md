# Tuck — agent guide

Tuck is a free, GPL-3.0 menu bar organizer for macOS (a Bartender alternative). It hides menu bar icons using the **separator-expansion technique** — inflating an `NSStatusItem`'s length pushes everything to its left off-screen — which requires **zero privacy permissions**. That promise is the product's identity; don't trade it away casually.

Constraints that are locked in: macOS 26 (Tahoe)+ only, Apple Silicon (arm64) only, Liquid Glass UI, SwiftPM only (no `.xcodeproj` — contributors open `Package.swift` in Xcode), unsigned/ad-hoc distribution (no Apple Developer account exists).

## Required reading

- `docs/ARCHITECTURE.md` — how the app works; read before touching anything in `Sources/Tuck/StatusBar/`.
- `docs/PITFALLS.md` — symptom → cause → fix for every trap already hit in this codebase; read before debugging anything weird. **Several of these bugs destroy the user's menu bar arrangement, which no code change can restore.**
- `docs/ROADMAP.md` — planned features with feasibility notes; read before starting a new feature.

## Commands

```bash
swift build                        # dev compile check
./scripts/build-app.sh [debug|release]  # → dist/Tuck.app (default: release)
./scripts/build-dmg.sh             # → dist/Tuck-<version>.dmg (prints SHA-256)
./scripts/make-icon.sh             # regenerate Assets/AppIcon.icns from gen-icon.swift
```

**Always verify behavior against `dist/Tuck.app`, never `swift run`** — they use different UserDefaults domains, so preferences and seeded status-item positions diverge.

## Verifying without a GUI

DEBUG builds (`./scripts/build-app.sh debug`) listen for distributed notifications, so you can drive the app from the CLI:

```bash
swift -e 'import Foundation; DistributedNotificationCenter.default().postNotificationName(.init("com.tonmoybishwas.tuck.debug.toggle"), object: nil, userInfo: nil, deliverImmediately: true)'
```

Hooks: `com.tonmoybishwas.tuck.debug.{toggle,peek,openSettings,dump}`. `dump` writes item lengths/window frames to `/tmp/tuck-debug-dump.txt`; every action traces to `/tmp/tuck-debug-events.log`. A collapsed separator length ≈ screen width + 200 (e.g. 1670 on a 1470-pt display) and expanded = 20 are the expected values.

## Iron rules

1. **Never toggle `NSStatusItem.isVisible`** — it permanently loses the item's position (FB9052637). Hide by length only.
2. **Seed `"NSStatusItem Preferred Position …"` defaults before creating any status item**, and only on a virgin install (`StatusItemPositioner`).
3. Collapse length is bounded — `max(500, min(maxScreenWidth + 200, 4000))` — never the classic 10000.
4. All status bar images must be **template images** (Tahoe's menu bar is transparent).
5. Never inflate a divider that might sit to the right of icons the user didn't choose to hide (see PITFALLS #2 — this shipped as a real bug).
6. Distribution stays unsigned + ad-hoc: don't add steps assuming a Developer ID; `spctl --assess` rejection is expected, not a failure.

## Releasing

1. Bump `CFBundleShortVersionString`/`CFBundleVersion` in `Packaging/Info.plist`; update `CHANGELOG.md`.
2. `./scripts/build-app.sh release && ./scripts/build-dmg.sh`.
3. Commit, tag `vX.Y.Z`, push, then `gh release create vX.Y.Z dist/Tuck-X.Y.Z.dmg` with install steps + the printed SHA-256 in the notes. Release notes must include both Gatekeeper paths (System Settings → Privacy & Security → "Open Anyway", or `xattr -dr com.apple.quarantine /Applications/Tuck.app`) — right-click → Open no longer works on Sequoia/Tahoe.

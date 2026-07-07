# Roadmap

Where Tuck should go after 1.0, ordered by value-per-risk. The organizing principle: **Tuck currently requires zero privacy permissions**, and that is a headline feature. Everything below is grouped by whether it keeps that promise.

## Tier 1 — near-term, zero-permission, low risk

**Homebrew cask** — the single biggest UX win. For an unsigned app, `brew install --cask tuck` sidesteps the whole Gatekeeper dance (`--no-quarantine` guidance, or the cask's standard flow). Steps: submit to homebrew/homebrew-cask referencing the GitHub release DMG + SHA-256 (`build-dmg.sh` already prints it); casks for unsigned apps are accepted but run `brew audit --new-cask` first and expect reviewers to ask about signing. Update the README install section once accepted.

**Update notifier** — users of an unsigned app get no update channel at all today. Start with a lightweight check of the GitHub Releases API (compare tag against `CFBundleShortVersionString`, notify at most once per version, link to the release page). Avoid bundling Sparkle initially: it drags in signing/appcast infrastructure that clashes with the unsigned constraint.

**Profiles** — named snapshots of the user's arrangement. Tuck's own item positions are just the three `"NSStatusItem Preferred Position …"` defaults keys, so save/restore of *Tuck's* layout is trivial; be honest in the UI that third-party icon positions can't be moved programmatically (see ARCHITECTURE — no API exists). A profile is therefore "which sections exist + Tuck divider placement + settings," not a full menu-bar layout.

**Localization** — the KeyboardShortcuts dependency already ships localized; Tuck's own strings are few and centralized in the SwiftUI views. Standard `String(localized:)` sweep + a couple of community languages.

**Multi-display audit** — `collapsedLength()` already uses the widest screen and listens for geometry changes, but peek/hover/outside-click behavior on a second display has never been systematically tested. Write down expected behavior first, then fix deviations.

## Tier 2 — medium effort, approaching the permission line

**Menu bar search palette** (Bartender's "Quick search") — a floating panel that finds and clicks a status item by name. Requires *enumerating other apps' items*, which the current architecture deliberately cannot do. Least-invasive route: the Accessibility API (`AXUIElement` on the menu bar owner) — needs the Accessibility permission but not Screen Recording. This is the first feature that crosses the permission line; if built, it must be **optional and degradable**: the app keeps working fully without the permission, and the UI explains exactly why it's asked for.

**Spacing/gap control** — Bartender-style tightening of menu bar item spacing uses the `NSStatusItemSpacing`/`NSStatusItemSelectionPadding` defaults, which apply system-wide and require a logout/relaunch of apps to take effect. Cheap to implement, awkward UX — ship only with clear caveats in the UI.

## Tier 3 — long-term, requires an architectural fork

Floating "Tuck Bar" (second bar for notched Macs), show-on-trigger rules (reveal an icon on battery/CPU/network events), and per-icon control all require knowing *which* icons exist and rendering them — the Ice model: Screen Recording permission + `CGWindowList`-style capture (note PITFALLS #8: status item windows aren't in CGWindowList on Tahoe; Ice uses private CGS APIs). **Do not bolt this onto `StatusBarController`.** It is a second engine with a different privacy story; if it ever happens, it should be a separate module the user explicitly opts into, with the separator engine remaining the default.

## Non-goals

- Intel/x86_64 support, macOS < 26 — locked decisions, the Liquid Glass UI doesn't compile below Tahoe anyway.
- Paid signing/notarization — there is no Developer ID; don't build features that assume one.
- Anything that makes the *default* experience require a privacy permission.

## Conventions

- Semver. User-visible changes go in `CHANGELOG.md` (Keep-a-Changelog style, matching the existing 1.0.0 entry).
- Release flow is in `CLAUDE.md` § Releasing; `.github/workflows/release.yml` is best-effort CI on tag push — the local scripts are authoritative.
- New features that add preferences: extend `Preferences` (register a default, `@Published` + `didSet`), observe via Combine in the controller — follow the existing pattern.

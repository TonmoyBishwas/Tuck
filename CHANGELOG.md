# Changelog

## Unreleased

### Changed
- Auto-rehide and hide-on-outside-click are now **off by default** (opt-in via Settings → General). Nothing moves the menu bar unless the user asked for it. Existing installs that already toggled these keep their choice.

## 1.0.0 — 2026-07-07

Initial release.

- Hide/show menu bar icons behind a single chevron (expanding-separator technique, zero permissions)
- Always-hidden section with option-click peek
- Auto-rehide with configurable delay; collapse on outside click
- Optional hover-to-reveal
- Global hotkeys (default `⌥⌘\`) via Carbon — no Accessibility permission
- Launch at login (SMAppService)
- Liquid Glass settings window (General / Sections / Shortcuts / About)
- Three-step onboarding tutorial
- Start behavior: remember last state / start tucked / start expanded

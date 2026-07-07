# Pitfalls

Every trap in this list was actually hit while building Tuck 1.0. Format: **symptom → cause → correct move.** Ordered by how likely you are to hit it again. The ones marked ⚠️ destroy the *user's* menu bar arrangement — state that lives in their defaults and muscle memory, which no code change can restore — so treat them as unshippable, not just bugs.

### 1. ⚠️ Hiding via `isVisible` loses item positions
**Symptom:** after toggling an item invisible and back, it reappears in the wrong slot; the user's arrangement is scrambled.
**Cause:** long-standing AppKit bug (FB9052637): `NSStatusItem.isVisible = false` discards the autosaved position.
**Correct move:** hide by **length only**, always. Nothing in the codebase touches `isVisible` for hiding, ever.

### 2. ⚠️ Always-hidden divider swallows the entire menu bar
**Symptom (verbatim from the real 1.0 bug report):** "when I click ‹ it only brings a │ and nothing else, all of my bar icons are gone."
**Cause:** the always-hidden divider stays inflated by design even when Tuck is expanded. Seeded at a fixed position (140) it can land to the *right* of icons the user never chose to hide — inflating it pushes all of them off-screen with no way back.
**Correct move (all three, currently implemented):** the section is **opt-in** (`alwaysHiddenEnabled` defaults to false); on enable, `seedAlwaysHiddenAdjacentToSeparator()` places it immediately left of the main separator (its stored position + 25); it spawns **deflated** and only inflates 0.6 s later, once it has settled into its slot. If you ever add another Tuck-owned item, apply the same reasoning before it inflates anything.

### 3. Seeding positions after item creation scrambles the layout
**Symptom:** on first launch the three Tuck items spawn in the wrong order (e.g. dividers right of the chevron).
**Cause:** `"NSStatusItem Preferred Position <autosaveName>"` defaults must exist **before** `NSStatusBar.statusItem(...)` is called; afterwards AppKit's own values win.
**Correct move:** `StatusItemPositioner.seedIfNeeded()` is the first thing `applicationDidFinishLaunching` does, and it only writes when the keys are absent (virgin install) — later launches must respect the user's drags.

### 4. Verifying against `swift run` instead of `dist/Tuck.app`
**Symptom:** preferences don't persist, seeded positions "don't work," onboarding reappears, behavior differs run to run.
**Cause:** `swift run` executes a bare binary whose `UserDefaults.standard` resolves to a different domain than the bundled app (`com.tonmoybishwas.tuck`).
**Correct move:** always verify with `./scripts/build-app.sh debug && open dist/Tuck.app`, then inspect with `defaults read com.tonmoybishwas.tuck`.

### 5. App launches but does nothing (weak delegate)
**Symptom:** process runs, no status items, no log output after launch.
**Cause:** `NSApplication.delegate` is a *weak* reference; an `AppDelegate` held only by a local in `main` is deallocated immediately.
**Correct move:** `TuckMain` holds it as `private static let delegate` — don't "simplify" that away.

### 6. Modal alert at startup freezes the app
**Symptom:** app hangs right after launch; debug hooks stop responding.
**Cause:** running the ordering check one runloop turn after launch: the item windows aren't laid out yet, origins compare equal, the state reads "broken," and `NSAlert.runModal()` blocks the main thread with no one to dismiss it.
**Correct move:** equal/missing origins are `.indeterminate`, not `.broken`; alerts fire only for `userInitiated` collapses; `applyStartBehavior()` runs 0.5 s after launch. Keep all three.

### 7. Build breaks: missing bundle or "Permission denied"
**Symptom:** shortcut-recorder UI broken at runtime; or `codesign`/`xattr` on the assembled app fails with Permission denied.
**Cause:** (a) KeyboardShortcuts ships localized resources in a `.bundle` that SwiftPM leaves next to the binary — it must be copied into `Contents/Resources/`. (b) SwiftPM checkout files are read-only and `cp` preserves that.
**Correct move:** `scripts/build-app.sh` already copies `$BUILD_DIR/*.bundle` and runs `chmod -R u+w` before signing. If you rewrite the build script, keep both steps.

### 8. Tahoe red herrings
- `CGWindowListCopyWindowInfo` does **not** list `NSStatusItem` windows on macOS 26. This is not a bug in your code — use `NSApp.windows` (the `debug.dump` hook prints them). Hours were lost here once; don't chase it again.
- The Tahoe menu bar is transparent: any non-template status image is invisible in some appearances. Every image in `StatusBarIcons` sets `isTemplate = true`.

### 9. Gatekeeper on an unsigned app
- Unsigned arm64 binaries are **killed on launch** — the ad-hoc `codesign --force --sign -` step is mandatory, not cosmetic.
- `spctl --assess` saying "rejected" is the **expected** result for this app. Not a build failure.
- Right-click → Open is removed on Sequoia/Tahoe. The only user paths are System Settings → Privacy & Security → "Open Anyway", or `xattr -dr com.apple.quarantine /Applications/Tuck.app`. Keep both in the README and every release note.
- Don't add signing/notarization steps that assume a Developer ID — there isn't one.

### 10. A permanent `statusItem.menu` swallows left-clicks
**Symptom:** chevron stops toggling; every click opens the menu.
**Cause:** assigning `NSStatusItem.menu` permanently makes AppKit route *all* clicks to it.
**Correct move:** the assign → `performClick(nil)` → clear pattern in `showContextMenu()`, with right/left/option branching on `NSApp.currentEvent` in the button action.

### 11. Swift 6 strict-concurrency compile errors in callbacks
**Symptom:** "call to main actor-isolated … in a synchronous nonisolated context" in Timer / event-monitor / DistributedNotificationCenter closures.
**Correct move:** these callbacks do arrive on the main queue but aren't statically isolated — wrap the body in `MainActor.assumeIsolated`. For `NotificationCenter`, prefer Combine publishers (the sink inherits `@MainActor`).

### 12. Collapse length: don't use 10000
**Symptom:** with an unbounded/huge separator length, layout glitches on recent macOS (the classic Hidden Bar/Dozer value).
**Correct move:** `collapsedLength()` = `max(500, min(maxScreenWidth + 200, 4000))`, recomputed on `didChangeScreenParametersNotification`. Big enough for any display, bounded on purpose.

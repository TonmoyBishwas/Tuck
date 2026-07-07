# Tuck architecture

How the app works, file by file and flow by flow. Companion documents: [PITFALLS.md](PITFALLS.md) (traps already hit) and [ROADMAP.md](ROADMAP.md) (what to build next).

## The mental model

macOS lays out status items **right to left**. Tuck owns three `NSStatusItem`s and hides other apps' icons purely by inflating its separator's width so everything left of it slides past the screen edge:

```
 ┌ always-hidden divider (┆, opt-in)     ┌ main divider (│)     ┌ toggle chevron (‹ / ›)
 ▼                                       ▼                      ▼
[always-hidden icons] ┆ [hideable icons] │ ‹  [always-visible icons]  Wi-Fi  Clock
◀──────────────────── further from right edge ──────────────── nearer ─────────────▶
```

- **Collapse** = set separator length to `max(500, min(maxScreenWidth + 200, 4000))`. Icons left of it are pushed off-screen. **Expand** = restore length 20.
- The always-hidden divider stays inflated even while expanded; only an option-click "peek" deflates it.
- There is **no API to move third-party status items**. Users assign icons to sections by native ⌘-drag; onboarding teaches this. Tuck only positions its *own* three items.
- Nothing here needs Screen Recording, Accessibility, or any other permission. Keep it that way (see ROADMAP for where that line sits).

## Module map

| File | Responsibility |
|---|---|
| `TuckMain.swift` | `@main` bootstrap. Holds the `AppDelegate` in a **`static let`** — `NSApplication.delegate` is weak; a local would deallocate silently. Sets `.accessory` activation policy (no Dock icon). |
| `AppDelegate.swift` | Wiring hub. Launch order: seed positions → `StatusBarController` → `HotkeyManager` → debug hooks → onboarding *or* start behavior (delayed 0.5 s). Owns settings/onboarding window controllers. DEBUG-only `DistributedNotificationCenter` hooks. |
| `StatusBar/StatusBarController.swift` | The engine. Creates the three items, `collapse(userInitiated:)`/`expand(peekAlwaysHidden:)`/`toggle()`, ordering sanity check, right-click context menu, rehide timer, monitor lifecycle, Combine observation of preference changes and screen-geometry changes. |
| `StatusBar/StatusItemPositioner.swift` | Pre-seeds `"NSStatusItem Preferred Position <autosaveName>"` defaults keys, and re-seeds the always-hidden divider next to the separator when freshly enabled. |
| `StatusBar/StatusBarIcons.swift` | Template images only: `chevron.left`/`chevron.right` SF Symbols for the toggle, hand-drawn 3×14 pt line glyphs for the dividers (solid │, dashed ┆). |
| `StatusBar/EventMonitors.swift` | Global `NSEvent` monitors (permission-free): outside-click and debounced (1 s) menu-bar hover. `mouseIsInMenuBar()` = `location.y > screen.visibleFrame.maxY`. |
| `State/Preferences.swift` | `@MainActor ObservableObject` singleton over `UserDefaults`; `@Published var … { didSet { persist } }`. Single source of truth for AppKit *and* SwiftUI. Defaults registered in `init`. |
| `State/HotkeyManager.swift` | [sindresorhus/KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) names: `toggleHidden` (default ⌥⌘\\) and `peekAlwaysHidden` (none). Carbon hotkeys — permission-free. |
| `Support/LoginItemManager.swift` | `SMAppService.mainApp` register/unregister; surfaces `.requiresApproval`. Only meaningful when running from `/Applications`. |
| `Support/Logging.swift` | `os.Logger` subsystem `com.tonmoybishwas.tuck`; `Log.trace()` appends to `/tmp/tuck-debug-events.log` in DEBUG builds. |
| `Settings/*` | Plain `NSWindow` + `NSHostingController` (no SwiftUI `Settings` scene — unreliable for `LSUIElement` apps). `SettingsTab` enum: general/sections/shortcuts/about. Liquid Glass (`GlassEffectContainer`, `.glassEffect`, `.buttonStyle(.glass)`). |
| `Onboarding/*` | 3-step first-launch tutorial (welcome → animated ⌘-drag demo → always-hidden/shortcut tips). Finishing sets `hasCompletedOnboarding` and applies start behavior. |

## The positioning system

`autosaveName` makes AppKit persist each item's slot in `UserDefaults.standard` under `"NSStatusItem Preferred Position <name>"`. The value is the **distance in points from the right screen edge — larger = further left.**

- Virgin install only, *before* any item exists, `seedIfNeeded()` writes: toggle = 100, separator = 120, always-hidden = 140. This spawns them in the correct relative order; afterwards the user's own drags are authoritative and Tuck never touches the keys again…
- …except `seedAlwaysHiddenAdjacentToSeparator()`: when the user *enables* the always-hidden section later, its divider must appear immediately left of the main separator (separator's current stored position + 25), spawn **deflated** (length 20), and inflate only 0.6 s later. See PITFALLS #2 for the shipped bug this prevents.

## Key flows

**Launch** (`applicationDidFinishLaunching`): seed → create items → hotkeys → debug hooks → if onboarding done, `applyStartBehavior()` after 0.5 s (item windows need time to lay out before the ordering check); otherwise show onboarding, which applies start behavior on finish.

**Collapse** (`collapse(userInitiated:)`): check `orderingState()` first —
- `.sane` (separator left of toggle): inflate separator (and always-hidden item), swap the chevron to ‹ (`chevron.left` = collapsed, "click to bring items back"; `chevron.right` = expanded), persist `isCollapsed`, stop the outside-click monitor, update the hover monitor.
- `.broken` (user ⌘-dragged separator right of toggle — collapsing would hide unreachable icons): refuse; modal alert **only if `userInitiated`**. Automatic paths (startup, rehide timer, outside click) skip silently.
- `.indeterminate` (window origins equal/missing, i.e. right after launch): proceed — autosaved positions assert themselves. Never alert here (PITFALLS #6).

**Expand** (`expand(peekAlwaysHidden:)`): separator → 20; always-hidden item → 20 only when peeking, else stays inflated; schedule rehide timer (2–120 s, default 15); start outside-click monitor if enabled. The rehide timer re-schedules instead of firing while any app window is key (user is in settings/onboarding).

**Toggle click** (`toggleClicked`): `sendAction(on: [.leftMouseUp, .rightMouseUp])`, then branch on `NSApp.currentEvent`: right-click → context menu (assign menu → `performClick` → clear — a permanently assigned menu swallows left-clicks); option-click → peek; plain click → toggle.

**Preference changes**: `StatusBarController.observePreferences()` sinks Combine publishers from `Preferences` — enabling always-hidden creates the item with `freshlyEnabled: true`, disabling removes it; hover/outside-click toggles start/stop their monitors. Screen-parameter changes recompute inflated lengths.

## Concurrency

Swift 6 strict concurrency, everything relevant is `@MainActor`. Closures that arrive on the main queue but aren't statically isolated (Timer, global event monitors, `DistributedNotificationCenter`) use `MainActor.assumeIsolated`. `NotificationCenter` observation goes through Combine publishers so the sink inherits `@MainActor`.

## Build & packaging pipeline

```
swift build -c release --arch arm64
  └► scripts/build-app.sh: assemble dist/Tuck.app
       Contents/MacOS/Tuck, Info.plist (LSUIElement, min 26.0, arm64), PkgInfo,
       Resources/AppIcon.icns, Resources/*.bundle  ← KeyboardShortcuts resources, REQUIRED
       chmod -R u+w (SwiftPM checkouts are read-only)
       codesign --force --sign -   (ad-hoc, no --deep)
  └► scripts/build-dmg.sh: hdiutil UDZO image with app + /Applications symlink; prints SHA-256
```

`scripts/gen-icon.swift` + `make-icon.sh` regenerate `Assets/AppIcon.icns` programmatically (no design tools needed). `.github/workflows/release.yml` attempts the same build on a tag push (best-effort — depends on `macos-26` runner availability); the local scripts are the source of truth.

## Debug hooks (DEBUG builds only)

`AppDelegate.installDebugHooks()` observes distributed notifications, so the app can be driven headlessly:

| Notification | Effect |
|---|---|
| `com.tonmoybishwas.tuck.debug.toggle` | `statusBarController.toggle()` |
| `com.tonmoybishwas.tuck.debug.peek` | `expand(peekAlwaysHidden: true)` |
| `com.tonmoybishwas.tuck.debug.openSettings` | opens the settings window |
| `com.tonmoybishwas.tuck.debug.dump` | writes item lengths/frames + window list to `/tmp/tuck-debug-dump.txt` |

Post one with:

```bash
swift -e 'import Foundation; DistributedNotificationCenter.default().postNotificationName(.init("com.tonmoybishwas.tuck.debug.dump"), object: nil, userInfo: nil, deliverImmediately: true)'
```

`Log.trace()` events land in `/tmp/tuck-debug-events.log`. This is the primary verification loop: build debug, launch `dist/Tuck.app`, fire hooks, read the dump/trace. (Note: `CGWindowListCopyWindowInfo` does *not* list status item windows on Tahoe — the dump's `NSApp.windows` listing is how you see them.)

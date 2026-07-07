import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Default: ⌥⌘\
    static let toggleHidden = Self("toggleHidden", default: .init(.backslash, modifiers: [.option, .command]))
    static let peekAlwaysHidden = Self("peekAlwaysHidden")
}

/// Global hotkeys via Carbon RegisterEventHotKey (wrapped by the
/// KeyboardShortcuts package) — works without any privacy permissions.
@MainActor
final class HotkeyManager {
    init(statusBar: StatusBarController) {
        KeyboardShortcuts.onKeyUp(for: .toggleHidden) { [weak statusBar] in
            statusBar?.toggle()
        }
        KeyboardShortcuts.onKeyUp(for: .peekAlwaysHidden) { [weak statusBar] in
            statusBar?.expand(peekAlwaysHidden: true)
        }
    }
}

import AppKit

/// Pre-seeds the "NSStatusItem Preferred Position" defaults keys before any
/// status item is created, so that on first launch the items spawn in the
/// correct order: [always-hidden separator] [separator] [toggle], right to
/// left. The values are distances in points from the right edge of the
/// screen — larger means further left. Without seeding, macOS places new
/// items at the far left and the user would have to untangle them by hand.
@MainActor
enum StatusItemPositioner {
    static let toggleAutosaveName = "tuck_toggle"
    static let separatorAutosaveName = "tuck_separator"
    static let alwaysHiddenAutosaveName = "tuck_always_hidden"

    private static func positionKey(_ autosaveName: String) -> String {
        "NSStatusItem Preferred Position \(autosaveName)"
    }

    static func seedIfNeeded() {
        let defaults = UserDefaults.standard
        // Only seed a virgin install; afterwards autosaveName keeps the
        // user's own arrangement authoritative.
        guard defaults.object(forKey: positionKey(toggleAutosaveName)) == nil else { return }
        defaults.set(100, forKey: positionKey(toggleAutosaveName))
        defaults.set(120, forKey: positionKey(separatorAutosaveName))
        defaults.set(140, forKey: positionKey(alwaysHiddenAutosaveName))
        Log.statusBar.info("Seeded initial status item positions")
    }

    /// When the user enables the always-hidden section, its divider must
    /// appear immediately left of the main separator — anywhere further left
    /// would swallow existing icons the moment it inflates. AppKit keeps the
    /// "Preferred Position" keys current as items are dragged, so seed
    /// relative to the separator's latest stored position.
    static func seedAlwaysHiddenAdjacentToSeparator() {
        let defaults = UserDefaults.standard
        let separatorPosition = defaults.double(forKey: positionKey(separatorAutosaveName))
        let base = separatorPosition > 0 ? separatorPosition : 120
        defaults.set(base + 25, forKey: positionKey(alwaysHiddenAutosaveName))
        Log.statusBar.info("Re-seeded always-hidden divider next to separator")
    }
}

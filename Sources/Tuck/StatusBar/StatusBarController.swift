import AppKit
import Combine

/// Owns the three status items and implements hiding via the
/// separator-expansion technique: menu bar items are laid out right to left,
/// and inflating the separator's length pushes everything to its left off
/// the screen edge. This requires no privacy permissions at all.
///
/// Menu bar layout, left to right:
///   [always-hidden items] ┆ [hidden items] │ ‹ [visible items]
///                         └ always-hidden      └ toggle chevron
///                           separator        └ separator
@MainActor
final class StatusBarController {
    private let preferences: Preferences
    private let statusBar = NSStatusBar.system

    private let toggleItem: NSStatusItem
    private let separatorItem: NSStatusItem
    private var alwaysHiddenItem: NSStatusItem?

    private var rehideTimer: Timer?
    private let monitors = EventMonitors()
    private var cancellables: Set<AnyCancellable> = []
    private var isPeekingAlwaysHidden = false

    /// Set by the app delegate so menu entries can open app windows.
    var onOpenSettings: (() -> Void)?
    var onOpenAbout: (() -> Void)?
    var onShowTutorial: (() -> Void)?

    static let expandedSeparatorLength: CGFloat = 20

    init(preferences: Preferences) {
        self.preferences = preferences

        toggleItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        toggleItem.autosaveName = StatusItemPositioner.toggleAutosaveName
        toggleItem.behavior = []

        separatorItem = statusBar.statusItem(withLength: Self.expandedSeparatorLength)
        separatorItem.autosaveName = StatusItemPositioner.separatorAutosaveName

        if let button = toggleItem.button {
            button.image = StatusBarIcons.expanded
            button.target = self
            button.action = #selector(toggleClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Tuck — click to hide or show menu bar items"
        }
        separatorItem.button?.image = StatusBarIcons.separator
        separatorItem.button?.toolTip = "Tuck divider — ⌘-drag icons to its left to hide them"

        if preferences.alwaysHiddenEnabled {
            createAlwaysHiddenItem()
        }

        observePreferences()
        observeScreenChanges()
    }

    // MARK: - Collapse / expand

    var isCollapsed: Bool { preferences.isCollapsed }

    func toggle() {
        if preferences.isCollapsed {
            expand()
        } else {
            collapse(userInitiated: true)
        }
    }

    /// `userInitiated` controls how a broken item ordering is reported: a
    /// modal alert for direct user actions, a silent skip for automatic
    /// paths (startup, rehide timer, outside clicks).
    func collapse(userInitiated: Bool = false) {
        if orderingState() == .broken {
            Log.statusBar.warning("Refusing to collapse: item ordering is broken")
            Log.trace("collapse refused: ordering broken")
            if userInitiated {
                presentOrderingAlert()
            }
            return
        }
        cancelRehide()
        isPeekingAlwaysHidden = false
        separatorItem.length = collapsedLength()
        alwaysHiddenItem?.length = collapsedLength()
        toggleItem.button?.image = StatusBarIcons.collapsed
        preferences.isCollapsed = true
        monitors.stopOutsideClick()
        updateHoverMonitor()
        Log.statusBar.info("Collapsed")
        Log.trace("collapse()")
    }

    func expand(peekAlwaysHidden: Bool = false) {
        isPeekingAlwaysHidden = peekAlwaysHidden
        separatorItem.length = Self.expandedSeparatorLength
        alwaysHiddenItem?.length = peekAlwaysHidden
            ? Self.expandedSeparatorLength
            : collapsedLength()
        toggleItem.button?.image = StatusBarIcons.expanded
        preferences.isCollapsed = false
        scheduleRehide()
        if preferences.collapseOnOutsideClick {
            monitors.startOutsideClick { [weak self] event in
                self?.handleOutsideClick(event)
            }
        }
        updateHoverMonitor()
        Log.statusBar.info("Expanded (peek: \(peekAlwaysHidden))")
        Log.trace("expand(peek: \(peekAlwaysHidden))")
    }

    /// Applies the user's configured startup behavior. Deferred one runloop
    /// turn by the caller so the status item windows exist for the ordering
    /// sanity check.
    func applyStartBehavior() {
        Log.trace("applyStartBehavior(\(preferences.startBehavior.rawValue)) isCollapsed=\(preferences.isCollapsed)")
        switch preferences.startBehavior {
        case .remember:
            if preferences.isCollapsed { collapse() } else { expand() }
        case .collapsed:
            collapse()
        case .expanded:
            expand()
        }
    }

    private func collapsedLength() -> CGFloat {
        // Bounded, unlike the classic 10000pt trick: unbounded lengths cause
        // layout pathologies on recent macOS. Large enough to push every
        // hidden item past the left screen edge on any display.
        let widest = NSScreen.screens.map(\.frame.width).max() ?? 2000
        return max(500, min(widest + 200, 4000))
    }

    // MARK: - Ordering sanity

    private enum OrderingState {
        case sane
        case broken
        /// Windows missing or not laid out yet (equal origins right after
        /// launch) — don't block, autosaved positions will assert themselves.
        case indeterminate
    }

    /// The user can ⌘-drag our items into a broken order at any time. If the
    /// separator sits to the right of the toggle, collapsing would hide the
    /// wrong icons with no way to reach them — so refuse instead.
    private func orderingState() -> OrderingState {
        guard
            let toggleX = toggleItem.button?.window?.frame.origin.x,
            let separatorX = separatorItem.button?.window?.frame.origin.x
        else {
            return .indeterminate
        }
        if separatorX == toggleX { return .indeterminate }
        if separatorX > toggleX { return .broken }
        if let alwaysHiddenX = alwaysHiddenItem?.button?.window?.frame.origin.x,
           alwaysHiddenItem?.length == Self.expandedSeparatorLength,
           alwaysHiddenX > separatorX {
            return .broken
        }
        return .sane
    }

    private func presentOrderingAlert() {
        let alert = NSAlert()
        alert.messageText = "Tuck's icons are out of order"
        alert.informativeText = """
        The Tuck divider must sit to the left of the chevron (‹) in the menu \
        bar. Hold ⌘ and drag the divider back to the left of the chevron, \
        then try again.
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Show Tutorial")
        NSApp.activate()
        if alert.runModal() == .alertSecondButtonReturn {
            onShowTutorial?()
        }
    }

    // MARK: - Click handling

    @objc private func toggleClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else if event.modifierFlags.contains(.option) {
            // Option-click: peek at the always-hidden section too.
            expand(peekAlwaysHidden: true)
        } else {
            toggle()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()

        let toggleTitle = preferences.isCollapsed ? "Show Hidden Items" : "Hide Items"
        let toggleEntry = NSMenuItem(title: toggleTitle, action: #selector(menuToggle), keyEquivalent: "")
        toggleEntry.target = self
        menu.addItem(toggleEntry)

        if preferences.alwaysHiddenEnabled {
            let peekEntry = NSMenuItem(title: "Peek at Always-Hidden Items", action: #selector(menuPeek), keyEquivalent: "")
            peekEntry.target = self
            menu.addItem(peekEntry)
        }

        menu.addItem(.separator())

        let settingsEntry = NSMenuItem(title: "Settings…", action: #selector(menuOpenSettings), keyEquivalent: ",")
        settingsEntry.target = self
        menu.addItem(settingsEntry)

        let aboutEntry = NSMenuItem(title: "About Tuck", action: #selector(menuOpenAbout), keyEquivalent: "")
        aboutEntry.target = self
        menu.addItem(aboutEntry)

        menu.addItem(.separator())

        let quitEntry = NSMenuItem(title: "Quit Tuck", action: #selector(menuQuit), keyEquivalent: "q")
        quitEntry.target = self
        menu.addItem(quitEntry)

        // Assign → click → clear: a permanently assigned menu would swallow
        // the button's left-click action.
        toggleItem.menu = menu
        toggleItem.button?.performClick(nil)
        toggleItem.menu = nil
    }

    @objc private func menuToggle() { toggle() }
    @objc private func menuPeek() { expand(peekAlwaysHidden: true) }
    @objc private func menuOpenSettings() { onOpenSettings?() }
    @objc private func menuOpenAbout() { onOpenAbout?() }
    @objc private func menuQuit() { NSApp.terminate(nil) }

    // MARK: - Auto-rehide

    private func scheduleRehide() {
        cancelRehide()
        guard preferences.autoRehideEnabled else { return }
        let delay = preferences.autoRehideDelay
        rehideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            MainActor.assumeIsolated {
                self.rehideTimerFired()
            }
        }
    }

    private func rehideTimerFired() {
        // Don't yank the menu bar around while the user is in one of our
        // windows (settings / onboarding); check again later instead.
        if NSApp.keyWindow != nil {
            scheduleRehide()
            return
        }
        collapse()
    }

    private func cancelRehide() {
        rehideTimer?.invalidate()
        rehideTimer = nil
    }

    private func handleOutsideClick(_ event: NSEvent) {
        guard !preferences.isCollapsed else { return }
        // Ignore clicks in the menu bar band: the user may be ⌘-dragging
        // icons or using a revealed item. The rehide timer covers those.
        if EventMonitors.mouseIsInMenuBar() { return }
        collapse()
    }

    private func updateHoverMonitor() {
        // A global mouseMoved monitor is high-frequency; keep it installed
        // only while it can actually do something.
        if preferences.hoverToReveal && preferences.isCollapsed {
            monitors.startHover { [weak self] in
                guard let self, self.preferences.isCollapsed else { return }
                self.expand()
            }
        } else {
            monitors.stopHover()
        }
    }

    // MARK: - Always-hidden section

    /// `freshlyEnabled` is true when the user just switched the section on:
    /// the divider is then seeded immediately left of the main separator and
    /// created deflated, so that inflating it cannot swallow existing icons
    /// the user never chose to hide. On normal startup the autosaved
    /// arrangement is already the user's own, so it spawns inflated.
    private func createAlwaysHiddenItem(freshlyEnabled: Bool = false) {
        if freshlyEnabled {
            StatusItemPositioner.seedAlwaysHiddenAdjacentToSeparator()
        }
        let item = statusBar.statusItem(
            withLength: freshlyEnabled ? Self.expandedSeparatorLength : collapsedLength()
        )
        item.autosaveName = StatusItemPositioner.alwaysHiddenAutosaveName
        item.button?.image = StatusBarIcons.alwaysHiddenSeparator
        item.button?.toolTip = "Tuck always-hidden divider — icons left of this stay hidden"
        alwaysHiddenItem = item
        if freshlyEnabled {
            // Inflate once it has settled into its adjacent slot.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                guard let self, let item = alwaysHiddenItem, !isPeekingAlwaysHidden else { return }
                item.length = collapsedLength()
            }
        }
    }

    private func removeAlwaysHiddenItem() {
        if let item = alwaysHiddenItem {
            statusBar.removeStatusItem(item)
            alwaysHiddenItem = nil
        }
    }

    // MARK: - Observation

    private func observePreferences() {
        preferences.$alwaysHiddenEnabled
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self else { return }
                if enabled {
                    if alwaysHiddenItem == nil { createAlwaysHiddenItem(freshlyEnabled: true) }
                } else {
                    removeAlwaysHiddenItem()
                }
            }
            .store(in: &cancellables)

        preferences.$hoverToReveal
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] _ in
                // Defer so the published property has its new value.
                DispatchQueue.main.async { self?.updateHoverMonitor() }
            }
            .store(in: &cancellables)

        preferences.$collapseOnOutsideClick
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self else { return }
                if !enabled {
                    monitors.stopOutsideClick()
                } else if !preferences.isCollapsed {
                    monitors.startOutsideClick { [weak self] event in
                        self?.handleOutsideClick(event)
                    }
                }
            }
            .store(in: &cancellables)
    }

    #if DEBUG
    func debugDescriptionText() -> String {
        func describe(_ name: String, _ item: NSStatusItem?) -> String {
            guard let item else { return "\(name): nil" }
            let frame = item.button?.window?.frame
            return "\(name): length=\(item.length) visible=\(item.isVisible) windowFrame=\(String(describing: frame))"
        }
        return [
            describe("toggle", toggleItem),
            describe("separator", separatorItem),
            describe("alwaysHidden", alwaysHiddenItem),
            "prefs.isCollapsed=\(preferences.isCollapsed)",
        ].joined(separator: "\n")
    }
    #endif

    private func observeScreenChanges() {
        NotificationCenter.default
            .publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                // Recompute inflated lengths for the new display geometry.
                if preferences.isCollapsed {
                    separatorItem.length = collapsedLength()
                }
                if let item = alwaysHiddenItem, !isPeekingAlwaysHidden {
                    item.length = collapsedLength()
                }
            }
            .store(in: &cancellables)
    }
}

import AppKit
import SwiftUI

enum SettingsTab: String, Hashable, CaseIterable {
    case general
    case sections
    case shortcuts
    case about
}

@MainActor
final class SettingsTabSelection: ObservableObject {
    @Published var tab: SettingsTab = .general
}

@MainActor
final class SettingsWindowController {
    private let window: NSWindow
    private let selection = SettingsTabSelection()

    init(preferences: Preferences) {
        let view = SettingsView()
            .environmentObject(preferences)
            .environmentObject(selection)
            .environmentObject(LoginItemManager.shared)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Tuck Settings"
        window.contentViewController = NSHostingController(rootView: view)
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show(tab: SettingsTab = .general) {
        selection.tab = tab
        LoginItemManager.shared.refresh()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }
}

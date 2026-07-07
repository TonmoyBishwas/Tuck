import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) static weak var shared: AppDelegate?

    let preferences = Preferences.shared
    private(set) var statusBarController: StatusBarController?
    private var hotkeyManager: HotkeyManager?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self

        // Must run before any status item is created.
        StatusItemPositioner.seedIfNeeded()

        let statusBar = StatusBarController(preferences: preferences)
        statusBar.onOpenSettings = { [weak self] in self?.openSettings() }
        statusBar.onOpenAbout = { [weak self] in self?.openSettings(tab: .about) }
        statusBar.onShowTutorial = { [weak self] in self?.showOnboarding() }
        statusBarController = statusBar

        hotkeyManager = HotkeyManager(statusBar: statusBar)

        installDebugHooks()

        if preferences.hasCompletedOnboarding {
            // Give the status item windows time to attach and lay out before
            // the ordering sanity check that guards a startup collapse.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                statusBar.applyStartBehavior()
            }
        } else {
            showOnboarding()
        }

        Log.app.info("Tuck launched")
        Log.trace("launched; hasCompletedOnboarding=\(preferences.hasCompletedOnboarding)")
    }

    // MARK: - Windows

    func openSettings(tab: SettingsTab = .general) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(preferences: preferences)
        }
        settingsWindowController?.show(tab: tab)
    }

    func showOnboarding() {
        if onboardingWindowController == nil {
            onboardingWindowController = OnboardingWindowController(
                preferences: preferences,
                onFinished: { [weak self] in
                    guard let self else { return }
                    preferences.hasCompletedOnboarding = true
                    statusBarController?.applyStartBehavior()
                }
            )
        }
        onboardingWindowController?.show()
    }

    // MARK: - Debug hooks

    /// Debug-only distributed notifications so the app can be driven from
    /// the command line during development and CI-style verification:
    ///   swift -e 'import Foundation; DistributedNotificationCenter.default()
    ///     .postNotificationName(.init("com.tonmoybishwas.tuck.debug.toggle"),
    ///                           object: nil, userInfo: nil,
    ///                           deliverImmediately: true)'
    private func installDebugHooks() {
        #if DEBUG
        let center = DistributedNotificationCenter.default()
        center.addObserver(
            forName: Notification.Name("com.tonmoybishwas.tuck.debug.toggle"),
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                AppDelegate.shared?.statusBarController?.toggle()
            }
        }
        center.addObserver(
            forName: Notification.Name("com.tonmoybishwas.tuck.debug.openSettings"),
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                AppDelegate.shared?.openSettings()
            }
        }
        center.addObserver(
            forName: Notification.Name("com.tonmoybishwas.tuck.debug.peek"),
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                AppDelegate.shared?.statusBarController?.expand(peekAlwaysHidden: true)
            }
        }
        center.addObserver(
            forName: Notification.Name("com.tonmoybishwas.tuck.debug.dump"),
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                var dump = AppDelegate.shared?.statusBarController?.debugDescriptionText() ?? "no status bar controller"
                dump += "\nhasCompletedOnboarding=\(Preferences.shared.hasCompletedOnboarding)"
                for window in NSApp.windows {
                    dump += "\nwindow: \(window.title.isEmpty ? String(describing: type(of: window)) : window.title) frame=\(window.frame) visible=\(window.isVisible)"
                }
                try? dump.write(toFile: "/tmp/tuck-debug-dump.txt", atomically: true, encoding: .utf8)
            }
        }
        #endif
    }
}

import AppKit
import Combine

enum StartBehavior: String, CaseIterable, Identifiable {
    case remember
    case collapsed
    case expanded

    var id: String { rawValue }

    var label: String {
        switch self {
        case .remember: "Remember last state"
        case .collapsed: "Start tucked away"
        case .expanded: "Start expanded"
        }
    }
}

/// Single source of truth for user preferences, shared between the AppKit
/// status bar machinery and the SwiftUI settings/onboarding views.
@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    private enum Key {
        static let isCollapsed = "isCollapsed"
        static let startBehavior = "startBehavior"
        static let autoRehideEnabled = "autoRehideEnabled"
        static let autoRehideDelay = "autoRehideDelay"
        static let collapseOnOutsideClick = "collapseOnOutsideClick"
        static let hoverToReveal = "hoverToReveal"
        static let alwaysHiddenEnabled = "alwaysHiddenEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    @Published var isCollapsed: Bool {
        didSet { defaults.set(isCollapsed, forKey: Key.isCollapsed) }
    }
    @Published var startBehavior: StartBehavior {
        didSet { defaults.set(startBehavior.rawValue, forKey: Key.startBehavior) }
    }
    @Published var autoRehideEnabled: Bool {
        didSet { defaults.set(autoRehideEnabled, forKey: Key.autoRehideEnabled) }
    }
    /// Seconds until revealed items tuck themselves away again (2...120).
    @Published var autoRehideDelay: Double {
        didSet { defaults.set(autoRehideDelay, forKey: Key.autoRehideDelay) }
    }
    @Published var collapseOnOutsideClick: Bool {
        didSet { defaults.set(collapseOnOutsideClick, forKey: Key.collapseOnOutsideClick) }
    }
    @Published var hoverToReveal: Bool {
        didSet { defaults.set(hoverToReveal, forKey: Key.hoverToReveal) }
    }
    @Published var alwaysHiddenEnabled: Bool {
        didSet { defaults.set(alwaysHiddenEnabled, forKey: Key.alwaysHiddenEnabled) }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Key.hasCompletedOnboarding) }
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.isCollapsed: false,
            Key.startBehavior: StartBehavior.remember.rawValue,
            Key.autoRehideEnabled: true,
            Key.autoRehideDelay: 15.0,
            Key.collapseOnOutsideClick: true,
            Key.hoverToReveal: false,
            // Opt-in: enabling this inflates a second divider, which would
            // swallow every pre-existing icon to its left on first launch.
            Key.alwaysHiddenEnabled: false,
            Key.hasCompletedOnboarding: false,
        ])
        isCollapsed = defaults.bool(forKey: Key.isCollapsed)
        startBehavior = StartBehavior(rawValue: defaults.string(forKey: Key.startBehavior) ?? "") ?? .remember
        autoRehideEnabled = defaults.bool(forKey: Key.autoRehideEnabled)
        autoRehideDelay = defaults.double(forKey: Key.autoRehideDelay)
        collapseOnOutsideClick = defaults.bool(forKey: Key.collapseOnOutsideClick)
        hoverToReveal = defaults.bool(forKey: Key.hoverToReveal)
        alwaysHiddenEnabled = defaults.bool(forKey: Key.alwaysHiddenEnabled)
        hasCompletedOnboarding = defaults.bool(forKey: Key.hasCompletedOnboarding)
    }
}

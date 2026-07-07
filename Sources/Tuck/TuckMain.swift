import AppKit

@main
@MainActor
struct TuckMain {
    // NSApplication.delegate is weak; hold the delegate strongly for the
    // app's whole lifetime or it (and the status items it owns) would be
    // deallocated once this reference goes out of scope.
    private static let delegate = AppDelegate()

    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        // Menu-bar-only app. Also covers `swift run` during development,
        // where there is no bundle Info.plist to declare LSUIElement.
        app.setActivationPolicy(.accessory)
        app.run()
    }
}

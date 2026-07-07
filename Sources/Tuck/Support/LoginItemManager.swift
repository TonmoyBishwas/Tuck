import AppKit
import ServiceManagement

/// Wraps SMAppService for the launch-at-login toggle. Note: registration is
/// tied to the app's bundle path, so it only behaves sensibly once Tuck is
/// installed in /Applications (running from a build directory would register
/// the build product).
@MainActor
final class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()

    @Published var isEnabled: Bool = SMAppService.mainApp.status == .enabled

    var requiresApproval: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Log.app.error("Login item change failed: \(error.localizedDescription)")
        }
        refresh()
    }

    func refresh() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
}

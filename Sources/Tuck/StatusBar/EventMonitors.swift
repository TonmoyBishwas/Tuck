import AppKit

/// Global NSEvent monitors used for click-outside-to-collapse and
/// hover-to-reveal. Global monitors never receive events destined for our
/// own app and require no privacy permissions for mouse events.
@MainActor
final class EventMonitors {
    private var outsideClickMonitor: Any?
    private var hoverMonitor: Any?
    private var lastHoverTrigger: Date = .distantPast

    func startOutsideClick(onClick: @escaping @MainActor (NSEvent) -> Void) {
        stopOutsideClick()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { event in
            MainActor.assumeIsolated { onClick(event) }
        }
    }

    func stopOutsideClick() {
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }

    func startHover(onMenuBarHover: @escaping @MainActor () -> Void) {
        stopHover()
        hoverMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            MainActor.assumeIsolated {
                guard Self.mouseIsInMenuBar() else { return }
                let now = Date()
                guard now.timeIntervalSince(self.lastHoverTrigger) > 1.0 else { return }
                self.lastHoverTrigger = now
                onMenuBarHover()
            }
        }
    }

    func stopHover() {
        if let monitor = hoverMonitor {
            NSEvent.removeMonitor(monitor)
            hoverMonitor = nil
        }
    }

    static func mouseIsInMenuBar() -> Bool {
        let location = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(location, $0.frame, false) })
        else { return false }
        // The band above the visible frame is the menu bar (plus the notch
        // region on notched displays, which is fine for our purposes).
        return location.y > screen.visibleFrame.maxY
    }
}

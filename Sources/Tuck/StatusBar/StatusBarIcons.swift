import AppKit

/// All menu bar images must be template images: the Tahoe menu bar is fully
/// transparent by default, so only template rendering stays legible over any
/// wallpaper in both light and dark appearances.
@MainActor
enum StatusBarIcons {
    static let collapsed: NSImage = symbol("chevron.left", description: "Show hidden items")
    static let expanded: NSImage = symbol("chevron.right", description: "Hide items")

    /// Solid vertical line marking the boundary of the hidden section.
    static let separator: NSImage = line(dashed: false)

    /// Dashed line marking the boundary of the always-hidden section.
    static let alwaysHiddenSeparator: NSImage = line(dashed: true)

    private static func symbol(_ name: String, description: String) -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: description)!
            .withSymbolConfiguration(config)!
        image.isTemplate = true
        return image
    }

    private static func line(dashed: Bool) -> NSImage {
        let size = NSSize(width: 3, height: 14)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath()
            path.lineWidth = 1.5
            path.lineCapStyle = .round
            if dashed {
                let pattern: [CGFloat] = [3, 3]
                path.setLineDash(pattern, count: pattern.count, phase: 0)
            }
            path.move(to: NSPoint(x: rect.midX, y: rect.minY + 1))
            path.line(to: NSPoint(x: rect.midX, y: rect.maxY - 1))
            NSColor.black.withAlphaComponent(dashed ? 0.5 : 0.8).setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }
}

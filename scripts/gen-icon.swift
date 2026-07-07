#!/usr/bin/env swift
// Generates the 1024x1024 Tuck app icon PNG.
// Usage: swift scripts/gen-icon.swift /path/to/out.png
//
// Design: a deep indigo->midnight gradient squircle. Across the middle, a
// "tucking" motif: two ghost dots sliding behind a glass panel, a bold white
// chevron, and two solid dots — menu bar icons disappearing behind Tuck.

import AppKit

guard CommandLine.arguments.count == 2 else {
    print("usage: swift scripts/gen-icon.swift <out.png>")
    exit(1)
}
let outPath = CommandLine.arguments[1]

let canvas: CGFloat = 1024
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(canvas), pixelsHigh: Int(canvas),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background squircle (macOS icon grid: ~100pt margin, ~185pt corner radius)
let margin: CGFloat = 100
let bgRect = NSRect(x: margin, y: margin, width: canvas - 2 * margin, height: canvas - 2 * margin)
let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: 185, yRadius: 185)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.32, green: 0.30, blue: 0.85, alpha: 1.0), // indigo
    NSColor(calibratedRed: 0.10, green: 0.08, blue: 0.30, alpha: 1.0), // midnight
])!
gradient.draw(in: bgPath, angle: -90)

// Subtle top sheen for depth
let sheenRect = NSRect(x: margin, y: canvas / 2, width: canvas - 2 * margin, height: canvas / 2 - margin)
let sheenPath = NSBezierPath(roundedRect: sheenRect, xRadius: 185, yRadius: 185)
NSGradient(colors: [
    NSColor.white.withAlphaComponent(0.16),
    NSColor.white.withAlphaComponent(0.0),
])!.draw(in: sheenPath, angle: -90)

let midY = canvas / 2
let dotRadius: CGFloat = 52

func dot(x: CGFloat, alpha: CGFloat) {
    let rect = NSRect(x: x - dotRadius, y: midY - dotRadius, width: dotRadius * 2, height: dotRadius * 2)
    NSColor.white.withAlphaComponent(alpha).setFill()
    NSBezierPath(ovalIn: rect).fill()
}

// Glass panel on the left: where icons get tucked away
let panelRect = NSRect(x: margin + 40, y: midY - 150, width: 260, height: 300)
let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 60, yRadius: 60)
NSColor.white.withAlphaComponent(0.14).setFill()
panelPath.fill()
NSColor.white.withAlphaComponent(0.28).setStroke()
panelPath.lineWidth = 6
panelPath.stroke()

// Ghost dots inside the panel (tucked-away icons)
dot(x: panelRect.midX - 60, alpha: 0.30)
dot(x: panelRect.midX + 60, alpha: 0.30)

// Bold chevron pointing left (the Tuck toggle)
let chevron = NSBezierPath()
chevron.lineWidth = 58
chevron.lineCapStyle = .round
chevron.lineJoinStyle = .round
let chevronTipX = panelRect.maxX + 70
let chevronSpan: CGFloat = 96
chevron.move(to: NSPoint(x: chevronTipX + chevronSpan, y: midY + 120))
chevron.line(to: NSPoint(x: chevronTipX, y: midY))
chevron.line(to: NSPoint(x: chevronTipX + chevronSpan, y: midY - 120))
NSColor.white.setStroke()
chevron.stroke()

// Solid dots on the right (still-visible icons)
dot(x: chevronTipX + chevronSpan + 130, alpha: 1.0)
dot(x: chevronTipX + chevronSpan + 280, alpha: 1.0)

NSGraphicsContext.restoreGraphicsState()

let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")

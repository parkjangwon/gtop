import AppKit
import Foundation

struct IconSpec {
    let filename: String
    let pixels: Int
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "")
guard !outputDirectory.path.isEmpty else {
    fputs("Usage: swift generate_app_icon.swift <output-directory>\n", stderr)
    exit(1)
}

let specs: [IconSpec] = [
    .init(filename: "icon_16x16.png", pixels: 16),
    .init(filename: "icon_16x16@2x.png", pixels: 32),
    .init(filename: "icon_32x32.png", pixels: 32),
    .init(filename: "icon_32x32@2x.png", pixels: 64),
    .init(filename: "icon_128x128.png", pixels: 128),
    .init(filename: "icon_128x128@2x.png", pixels: 256),
    .init(filename: "icon_256x256.png", pixels: 256),
    .init(filename: "icon_256x256@2x.png", pixels: 512),
    .init(filename: "icon_512x512.png", pixels: 512),
    .init(filename: "icon_512x512@2x.png", pixels: 1024)
]

try FileManager.default.createDirectory(
    at: outputDirectory,
    withIntermediateDirectories: true
)

for spec in specs {
    let image = NSImage(size: NSSize(width: spec.pixels, height: spec.pixels))
    image.lockFocus()
    drawIcon(in: NSRect(x: 0, y: 0, width: spec.pixels, height: spec.pixels))
    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        fputs("Failed to encode \(spec.filename)\n", stderr)
        exit(1)
    }

    try pngData.write(to: outputDirectory.appendingPathComponent(spec.filename))
}

private func drawIcon(in rect: NSRect) {
    NSColor.clear.setFill()
    rect.fill()

    let iconRect = rect.insetBy(dx: rect.width * 0.12, dy: rect.height * 0.12)
    let iconPath = NSBezierPath(
        roundedRect: iconRect,
        xRadius: rect.width * 0.2,
        yRadius: rect.width * 0.2
    )
    NSColor.black.setFill()
    iconPath.fill()

    iconPath.lineWidth = max(1, rect.width * 0.01)
    NSColor(calibratedWhite: 1, alpha: 0.14).setStroke()
    iconPath.stroke()

    let screenRect = iconRect.insetBy(dx: rect.width * 0.11, dy: rect.height * 0.14)
    let screenPath = NSBezierPath(
        roundedRect: screenRect,
        xRadius: rect.width * 0.055,
        yRadius: rect.width * 0.055
    )
    screenPath.lineWidth = max(2, rect.width * 0.02)
    NSColor.white.setStroke()
    screenPath.stroke()

    drawWave(in: screenRect, canvas: rect)
}

private func drawWave(in screenRect: NSRect, canvas: NSRect) {
    let path = NSBezierPath()
    path.lineJoinStyle = .round
    path.lineCapStyle = .round
    path.lineWidth = max(2, canvas.width * 0.018)

    let horizontalInset = screenRect.width * 0.12
    let baseX = screenRect.minX + horizontalInset
    let width = screenRect.width - horizontalInset * 2
    let midY = screenRect.midY
    let amplitude = screenRect.height * 0.24

    let points: [CGPoint] = [
        .init(x: 0.00, y: 0.00),
        .init(x: 0.14, y: 0.00),
        .init(x: 0.24, y: 0.18),
        .init(x: 0.34, y: -0.28),
        .init(x: 0.46, y: 0.56),
        .init(x: 0.56, y: -0.12),
        .init(x: 0.70, y: 0.10),
        .init(x: 0.84, y: -0.06),
        .init(x: 1.00, y: -0.06)
    ]

    for (index, point) in points.enumerated() {
        let mapped = CGPoint(
            x: baseX + width * point.x,
            y: midY + amplitude * point.y
        )
        if index == 0 {
            path.move(to: mapped)
        } else {
            path.line(to: mapped)
        }
    }

    NSColor.white.setStroke()
    path.stroke()
}

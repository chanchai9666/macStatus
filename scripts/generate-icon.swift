import AppKit
import CoreGraphics

func degreeToRadian(_ deg: CGFloat) -> CGFloat {
    return deg * .pi / 180.0
}

func drawArc(
    in context: CGContext,
    center: CGPoint,
    radius: CGFloat,
    lineWidth: CGFloat,
    startAngleDeg: CGFloat,
    endAngleDeg: CGFloat,
    startColor: NSColor,
    endColor: NSColor,
    glowColor: NSColor
) {
    context.saveGState()

    // Background track ring
    context.setStrokeColor(startColor.withAlphaComponent(0.18).cgColor)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.addArc(
        center: center,
        radius: radius,
        startAngle: 0,
        endAngle: 2 * .pi,
        clockwise: false
    )
    context.strokePath()

    // Draw Glowing Active Arc
    let path = CGMutablePath()
    let startRad = degreeToRadian(startAngleDeg)
    let endRad = degreeToRadian(endAngleDeg)
    path.addArc(
        center: center,
        radius: radius,
        startAngle: startRad,
        endAngle: endRad,
        clockwise: false
    )

    // Glow layer
    context.saveGState()
    context.setShadow(offset: .zero, blur: lineWidth * 0.75, color: glowColor.withAlphaComponent(0.65).cgColor)
    context.addPath(path)
    context.setStrokeColor(glowColor.cgColor)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.strokePath()
    context.restoreGState()

    // Main sharp arc
    context.saveGState()
    context.addPath(path)
    context.setStrokeColor(startColor.cgColor)
    context.setLineWidth(lineWidth)
    context.setLineCap(.round)
    context.strokePath()
    context.restoreGState()

    context.restoreGState()
}

func renderMasterIcon(size: CGFloat = 1024) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high

    let center = CGPoint(x: size / 2.0, y: size / 2.0)

    // 1. macOS Squircle Drop Shadow & Base Frame
    // Standard macOS HIG canvas: 1024x1024, icon body is ~824x824 offset slightly upwards
    let iconBodySize: CGFloat = 824.0
    let iconOrigin = CGPoint(x: (size - iconBodySize) / 2.0, y: (size - iconBodySize) / 2.0 - 15.0)
    let iconRect = CGRect(origin: iconOrigin, size: CGSize(width: iconBodySize, height: iconBodySize))
    let cornerRadius: CGFloat = 185.0

    let squirclePath = CGPath(roundedRect: iconRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Draw deep realistic macOS drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -28), blur: 36, color: NSColor.black.withAlphaComponent(0.48).cgColor)
    ctx.setFillColor(NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0).cgColor)
    ctx.addPath(squirclePath)
    ctx.fillPath()
    ctx.restoreGState()

    // Clip to Squircle for interior artwork
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    // 2. Base Dark Titanium Gradient Background
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.14, green: 0.16, blue: 0.21, alpha: 1.0).cgColor,
        NSColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0).cgColor,
        NSColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0).cgColor
    ] as CFArray
    let bgLocations: [CGFloat] = [0.0, 0.6, 1.0]
    if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: bgLocations) {
        ctx.drawLinearGradient(
            bgGradient,
            start: CGPoint(x: center.x, y: iconRect.maxY),
            end: CGPoint(x: center.x, y: iconRect.minY),
            options: []
        )
    }

    // Radial subtle blue-cyan backlight ambiance
    let radialColors = [
        NSColor(red: 0.04, green: 0.18, blue: 0.35, alpha: 0.35).cgColor,
        NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0).cgColor
    ] as CFArray
    if let radialGradient = CGGradient(colorsSpace: colorSpace, colors: radialColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            radialGradient,
            startCenter: center,
            startRadius: 40,
            endCenter: center,
            endRadius: 420,
            options: []
        )
    }

    // 3. Apple Silicon Chip Substrate
    let chipCenter = CGPoint(x: center.x, y: center.y - 15.0)
    let chipSize: CGFloat = 520.0
    let chipRect = CGRect(
        x: chipCenter.x - chipSize / 2.0,
        y: chipCenter.y - chipSize / 2.0,
        width: chipSize,
        height: chipSize
    )
    let chipRadius: CGFloat = 32.0
    let chipPath = CGPath(roundedRect: chipRect, cornerWidth: chipRadius, cornerHeight: chipRadius, transform: nil)

    // Chip shadow & base
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10), blur: 24, color: NSColor.black.withAlphaComponent(0.65).cgColor)
    ctx.setFillColor(NSColor(red: 0.07, green: 0.08, blue: 0.10, alpha: 0.95).cgColor)
    ctx.addPath(chipPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Chip substrate gradient
    ctx.saveGState()
    ctx.addPath(chipPath)
    ctx.clip()

    let chipColors = [
        NSColor(red: 0.12, green: 0.13, blue: 0.16, alpha: 1.0).cgColor,
        NSColor(red: 0.06, green: 0.07, blue: 0.09, alpha: 1.0).cgColor
    ] as CFArray
    if let chipGrad = CGGradient(colorsSpace: colorSpace, colors: chipColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(chipGrad, start: CGPoint(x: chipCenter.x, y: chipRect.maxY), end: CGPoint(x: chipCenter.x, y: chipRect.minY), options: [])
    }

    // Golden Micro-pins around the chip perimeter
    let pinCount = 14
    let pinWidth: CGFloat = 16.0
    let pinHeight: CGFloat = 6.0
    let pinSpacing: CGFloat = (chipSize - 100) / CGFloat(pinCount - 1)
    let goldColor = NSColor(red: 0.88, green: 0.74, blue: 0.42, alpha: 0.85)

    ctx.setFillColor(goldColor.cgColor)
    for i in 0..<pinCount {
        let offset = (chipCenter.x - (chipSize - 100) / 2.0) + CGFloat(i) * pinSpacing - pinWidth / 2.0
        // Top edge pins
        ctx.fill(CGRect(x: offset, y: chipRect.maxY - pinHeight, width: pinWidth, height: pinHeight))
        // Bottom edge pins
        ctx.fill(CGRect(x: offset, y: chipRect.minY, width: pinWidth, height: pinHeight))
        // Left edge pins
        ctx.fill(CGRect(x: chipRect.minX, y: (chipCenter.y - (chipSize - 100) / 2.0) + CGFloat(i) * pinSpacing - pinWidth / 2.0, width: pinHeight, height: pinWidth))
        // Right edge pins
        ctx.fill(CGRect(x: chipRect.maxX - pinHeight, y: (chipCenter.y - (chipSize - 100) / 2.0) + CGFloat(i) * pinSpacing - pinWidth / 2.0, width: pinHeight, height: pinWidth))
    }

    // Subtle hardware PCB circuit grid traces
    ctx.setStrokeColor(NSColor(red: 0.18, green: 0.22, blue: 0.30, alpha: 0.45).cgColor)
    ctx.setLineWidth(1.5)
    for i in 1...4 {
        let gridOffset = CGFloat(i) * 55.0
        // Horizontal traces
        ctx.move(to: CGPoint(x: chipRect.minX + 30, y: chipCenter.y + gridOffset))
        ctx.addLine(to: CGPoint(x: chipRect.maxX - 30, y: chipCenter.y + gridOffset))
        ctx.move(to: CGPoint(x: chipRect.minX + 30, y: chipCenter.y - gridOffset))
        ctx.addLine(to: CGPoint(x: chipRect.maxX - 30, y: chipCenter.y - gridOffset))
        // Vertical traces
        ctx.move(to: CGPoint(x: chipCenter.x + gridOffset, y: chipRect.minY + 30))
        ctx.addLine(to: CGPoint(x: chipCenter.x + gridOffset, y: chipRect.maxY - 30))
        ctx.move(to: CGPoint(x: chipCenter.x - gridOffset, y: chipRect.minY + 30))
        ctx.addLine(to: CGPoint(x: chipCenter.x - gridOffset, y: chipRect.maxY - 30))
    }
    ctx.strokePath()

    // Chip subtle border
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.12).cgColor)
    ctx.setLineWidth(2.0)
    ctx.addPath(chipPath)
    ctx.strokePath()

    ctx.restoreGState() // End chip clip

    // 4. The 3 Signature Telemetry Activity Rings
    // Ring 1 (Outer - CPU): Electric Blue
    drawArc(
        in: ctx,
        center: chipCenter,
        radius: 185.0,
        lineWidth: 26.0,
        startAngleDeg: 120,
        endAngleDeg: 380, // ~260 deg arc
        startColor: NSColor(red: 10/255, green: 132/255, blue: 255/255, alpha: 1.0),
        endColor: NSColor(red: 0/255, green: 198/255, blue: 255/255, alpha: 1.0),
        glowColor: NSColor(red: 10/255, green: 145/255, blue: 255/255, alpha: 0.9)
    )

    // Ring 2 (Middle - RAM Unified Memory): Emerald Neon Green
    drawArc(
        in: ctx,
        center: chipCenter,
        radius: 145.0,
        lineWidth: 24.0,
        startAngleDeg: 210,
        endAngleDeg: 430, // ~220 deg arc
        startColor: NSColor(red: 48/255, green: 209/255, blue: 88/255, alpha: 1.0),
        endColor: NSColor(red: 52/255, green: 199/255, blue: 89/255, alpha: 1.0),
        glowColor: NSColor(red: 48/255, green: 215/255, blue: 95/255, alpha: 0.9)
    )

    // Ring 3 (Inner - Storage / Thermal): Sunset Vivid Orange
    drawArc(
        in: ctx,
        center: chipCenter,
        radius: 105.0,
        lineWidth: 22.0,
        startAngleDeg: 300,
        endAngleDeg: 470, // ~170 deg arc
        startColor: NSColor(red: 255/255, green: 159/255, blue: 10/255, alpha: 1.0),
        endColor: NSColor(red: 255/255, green: 69/255, blue: 58/255, alpha: 1.0),
        glowColor: NSColor(red: 255/255, green: 145/255, blue: 0/255, alpha: 0.9)
    )

    // 5. Center Core Icon Emblem: Geometric "M" Silicon Core with Telemetry Wave
    ctx.saveGState()
    let mPath = CGMutablePath()
    let mScale: CGFloat = 1.15
    let mcx = chipCenter.x
    let mcy = chipCenter.y

    // Bespoke modern M-Architecture telemetry crest
    // Left leg
    mPath.move(to: CGPoint(x: mcx - 42 * mScale, y: mcy - 30 * mScale))
    mPath.addLine(to: CGPoint(x: mcx - 42 * mScale, y: mcy + 30 * mScale))
    mPath.addLine(to: CGPoint(x: mcx - 26 * mScale, y: mcy + 30 * mScale))
    mPath.addLine(to: CGPoint(x: mcx - 1 * mScale, y: mcy - 10 * mScale))
    mPath.addLine(to: CGPoint(x: mcx + 1 * mScale, y: mcy - 10 * mScale))
    mPath.addLine(to: CGPoint(x: mcx + 26 * mScale, y: mcy + 30 * mScale))
    mPath.addLine(to: CGPoint(x: mcx + 42 * mScale, y: mcy + 30 * mScale))
    mPath.addLine(to: CGPoint(x: mcx + 42 * mScale, y: mcy - 30 * mScale))
    mPath.addLine(to: CGPoint(x: mcx + 28 * mScale, y: mcy - 30 * mScale))
    mPath.addLine(to: CGPoint(x: mcx + 28 * mScale, y: mcy + 10 * mScale))
    mPath.addLine(to: CGPoint(x: mcx + 10 * mScale, y: mcy - 18 * mScale))
    mPath.addLine(to: CGPoint(x: mcx - 10 * mScale, y: mcy - 18 * mScale))
    mPath.addLine(to: CGPoint(x: mcx - 28 * mScale, y: mcy + 10 * mScale))
    mPath.addLine(to: CGPoint(x: mcx - 28 * mScale, y: mcy - 30 * mScale))
    mPath.closeSubpath()

    // Glow under center crest
    ctx.setShadow(offset: .zero, blur: 20, color: NSColor(red: 0.2, green: 0.8, blue: 1.0, alpha: 0.7).cgColor)
    ctx.setFillColor(NSColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 0.95).cgColor)
    ctx.addPath(mPath)
    ctx.fillPath()
    ctx.restoreGState()

    // Central pulsing status point inside the M crest
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: 12, color: NSColor(red: 48/255, green: 209/255, blue: 88/255, alpha: 0.9).cgColor)
    ctx.setFillColor(NSColor(red: 48/255, green: 209/255, blue: 88/255, alpha: 1.0).cgColor)
    ctx.fillEllipse(in: CGRect(x: mcx - 5.5, y: mcy - 30, width: 11, height: 11))
    ctx.restoreGState()

    // 6. Realistic Glass Highlight / Bezel Reflection on Squircle Rim
    ctx.setStrokeColor(NSColor(white: 1.0, alpha: 0.22).cgColor)
    ctx.setLineWidth(3.0)
    ctx.addPath(squirclePath)
    ctx.strokePath()

    // Inner rim light gradient
    let rimColors = [
        NSColor(white: 1.0, alpha: 0.28).cgColor,
        NSColor(white: 1.0, alpha: 0.02).cgColor,
        NSColor(white: 0.0, alpha: 0.45).cgColor
    ] as CFArray
    if let rimGrad = CGGradient(colorsSpace: colorSpace, colors: rimColors, locations: [0.0, 0.4, 1.0]) {
        ctx.saveGState()
        let innerRect = iconRect.insetBy(dx: 3, dy: 3)
        let innerPath = CGPath(roundedRect: innerRect, cornerWidth: cornerRadius - 3, cornerHeight: cornerRadius - 3, transform: nil)
        ctx.addPath(squirclePath)
        ctx.addPath(innerPath)
        ctx.clip(using: .evenOdd)
        ctx.drawLinearGradient(rimGrad, start: CGPoint(x: center.x, y: iconRect.maxY), end: CGPoint(x: center.x, y: iconRect.minY), options: [])
        ctx.restoreGState()
    }

    ctx.restoreGState() // End squircle clip

    image.unlockFocus()
    return image
}

func generateIconset() {
    let fileManager = FileManager.default
    let currentDir = fileManager.currentDirectoryPath
    let iconsetDir = "\(currentDir)/build/AppIcon.iconset"
    let resourcesDir = "\(currentDir)/Resources"
    let icnsPath = "\(resourcesDir)/AppIcon.icns"

    try? fileManager.removeItem(atPath: iconsetDir)
    try? fileManager.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

    print("==> Rendering 1024x1024 Master Icon Artwork...")
    let master = renderMasterIcon(size: 1024)

    let targets: [(name: String, size: Int)] = [
        ("icon_16x16.png", 16),
        ("icon_16x16@2x.png", 32),
        ("icon_32x32.png", 32),
        ("icon_32x32@2x.png", 64),
        ("icon_128x128.png", 128),
        ("icon_128x128@2x.png", 256),
        ("icon_256x256.png", 256),
        ("icon_256x256@2x.png", 512),
        ("icon_512x512.png", 512),
        ("icon_512x512@2x.png", 1024)
    ]

    for target in targets {
        let resized = NSImage(size: NSSize(width: target.size, height: target.size))
        resized.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        master.draw(
            in: NSRect(x: 0, y: 0, width: target.size, height: target.size),
            from: NSRect(x: 0, y: 0, width: 1024, height: 1024),
            operation: .copy,
            fraction: 1.0
        )
        resized.unlockFocus()

        if let tiff = resized.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let png = rep.representation(using: .png, properties: [:]) {
            let path = "\(iconsetDir)/\(target.name)"
            try? png.write(to: URL(fileURLWithPath: path))
        }
    }
    print("==> Generated \(targets.count) iconset assets.")

    // Convert iconset to icns using macOS iconutil
    print("==> Compiling AppIcon.icns via iconutil...")
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
    process.arguments = ["-c", "icns", iconsetDir, "-o", icnsPath]
    try? process.run()
    process.waitUntilExit()

    if fileManager.fileExists(atPath: icnsPath) {
        let attrs = try? fileManager.attributesOfItem(atPath: icnsPath)
        let bytes = attrs?[.size] as? Int ?? 0
        print("==> Success! \(icnsPath) created (\(bytes) bytes).")
    } else {
        print("==> Error: Failed to generate \(icnsPath)")
    }
}

generateIconset()

#!/usr/bin/env swift

import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// Background gradient - warm orange to deep yellow
let gradient = NSGradient(colors: [
    NSColor(red: 1.0, green: 0.75, blue: 0.15, alpha: 1.0),
    NSColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 1.0)
])!
gradient.draw(in: NSRect(origin: .zero, size: size), angle: -45)

// Rounded rectangle mask (iOS icon shape approximation)
let ctx = NSGraphicsContext.current!.cgContext

// Draw sun circle
let sunCenter = CGPoint(x: 512, y: 560)
let sunRadius: CGFloat = 180

// Sun rays
ctx.saveGState()
ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
ctx.setLineWidth(28)
ctx.setLineCap(.round)

let rayCount = 12
let innerRadius: CGFloat = 220
let outerRadius: CGFloat = 320

for i in 0..<rayCount {
    let angle = CGFloat(i) * (2 * .pi / CGFloat(rayCount)) - .pi / 2
    let x1 = sunCenter.x + innerRadius * cos(angle)
    let y1 = sunCenter.y + innerRadius * sin(angle)
    let x2 = sunCenter.x + outerRadius * cos(angle)
    let y2 = sunCenter.y + outerRadius * sin(angle)
    ctx.move(to: CGPoint(x: x1, y: y1))
    ctx.addLine(to: CGPoint(x: x2, y: y2))
}
ctx.strokePath()
ctx.restoreGState()

// Sun body
ctx.saveGState()
ctx.setFillColor(NSColor.white.cgColor)
ctx.addArc(center: sunCenter, radius: sunRadius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
ctx.fillPath()
ctx.restoreGState()

// UV text inside sun
let uvText = "UV" as NSString
let uvFont = NSFont.systemFont(ofSize: 140, weight: .bold)
let uvAttributes: [NSAttributedString.Key: Any] = [
    .font: uvFont,
    .foregroundColor: NSColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 1.0)
]
let uvSize = uvText.size(withAttributes: uvAttributes)
let uvPoint = CGPoint(
    x: sunCenter.x - uvSize.width / 2,
    y: sunCenter.y - uvSize.height / 2
)
uvText.draw(at: uvPoint, withAttributes: uvAttributes)

// Shield/protection indicator at bottom
let shieldCenter = CGPoint(x: 512, y: 200)
ctx.saveGState()
ctx.setFillColor(NSColor.white.withAlphaComponent(0.25).cgColor)

// Simple shield shape
let shieldPath = NSBezierPath()
shieldPath.move(to: CGPoint(x: shieldCenter.x, y: shieldCenter.y + 90))
shieldPath.curve(to: CGPoint(x: shieldCenter.x + 70, y: shieldCenter.y + 40),
                 controlPoint1: CGPoint(x: shieldCenter.x + 10, y: shieldCenter.y + 90),
                 controlPoint2: CGPoint(x: shieldCenter.x + 70, y: shieldCenter.y + 75))
shieldPath.line(to: CGPoint(x: shieldCenter.x + 70, y: shieldCenter.y - 20))
shieldPath.curve(to: CGPoint(x: shieldCenter.x, y: shieldCenter.y - 90),
                 controlPoint1: CGPoint(x: shieldCenter.x + 70, y: shieldCenter.y - 60),
                 controlPoint2: CGPoint(x: shieldCenter.x + 30, y: shieldCenter.y - 90))
shieldPath.curve(to: CGPoint(x: shieldCenter.x - 70, y: shieldCenter.y - 20),
                 controlPoint1: CGPoint(x: shieldCenter.x - 30, y: shieldCenter.y - 90),
                 controlPoint2: CGPoint(x: shieldCenter.x - 70, y: shieldCenter.y - 60))
shieldPath.line(to: CGPoint(x: shieldCenter.x - 70, y: shieldCenter.y + 40))
shieldPath.curve(to: CGPoint(x: shieldCenter.x, y: shieldCenter.y + 90),
                 controlPoint1: CGPoint(x: shieldCenter.x - 70, y: shieldCenter.y + 75),
                 controlPoint2: CGPoint(x: shieldCenter.x - 10, y: shieldCenter.y + 90))
shieldPath.fill()
ctx.restoreGState()

// Small chart line at bottom of sun (representing UV chart)
ctx.saveGState()
ctx.setStrokeColor(NSColor(red: 1.0, green: 0.55, blue: 0.05, alpha: 0.6).cgColor)
ctx.setLineWidth(6)
ctx.setLineCap(.round)
ctx.setLineJoin(.round)

let chartY: CGFloat = 430
let chartPoints: [(CGFloat, CGFloat)] = [
    (320, chartY), (400, chartY - 30), (460, chartY - 70),
    (512, chartY - 90), (564, chartY - 70), (624, chartY - 30), (704, chartY)
]
ctx.move(to: CGPoint(x: chartPoints[0].0, y: chartPoints[0].1))
for i in 1..<chartPoints.count {
    ctx.addLine(to: CGPoint(x: chartPoints[i].0, y: chartPoints[i].1))
}
ctx.strokePath()
ctx.restoreGState()

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to generate PNG")
    exit(1)
}

let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon.png"

try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("Icon saved to \(outputPath)")

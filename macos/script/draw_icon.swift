import AppKit
import Foundation

let destination = CommandLine.arguments[1]
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: r/255, green: g/255, blue: b/255, alpha: alpha)
}
func render(_ size: Int, _ filename: String) throws {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else { fatalError("No graphics context") }
    let scale = CGFloat(size)/1024
    context.scaleBy(x:scale,y:scale)
    let box = NSRect(x:82,y:82,width:860,height:860)
    let shape = NSBezierPath(roundedRect: box, xRadius: 198, yRadius: 198)
    context.saveGState()
    let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.4); shadow.shadowBlurRadius = 30; shadow.shadowOffset = NSSize(width:0,height:-12); shadow.set()
    rgb(14,13,28).setFill(); shape.fill(); context.restoreGState()
    context.saveGState(); shape.addClip()
    NSGradient(starting:rgb(15,14,30), ending:rgb(54,48,103))!.draw(in:box, angle:90)
    let glow = NSGradient(starting:rgb(107,99,210,0.50), ending:rgb(107,99,210,0))!
    glow.draw(in:NSBezierPath(ovalIn:NSRect(x:180,y:140,width:670,height:650)), relativeCenterPosition:.zero)
    context.restoreGState()
    context.saveGState()
    let bolt = NSBezierPath()
    bolt.move(to:NSPoint(x:540,y:846)); bolt.line(to:NSPoint(x:303,y:452)); bolt.curve(to:NSPoint(x:326,y:410),controlPoint1:NSPoint(x:290,y:431),controlPoint2:NSPoint(x:302,y:410)); bolt.line(to:NSPoint(x:485,y:410)); bolt.line(to:NSPoint(x:400,y:166)); bolt.curve(to:NSPoint(x:421,y:155),controlPoint1:NSPoint(x:394,y:148),controlPoint2:NSPoint(x:410,y:143)); bolt.line(to:NSPoint(x:726,y:524)); bolt.curve(to:NSPoint(x:705,y:565),controlPoint1:NSPoint(x:741,y:544),controlPoint2:NSPoint(x:728,y:565)); bolt.line(to:NSPoint(x:553,y:565)); bolt.line(to:NSPoint(x:615,y:834)); bolt.curve(to:NSPoint(x:590,y:858),controlPoint1:NSPoint(x:619,y:853),controlPoint2:NSPoint(x:606,y:863)); bolt.close()
    let boltShadow = NSShadow(); boltShadow.shadowColor=rgb(0,0,0,0.28); boltShadow.shadowBlurRadius=22; boltShadow.shadowOffset=NSSize(width:0,height:-8); boltShadow.set()
    NSGradient(starting:rgb(4,147,91),ending:rgb(143,243,151))!.draw(in:bolt,angle:90)
    context.restoreGState()
    image.unlockFocus()
    guard let tiff=image.tiffRepresentation, let rep=NSBitmapImageRep(data:tiff), let data=rep.representation(using:.png, properties:[:]) else { fatalError("PNG encoding failed") }
    try data.write(to: URL(fileURLWithPath:destination).appendingPathComponent(filename))
}
for (pixels, name) in [(16,"icon_16x16.png"),(32,"icon_16x16@2x.png"),(32,"icon_32x32.png"),(64,"icon_32x32@2x.png"),(128,"icon_128x128.png"),(256,"icon_128x128@2x.png"),(256,"icon_256x256.png"),(512,"icon_256x256@2x.png"),(512,"icon_512x512.png"),(1024,"icon_512x512@2x.png")] { try render(pixels,name) }

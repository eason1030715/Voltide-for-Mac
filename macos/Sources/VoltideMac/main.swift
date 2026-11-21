import AppKit
import IOKit
import IOKit.ps

final class Devices {
    static func apple() -> [Reading] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleDeviceManagementHIDEventService"), &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }
        var result: [Reading] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            var unmanaged: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &unmanaged, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let props = unmanaged?.takeRetainedValue() as? [String: Any],
                  let percent = props["BatteryPercent"] as? Int, (0...100).contains(percent) else { continue }
            let category = (props["Accessory Category"] as? String) ?? "Accessory"
            let model: String
            switch category.lowercased() {
            case "keyboard": model = "Keyboard"
            case "mouse": model = "Mouse"
            case "trackpad": model = "Trackpad"
            default: model = category
            }
            let id = (props["SerialNumber"] as? String) ?? "apple-\(model)"
            result.append(Reading(id: id, brand: "APPLE", model: model, percent: percent, detail: "Bluetooth", updated: Date()))
        }
        if let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(), let sources = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef] {
            for source in sources {
                guard let info = IOPSGetPowerSourceDescription(blob, source)?.takeUnretainedValue() as? [String: Any],
                      (info[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType,
                      let current = info[kIOPSCurrentCapacityKey] as? Int, let max = info[kIOPSMaxCapacityKey] as? Int, max > 0 else { continue }
                result.append(Reading(id: "internal-battery", brand: "APPLE", model: "Mac", percent: current * 100 / max, detail: "Mac Battery", updated: Date()))
            }
        }
        return result.sorted { $0.model < $1.model }
    }
}

final class PanelView: NSView {
    var readings: [Reading] = [] {
        didSet {
            scrollPosition = min(scrollPosition, maxScroll)
            scrollTarget = min(scrollTarget, maxScroll)
            if let window { updateHover(window.mouseLocationOutsideOfEventStream) }
            needsDisplay = true
        }
    }
    var interval = UserDefaults.standard.integer(forKey: "interval") == 0 ? 90 : UserDefaults.standard.integer(forKey: "interval")
    var refresh: (() -> Void)?
    var onInterval: ((Int) -> Void)?
    private var hoverID: String?
    private var hoverTimer: Timer?
    private var tracking: NSTrackingArea?
    override func updateTrackingAreas() {
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: .zero, options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area); tracking = area
        super.updateTrackingAreas()
    }
    override func mouseEntered(with event: NSEvent) { updateHover(event.locationInWindow) }
    override func mouseMoved(with event: NSEvent) { updateHover(event.locationInWindow) }
    override func mouseExited(with event: NSEvent) { setHover(nil) }
    private func updateHover(_ location: NSPoint) {
        let point = convert(location, from: nil)
        let x = point.x * 941 / bounds.width, y = point.y * 573 / bounds.height
        guard y >= 152 && y <= 452 else { setHover(nil); return }
        let count = min(3, readings.count)
        let start = (941 - CGFloat(count)*220 - CGFloat(max(0,count-1))*29)/2
        let index = Int(floor((x - start + scrollPosition) / 249))
        guard index >= 0 && index < readings.count else { setHover(nil); return }
        let localX = x - (start + CGFloat(index)*249 - scrollPosition)
        let reading = readings[index]
        let canAnimate = !reading.sleeping && reading.percent.map { $0 > 0 && $0 < 100 } == true
        setHover((0...220).contains(localX) && canAnimate ? reading.id : nil)
    }
    private func setHover(_ id: String?) {
        guard hoverID != id else { return }
        hoverID = id
        if id == nil { hoverTimer?.invalidate(); hoverTimer = nil }
        else if hoverTimer == nil {
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0/30.0, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                self.needsDisplay = true
            }
        }
        needsDisplay = true
    }
    private var scrollPosition: CGFloat = 0
    private var scrollTarget: CGFloat = 0
    private var scrollTimer: Timer?
    private var maxScroll: CGFloat { CGFloat(max(0, readings.count - 3)) * 249 }
    private func animateScroll() {
        guard scrollTimer == nil else { return }
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let difference = self.scrollTarget - self.scrollPosition
            if abs(difference) < 0.3 {
                self.scrollPosition = self.scrollTarget
                timer.invalidate(); self.scrollTimer = nil
            } else {
                self.scrollPosition += difference * 0.22
            }
            if let window = self.window { self.updateHover(window.mouseLocationOutsideOfEventStream) }
            self.needsDisplay = true
        }
    }
    override var isFlipped: Bool { true }
    func color(_ r: CGFloat,_ g: CGFloat,_ b: CGFloat,_ a: CGFloat = 1) -> NSColor { NSColor(calibratedRed:r/255, green:g/255, blue:b/255, alpha:a) }
    func label(_ s:String,_ x:CGFloat,_ y:CGFloat,_ size:CGFloat,_ c:NSColor,_ weight:NSFont.Weight = .regular) {
        let font = NSFont.systemFont(ofSize:size, weight:weight)
        s.draw(at: NSPoint(x:x,y:y), withAttributes:[.font:font,.foregroundColor:c])
    }
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let sx = bounds.width/941, sy = bounds.height/573
        ctx.saveGState(); ctx.scaleBy(x:sx,y:sy)
        color(0,0,0).setFill(); NSRect(x:0,y:0,width:941,height:573).fill()
        let colors = [color(64,58,132,0.85).cgColor, color(0,0,0,0).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1]) {
            ctx.saveGState(); ctx.translateBy(x:470.5,y:286); ctx.scaleBy(x:1,y:0.63)
            ctx.drawRadialGradient(gradient, startCenter:.zero,startRadius:0,endCenter:.zero,endRadius:559,options:.drawsAfterEndLocation); ctx.restoreGState()
        }
        label("VOLTIDE",44,31,34,color(242,242,242),.semibold)
        label("for Mac",205,44,15,color(155,155,155),.medium)
        label("⟲",775,23,44,color(155,155,155)); label("×",856,24,46,color(155,155,155),.light)
        let count = readings.count
        if count == 0 { label("未找到設備",400,275,18,color(150,150,150)) }
        let shownCount = min(3, count)
        let start = (941 - CGFloat(shownCount)*220 - CGFloat(max(0,shownCount-1))*29)/2
        ctx.saveGState()
        ctx.clip(to: CGRect(x: 0, y: 152, width: 941, height: 300))
        for (i, reading) in readings.enumerated() {
            let x = start + CGFloat(i)*249 - scrollPosition
            if x + 220 >= 0 && x <= 941 { card(reading, x, 152, ctx) }
        }
        ctx.restoreGState()
        for (i,n) in [15,30,90].enumerated() { label(n == interval ? "◉ \(n)s" : "◯ \(n)s", CGFloat(380+i*70), 515, 14, n == interval ? color(116,221,124) : color(135,135,135)) }
        ctx.restoreGState()
    }
    func card(_ r:Reading,_ x:CGFloat,_ y:CGFloat,_ ctx:CGContext) {
        ctx.saveGState(); ctx.translateBy(x:x,y:y)
        let rect = NSRect(x:0,y:0,width:220,height:300), round = NSBezierPath(roundedRect: rect,xRadius:30,yRadius:30)
        color(15,15,15).setFill(); round.fill(); round.addClip()
        color(30,30,30).setStroke(); let grid = NSBezierPath(); grid.lineWidth = 0.6
        for x in stride(from: 22, through: 220, by: 44) { grid.move(to:NSPoint(x:x,y:0)); grid.line(to:NSPoint(x:x,y:300)) }
        for y in stride(from: 25, through: 300, by: 25) { grid.move(to:NSPoint(x:0,y:y)); grid.line(to:NSPoint(x:220,y:y)) }; grid.stroke()
        let bolt = NSBezierPath(); bolt.move(to:NSPoint(x:109.22,y:300)); bolt.line(to:NSPoint(x:220,y:170.49)); bolt.line(to:NSPoint(x:220,y:106.09)); bolt.line(to:NSPoint(x:197.31,y:106.09)); bolt.line(to:NSPoint(x:220,y:70.25)); bolt.line(to:NSPoint(x:220,y:30)); bolt.curve(to:NSPoint(x:190,y:0),controlPoint1:NSPoint(x:220,y:13.43),controlPoint2:NSPoint(x:206.57,y:0)); bolt.line(to:NSPoint(x:166.45,y:0)); bolt.line(to:NSPoint(x:85.32,y:161.97)); bolt.curve(to:NSPoint(x:90.58,y:170.48),controlPoint1:NSPoint(x:83.36,y:165.88),controlPoint2:NSPoint(x:86.2,y:170.48)); bolt.line(to:NSPoint(x:144.87,y:170.48)); bolt.line(to:NSPoint(x:90.43,y:300)); bolt.close()
        color(79,79,79).setFill(); bolt.fill()
        let p = r.percent ?? 0, tint = r.sleeping ? color(100,100,100) : p >= 50 ? color(116,221,124) : p >= 20 ? color(251,213,132) : color(252,134,132)
        ctx.saveGState(); bolt.addClip()
        if p > 0 {
            let surface = 300 - CGFloat(p) * 3
            let liquid = NSBezierPath(); liquid.move(to: NSPoint(x: 0, y: 300))
            liquid.line(to: NSPoint(x: 0, y: surface))
            let animated = hoverID == r.id && !r.sleeping && p > 0 && p < 100
            let phase = CGFloat(Date.timeIntervalSinceReferenceDate * 2.2)
            for step in 1...55 {
                let x = CGFloat(step) * 4
                let wave = animated ? sin(x / 29 + phase) * 3.0 : 0
                liquid.line(to: NSPoint(x:x, y:surface + wave))
            }
            liquid.line(to: NSPoint(x:220,y:300)); liquid.close()
            liquid.addClip()
            let bottom = r.sleeping ? color(60,60,60) : p >= 50 ? color(0,137,82) : p >= 20 ? color(177,132,29) : color(137,39,0)
            if let gradient = NSGradient(starting: tint, ending: bottom) {
                gradient.draw(in: NSRect(x:0,y:0,width:220,height:300), angle: 90)
            }
        }
        ctx.restoreGState()
        label(r.brand,24,20,13,color(229,203,179),.medium); let name = r.model.uppercased().hasPrefix("LIFT") ? "LIFT" : (r.model.uppercased().hasPrefix("PEBBLE MOUSE 2") ? "PEBBLE MOUSE 2" : String(r.model.prefix(19))); label(name,24,34,13,color(178,158,140),.medium)
        let percentText = r.percent.map { "\($0)%" } ?? "--%"
        let percentSize: CGFloat = p == 100 ? 34 : 42.5
        label(percentText, p == 100 ? 17 : 24, 55, percentSize, tint, .semibold)
        label(r.sleeping ? "設備休眠中" : (r.percent == nil ? "電量未知" : "電池使用中"),24,100,10,color(135,135,135))
        label(r.detail,24,224,11,color(255,255,255)); let f=DateFormatter(); f.dateFormat="HH:mm"; label(f.string(from:r.updated),24,240,10,color(135,135,135))
        ctx.restoreGState()
    }
    override func mouseDown(with event:NSEvent) {
        let p = convert(event.locationInWindow,from:nil); let x=p.x*941/bounds.width, y=p.y*573/bounds.height
        if y < 90 && x > 830 { window?.orderOut(nil) }
        else if y < 90 && x > 750 { refresh?() }
        else if y > 500 && y < 550 && x > 370 && x < 590 { let i = min(2,max(0,Int((x-380)/70))); interval = [15,30,90][i]; UserDefaults.standard.set(interval,forKey:"interval"); onInterval?(interval); needsDisplay=true }
    }
    override func scrollWheel(with event: NSEvent) {
        guard maxScroll > 0 else { return }
        let point = convert(event.locationInWindow, from: nil)
        let y = point.y * 573 / bounds.height
        guard (152...452).contains(y) else { return }
        let delta = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) ? event.scrollingDeltaX : event.scrollingDeltaY
        guard delta != 0 else { return }
        let movement = event.hasPreciseScrollingDeltas ? -delta * 941 / bounds.width : (delta < 0 ? CGFloat(124.5) : CGFloat(-124.5))
        scrollTarget = min(maxScroll, max(0, scrollTarget + movement))
        animateScroll()
    }
}
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!; var view: PanelView!; var status: NSStatusItem!; var timer: Timer?; var scanning = false; var previous = [String:Reading]()
    func applicationDidFinishLaunching(_ notification:Notification) {
        window = NSWindow(contentRect:NSRect(x:0,y:0,width:706,height:430),styleMask:[.borderless],backing:.buffered,defer:false)
        window.isOpaque=false; window.backgroundColor = .clear; window.hasShadow=true; window.acceptsMouseMovedEvents=true; window.center()
        view=PanelView(frame:window.contentView!.bounds); view.autoresizingMask=[.width,.height]
        view.wantsLayer = true; view.layer?.cornerRadius = 14; view.layer?.masksToBounds = true
        window.contentView=view
        view.refresh = { [weak self] in self?.refresh() }; view.onInterval = { [weak self] _ in self?.schedule() }
        status=NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength); status.button?.title="ϟ"; status.button?.target=self; status.button?.action=#selector(statusClicked); status.button?.sendAction(on:[.leftMouseUp,.rightMouseUp])
        refresh(); schedule(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true)
    }
    @objc func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            let show = NSMenuItem(title:"顯示 Voltide for Mac",action:#selector(toggle),keyEquivalent:""); show.target=self; menu.addItem(show)
            menu.addItem(.separator())
            let quit = NSMenuItem(title:"退出應用",action:#selector(NSApplication.terminate(_:)),keyEquivalent:""); quit.target=NSApp; menu.addItem(quit)
            status.menu=menu; status.button?.performClick(nil); status.menu=nil
        } else { toggle() }
    }
    @objc func toggle() { if window.isVisible { window.orderOut(nil) } else { refresh(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps:true) } }
    func refresh() {
        guard !scanning else { return }; scanning = true
        DispatchQueue.global(qos:.utility).async { [weak self] in
            let result = Devices.apple() + LogitechReader().read()
            DispatchQueue.main.async {
                guard let self else { return }
                let active = Set(result.map(\.id))
                let stale = self.previous.values.filter { $0.brand == "LOGITECH" && !active.contains($0.id) }.map { old -> Reading in var copy = old; copy.sleeping = true; return copy }
                for item in result { self.previous[item.id] = item }
                self.view.readings = sortReadings(result + stale)
                self.scanning = false
            }
        }
    }
    func schedule() { timer?.invalidate(); timer=Timer.scheduledTimer(withTimeInterval:TimeInterval(view.interval),repeats:true) { [weak self] _ in self?.refresh() } }
}
let app = NSApplication.shared
let delegate = AppDelegate(); app.delegate=delegate; app.setActivationPolicy(.accessory); app.run()

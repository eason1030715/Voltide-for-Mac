import Foundation
import IOKit.hid

// HID++ protocol adapted from Voltide, Copyright (c) 2026 Joko, MIT license.
final class LogitechReader {
    private var replies = [[UInt8]]()
    private let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)
    private var device: IOHIDDevice?
    deinit { buffer.deallocate() }
    private func send(slot: UInt8, feature: UInt8, function: UInt8, params: [UInt8] = []) -> [UInt8]? {
        guard let device else { return nil }
        var request = [UInt8](repeating: 0, count: 20)
        request[0] = 0x11; request[1] = slot; request[2] = feature; request[3] = (function << 4) | 0x0e
        for (i, byte) in params.prefix(16).enumerated() { request[4+i] = byte }
        replies.removeAll()
        let rc = request.withUnsafeBufferPointer { IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, 0x11, $0.baseAddress!, 20) }
        guard rc == kIOReturnSuccess else { return nil }
        let deadline = Date().addingTimeInterval(0.8)
        while Date() < deadline {
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.05, false)
            if let match = replies.first(where: { $0.count >= 7 && $0[0] == 0x11 && $0[1] == slot && $0[2] == feature && $0[3] == request[3] }) { return match }
            if replies.contains(where: { $0.count >= 6 && $0[1] == slot && $0[2] == 0x8f && $0[3] == feature && $0[4] == request[3] }) { return nil }
        }
        return nil
    }
    private func index(_ feature: UInt16, slot: UInt8) -> UInt8? {
        guard let response = send(slot: slot, feature: 0, function: 0, params: [UInt8(feature >> 8), UInt8(feature & 0xff)]), response[4] != 0 else { return nil }
        return response[4]
    }
    func read() -> [Reading] {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, 0)
        IOHIDManagerSetDeviceMatching(manager, [kIOHIDVendorIDKey: 0x046d, kIOHIDPrimaryUsagePageKey: 0xff00] as CFDictionary)
        guard IOHIDManagerOpen(manager, 0) == kIOReturnSuccess else { return [] }
        defer { IOHIDManagerClose(manager, 0) }
        guard let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return [] }
        var readings = [Reading]()
        for d in devices {
            let input = IOHIDDeviceGetProperty(d, kIOHIDMaxInputReportSizeKey as CFString) as? Int ?? 0
            let output = IOHIDDeviceGetProperty(d, kIOHIDMaxOutputReportSizeKey as CFString) as? Int ?? 0
            guard input >= 20, output >= 20, IOHIDDeviceOpen(d, 0) == kIOReturnSuccess else { continue }
            device = d
            IOHIDDeviceRegisterInputReportCallback(d, buffer, 64, { context, _, _, _, _, data, length in
                guard let context else { return }
                let reader = Unmanaged<LogitechReader>.fromOpaque(context).takeUnretainedValue()
                reader.replies.append(Array(UnsafeBufferPointer(start: data, count: length)))
                if reader.replies.count > 80 { reader.replies.removeFirst(40) }
            }, Unmanaged.passUnretained(self).toOpaque())
            IOHIDDeviceScheduleWithRunLoop(d, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            for slot in UInt8(1)...6 {
                let ping = send(slot:slot,feature:0,function:1,params:[0,0,0x55]) ?? send(slot:slot,feature:0,function:1,params:[0,0,0x55])
                guard ping != nil else { continue }
                var name = "Device \(slot)"
                if let feature = index(0x0005, slot: slot), let countResponse = send(slot:slot,feature:feature,function:0) {
                    let count = min(Int(countResponse[4]), 48); var bytes = [UInt8]()
                    while bytes.count < count {
                        guard let part = send(slot:slot,feature:feature,function:1,params:[UInt8(bytes.count)]) else { break }
                        bytes += part.dropFirst(4).prefix(min(16, count-bytes.count))
                    }
                    if let decoded = String(bytes:bytes,encoding:.utf8), !decoded.isEmpty { name = decoded }
                }
                var level:Int?
                if let f = index(0x1000,slot:slot), let b = send(slot:slot,feature:f,function:0), b[4] <= 100 { level=Int(b[4]) }
                else if let f = index(0x1004,slot:slot), let b = send(slot:slot,feature:f,function:1), b[4] <= 100 { level=Int(b[4]) }
                let pid = IOHIDDeviceGetProperty(d, kIOHIDProductIDKey as CFString) as? Int ?? 0
                let loc = IOHIDDeviceGetProperty(d, kIOHIDLocationIDKey as CFString) as? Int ?? 0
                readings.append(Reading(id:"logi-\(pid)-\(loc)-\(slot)",brand:"LOGITECH",model:name,percent:level,detail:"HID++ 2.0",updated:Date()))
            }
            IOHIDDeviceUnscheduleFromRunLoop(d, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
            IOHIDDeviceRegisterInputReportCallback(d,buffer,64,nil,nil)
            IOHIDDeviceClose(d, 0); device = nil
        }
        return readings
    }
}

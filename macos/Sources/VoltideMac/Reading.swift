import Foundation

struct Reading {
    let id: String
    let brand: String
    let model: String
    let percent: Int?
    let detail: String
    let updated: Date
    var sleeping: Bool = false

    var isBluetooth: Bool { detail.localizedCaseInsensitiveContains("bluetooth") }
}

func sortReadings(_ readings: [Reading]) -> [Reading] {
    readings.sorted { lhs, rhs in
        switch (lhs.percent, rhs.percent) {
        case let (a?, b?) where a != b: return a > b
        case (nil, _?): return false
        case (_?, nil): return true
        default: break
        }
        if lhs.isBluetooth != rhs.isBluetooth { return lhs.isBluetooth }
        let order = lhs.model.localizedStandardCompare(rhs.model)
        if order != .orderedSame { return order == .orderedAscending }
        return lhs.id < rhs.id
    }
}

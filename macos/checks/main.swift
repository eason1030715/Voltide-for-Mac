import Foundation
func item(_ id: String, _ level: Int?, _ source: String) -> Reading {
    Reading(id:id,brand:"test",model:id,percent:level,detail:source,updated:Date())
}
let result = sortReadings([item("usb80",80,"HID++ 2.0"), item("bt80",80,"Bluetooth"), item("bt10",10,"Bluetooth"), item("usb100",100,"HID++ 2.0"), item("unknown",nil,"Bluetooth")])
precondition(result.map(\.id) == ["usb100", "bt80", "usb80", "bt10", "unknown"])
let equals = sortReadings([item("z",50,"Bluetooth"),item("a",50,"Bluetooth"),item("u",50,"USB")])
precondition(equals.map(\.id) == ["a","z","u"])
print("排序檢查通過")

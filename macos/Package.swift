// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "VoltideMac", platforms: [.macOS(.v13)], products: [.executable(name: "VoltideMac", targets: ["VoltideMac"])], targets: [.executableTarget(name: "VoltideMac", linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("IOKit")])])

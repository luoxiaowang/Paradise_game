// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "ParadiseGame", platforms: [.macOS(.v13)], products: [
    .library(name: "ParadiseKit", targets: ["ParadiseKit"]),
    .executable(name: "ParadiseGame", targets: ["ParadiseGame"])
], targets: [
    .target(name: "ParadiseKit"),
    .target(name: "CoreBridge"),
    .executableTarget(name: "ParadiseGame", dependencies: ["ParadiseKit", "CoreBridge"], linkerSettings: [.linkedFramework("AppKit"), .linkedFramework("AVFoundation")]),
    .executableTarget(name: "ModelTests", dependencies: ["ParadiseKit"], path: "Tests/ParadiseKitTests")
])

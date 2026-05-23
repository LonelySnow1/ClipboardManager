// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardManager",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClipboardManager",
            path: "ClipboardManager",
            exclude: ["Resources/Info.plist", "Resources/ClipboardManager.entitlements"]
        )
    ]
)

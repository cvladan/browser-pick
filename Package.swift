// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrowserPick",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "BrowserPick",
            path: "Sources/BrowserPick"
        )
    ]
)

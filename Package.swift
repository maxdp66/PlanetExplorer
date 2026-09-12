// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PlanetExplorer",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "PlanetExplorer", targets: ["PlanetExplorer"])
    ],
    targets: [
        .executableTarget(
            name: "PlanetExplorer",
            path: "Sources/PlanetExplorer",
            exclude: ["Info.plist", "PlanetExplorer.entitlements"]
        )
    ]
)

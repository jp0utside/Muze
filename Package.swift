// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Muze",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Muze",
            targets: ["Muze"]
        )
    ],
    dependencies: [
        // Add Spotify SDK when ready
        // .package(url: "https://github.com/spotify/ios-sdk", from: "1.2.0")
    ],
    targets: [
        .target(
            name: "Muze",
            dependencies: [],
            path: "Muze",
            exclude: [
                "Info.plist"
            ],
            resources: [
                // Add resources here if needed
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        )
    ]
)


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
        // Spotify iOS SDK (App Remote for playback control)
        .package(url: "https://github.com/spotify/ios-sdk", from: "2.1.6")
    ],
    targets: [
        .target(
            name: "Muze",
            dependencies: [
                .product(name: "SpotifyiOS", package: "ios-sdk")
            ],
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


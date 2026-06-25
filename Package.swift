// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Rytmo",
    defaultLocalization: "en",
    platforms: [
        .macOS("15.6")
    ],
    products: [
        .executable(
            name: "rytmo",
            targets: ["rytmo"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/SvenTiigi/YouTubePlayerKit.git",
            from: "2.0.5"
        ),
        .package(
            url: "https://github.com/amplitude/AmplitudeUnified-Swift",
            branch: "main"
        ),
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk",
            from: "12.6.0"
        ),
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            from: "9.0.0"
        ),
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.8.1"
        )
    ],
    targets: [
        .executableTarget(
            name: "rytmo",
            dependencies: [
                .product(name: "AmplitudeUnified", package: "AmplitudeUnified-Swift"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "Sparkle", package: "Sparkle"),
                .product(name: "YouTubePlayerKit", package: "YouTubePlayerKit")
            ],
            path: "rytmo",
            exclude: [
                "Info.plist",
                "rytmo.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        ),
        .testTarget(
            name: "rytmoTests",
            dependencies: ["rytmo"],
            path: "Tests/rytmoTests",
            swiftSettings: [
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("MemberImportVisibility")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

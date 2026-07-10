// swift-tools-version: 6.2
import PackageDescription

let concurrencyBaseline: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .defaultIsolation(nil),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "TranslationKit",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .library(name: "AnvyxTranslationKit", targets: ["AnvyxTranslationKit"]),
    ],
    targets: [
        .target(name: "AnvyxTranslationKit", swiftSettings: concurrencyBaseline),
        .testTarget(name: "AnvyxTranslationKitTests", dependencies: ["AnvyxTranslationKit"], swiftSettings: concurrencyBaseline),
    ]
)

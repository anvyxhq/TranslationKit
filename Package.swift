// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TranslationKit",
    platforms: [
        .iOS("18.0")   // Apple's Translation framework is iOS 18.0+
    ],
    products: [
        .library(
            name: "TranslationKit",
            targets: ["TranslationKit"]),
    ],
    targets: [
        .target(
            name: "TranslationKit"),
        .testTarget(
            name: "TranslationKitTests",
            dependencies: ["TranslationKit"]),
    ]
)

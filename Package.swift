// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TranslationKit",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .library(name: "AnvyxTranslationKit", targets: ["AnvyxTranslationKit"]),
    ],
    targets: [
        .target(name: "AnvyxTranslationKit"),
        .testTarget(name: "AnvyxTranslationKitTests", dependencies: ["AnvyxTranslationKit"]),
    ]
)

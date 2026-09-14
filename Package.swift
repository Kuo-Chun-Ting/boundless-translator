// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BoundlessTranslator",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "BoundlessTranslator", targets: ["BoundlessTranslator"])
    ],
    dependencies: [
        .package(
            url: "https://github.com/sindresorhus/KeyboardShortcuts",
            from: "3.1.0"
        )
    ],
    targets: [
        .executableTarget(
            name: "BoundlessTranslator",
            dependencies: ["KeyboardShortcuts"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BoundlessTranslatorUnitTests",
            dependencies: ["BoundlessTranslator"],
            path: "Tests/Unit"
        ),
        .testTarget(
            name: "BoundlessTranslatorComponentTests",
            dependencies: ["BoundlessTranslator"],
            path: "Tests/Component"
        )
    ]
)

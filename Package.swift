// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BoundlessTranslator",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "BoundlessTranslator", targets: ["BoundlessTranslator"])
    ],
    targets: [
        .executableTarget(name: "BoundlessTranslator"),
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

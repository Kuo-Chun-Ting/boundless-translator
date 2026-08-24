// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "WhisperTranslate",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "WhisperTranslate", targets: ["WhisperTranslate"])
    ],
    targets: [
        .executableTarget(name: "WhisperTranslate"),
        .testTarget(
            name: "WhisperTranslateTests",
            dependencies: ["WhisperTranslate"]
        )
    ]
)

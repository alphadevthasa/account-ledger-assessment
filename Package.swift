// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AccountLedgerAssessment",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LedgerCore", targets: ["LedgerCore"]),
        .executable(name: "LedgerReplay", targets: ["LedgerReplay"]),
    ],
    targets: [
        .target(name: "LedgerCore"),
        .executableTarget(name: "LedgerReplay", dependencies: ["LedgerCore"]),
        .testTarget(name: "LedgerCoreTests", dependencies: ["LedgerCore"]),
        .testTarget(name: "KnownLimitations", dependencies: ["LedgerCore"]),
    ]
)

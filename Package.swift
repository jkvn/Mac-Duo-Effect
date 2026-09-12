// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacDuoEffect",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MacDuoEffect", targets: ["MacDuoEffect"])],
    targets: [
        .target(name: "EffectCore"),
        .executableTarget(name: "MacDuoEffect", dependencies: ["EffectCore"]),
        .testTarget(name: "EffectCoreTests", dependencies: ["EffectCore"])
    ]
)

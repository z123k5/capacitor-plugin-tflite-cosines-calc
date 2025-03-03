// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorPluginTfliteCosinesCalc",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "CapacitorPluginTfliteCosinesCalc",
            targets: ["GalleryEnginePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "7.0.0")
        .package(url: "https://github.com/apple/swift-tensorflow.git", .upToNextMajor(from: "0.12.0"))
    ],
    targets: [
        .target(
            name: "GalleryEnginePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
                .product(name: "TensorFlowLite", package: "swift-tensorflow")
            ],
            path: "ios/Sources/GalleryEnginePlugin"),
        .testTarget(
            name: "GalleryEnginePluginTests",
            dependencies: ["GalleryEnginePlugin"],
            path: "ios/Tests/GalleryEnginePluginTests")
    ]
)
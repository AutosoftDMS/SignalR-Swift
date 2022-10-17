// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SignalRSwift",
    platforms: [.macOS(.v10_13),
                .iOS(.v11),
                .tvOS(.v11),
                .watchOS(.v4)],
    products: [
        .library(
            name: "SignalRSwift",
            targets: ["SignalRSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "5.6.2"),
        .package(url: "https://github.com/kamrankhan07/Starscream", from: "4.0.5"),
    ],
    targets: [
        .target(
            name: "SignalRSwift",
            dependencies: ["Alamofire", "Starscream"],
            path: "SignalR-Swift",
            exclude: ["Info.plist"])
    ],
    swiftLanguageVersions: [.v5]
)

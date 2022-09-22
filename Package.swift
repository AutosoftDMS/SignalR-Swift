// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SignalRSwift",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "SignalRSwift",
            targets: ["SignalRSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire", from: "1.0.0"),
        .package(url: "https://github.com/kamrankhan07/Starscream", from: "1.0.0"),
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

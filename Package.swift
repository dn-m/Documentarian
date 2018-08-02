// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Documentarian",
    dependencies: [.package(url: "https://github.com/kareman/SwiftShell", from: "4.0.0")],
    targets: [.target(name: "Documentarian", dependencies: ["SwiftShell"])]
)

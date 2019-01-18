// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pergamon",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(name: "Pergamon", targets: ["Pergamon"]),
        .executable(name: "mon", targets: ["mon"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IBM-Swift/BlueCryptor.git", from: "1.0.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", from: "5.2.0"),
        .package(url: "https://github.com/jmmaloney4/Optionals.git", .branch("master"))
        
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Pergamon", dependencies: ["Cryptor", "Optionals"]),
        .target(name: "mon", dependencies: ["Pergamon", "SwiftCLI"]),
        .testTarget(
            name: "PergamonTests",
            dependencies: ["Pergamon"]),
    ]
)

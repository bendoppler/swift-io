// swift-tools-version:5.5.0


import PackageDescription

let package = Package(
    name: "postgres",
    dependencies: [
        .package(name: "LibPQ", url: "https://github.com/objcio/libpq", branch: "master")
    ]
)


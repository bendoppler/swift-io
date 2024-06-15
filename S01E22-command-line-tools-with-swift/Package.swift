// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "pdf-package",
    dependencies: [
        .package(url: "https://github.com/kylef/Commander.git", from: Version(stringLiteral:"0.9.2"))
    ]
)

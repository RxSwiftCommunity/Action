import PackageDescription

let package = Package(
    name: "Action",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", Version(4, 0, 0, prereleaseIdentifiers: ["alpha.1"]))
    ],
    exclude: ["Tests/"]
)


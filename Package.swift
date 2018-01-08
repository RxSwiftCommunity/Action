import PackageDescription

let package = Package(
    name: "Action",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", Version(4, 1, 0))
    ],
    exclude: ["Tests/"]
)


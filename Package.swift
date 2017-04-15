import PackageDescription

let package = Package(
    name: "Action",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3, minor: 3)
    ]
)


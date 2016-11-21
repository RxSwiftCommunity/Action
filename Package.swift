import PackageDescription

let package = Package(
    name: "Action",
    targets: [],
    dependencies: [
        .Package(url: "https://github.com/ReactiveX/RxSwift.git", majorVersion: 3)
    ],
    exclude: [
        "Sources/Action/UIKitExtensions/AlertAction.swift",
        "Sources/Action/UIKitExtensions/UIBarButtonItem+Action.swift",
        "Sources/Action/UIKitExtensions/UIButton+Rx.swift",
    ]
)


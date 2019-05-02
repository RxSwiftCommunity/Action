Changelog
=========


Current master
--------------
- Added full support for Swift 5.0
- Added full support for RxSwift 5.0
- Remove RxAtomic references

4.0.0
-------
- Add `completions` property to `CompletableAction`
- Change `inputs` type to `AnyObserver<Input>`

3.11.0
-------
- Introduction of  `underlyingError` observable which returns a `Swift.Error`  element type.
- Updated specs that were breaking in `Circle CI` pipeline

3.10.2
-------
- Update the project and xcworkspace and make it compatible with Version 10.1 (10B61)
- Update the Unit test target and make it compatible with Version 10.1 (10B61)
- Moved CI to circle CI 2.0
- Fix issue [#155](https://github.com/RxSwiftCommunity/Action/issues/155)
- Fix issue [#179](https://github.com/RxSwiftCommunity/Action/issues/179)

3.10.0
-------
- Adding syntax sugar `execute()` method on `Action` when `Input` is `Void`. [#171](https://github.com/RxSwiftCommunity/Action/pull/171)
- Raises minimum watchOS deployment target to 3.0, to match RxSwift.

3.9.1
-----

- Less restrictive RxSwift/RxCocoa dependencies in podspec, now supporting RxSwift/RxCocoa 4.x starting with version 4.3

3.9.0
-----
- Fix Action Demo build failure
- Added missing support for Swift 4.2 after 3.7.0


3.8.0
-----

- Fix build failure on New Build System (default on Xcode 10) [#151](https://github.com/RxSwiftCommunity/Action/pull/151)

3.7.0
-----
- Added full support for Swift 4.2
- Added full support for RxSwift 4.3

3.6.0
-----
- Updated `Semantic Versioning` to reflect what is actaully released both on `Pod`  and `Carthage`
- Added full support for Swift 4.1
- Added full support for RxSwift 4.2.0
- UIRefreshControl support: binding to an action (or CocoaAction) starts the action itself and updates the control's refreshing status

3.5.0
-----

- Add convenience initializer with work factories returning `PrimitiveSequence` or any other `ObservableConvertibleType` [#125](https://github.com/RxSwiftCommunity/Action/pull/125)
- Introduce `CompletableAction`, a typealias for action that only completes without emitting any elements [#125](https://github.com/RxSwiftCommunity/Action/pull/125)

3.4.0
-----
- Added full support for Swift 4.0
- Added full support for RxSwift 4.0.0
- Preserved old behavior for `shareReplay(1)` api changes from `RxSwift`. [#110](https://github.com/RxSwiftCommunity/Action/pull/110)


Version table
-------------

| Swift version | RxSwift version | Action version |
| ------------- | --------------- | -------------- |
| Swift 3.0     | v3.2.*   	      | v2.2.0 		   |
| Swift 3.2     | v3.6.*   	      | v3.2.0 		   |
| **Swift 4**   | **v4.0.0**      | **v3.4.0**     |
| Swift 4.1    | **v4.2.0**      | **v3.6.0**     |

3.2.0
-----
- Add macOS bindings for NSControl and NSButton

3.1.1
-----

- Loosens dependency on RxSwift.

3.1.0
-----

- Replace `PublishSubject` with `InputSubject` [#92](https://github.com/RxSwiftCommunity/Action/pull/92)
- Added missing sources for watchOS target [#95](https://github.com/RxSwiftCommunity/Action/pull/95)

3.0.0
-----

- Change `bindTo([...])` methods to `bind(to: [...])` to better align with the revised Rx API
- Update Rx invocations to resolve deprecation warnings related to same

2.2.2
-----

- Remove `RxBlocking` from Linked Libraries in `Action` target

2.2.1
-----

- Loosens dependency on RxSwift.

2.2.0
-----

- Fixes [#63](https://github.com/RxSwiftCommunity/Action/issues/63), related to the default enabled state.
- Adds `bindTo(action:)` for non-CocoaAction.

2.1.1
-----

- Not replay `executionObservables` to fix `execute(_:)`. See [#64](https://github.com/RxSwiftCommunity/Action/pull/56).

2.1.0
-----

- Refactors internal implementation. See [#56](https://github.com/RxSwiftCommunity/Action/pull/56) and [#59](https://github.com/RxSwiftCommunity/Action/pull/59).
- Adds SwiftPM support. See [#58](https://github.com/RxSwiftCommunity/Action/pull/58).

2.0.0-beta.1
------------

- Adds Swift 3 support. See [#46](https://github.com/RxSwiftCommunity/Action/pull/46).

1.2.2
-----

- Added inputs subject to trigger actins by observables. See [#37](https://github.com/RxSwiftCommunity/Action/pull/37).
- Fixes a problem with observable deallocation related to `rx_action` button property. See [#33](https://github.com/RxSwiftCommunity/Action/pull/33).
- Improved Carthage compatibility. See [#34](https://github.com/RxSwiftCommunity/Action/pull/34).
- Swift 2.3 support.

1.2.1
-----

- Relaxes dependency requirements.

1.2.0
-----

- Updates to RxSwift 2.1.0.

1.1.0
-----

- Transitioned podspec to new remote URL (see [#15](https://github.com/RxSwiftCommunity/Action/issues/15)).
- Moved to RxSwift 2.0 🎉

1.2.2
-----

- Fixes memory leak when used on buttons. See [#21](https://github.com/RxSwiftCommunity/Action/issues/21).

1.2.1
-----

- Relaxes dependency requirements.

1.0.0
-----

- Unbounded replaying of event values (see [#3](https://github.com/ashfurrow/Action/issues/3)).

0.3.0
-----

Added `UIAlertAction` support.

0.2.1
-----

- Fixes `enabledIf:` parameter to be `Observable<B>`, `where B: BooleanType`.

0.2.0
-----

- Added tvOS support to UIButton extension.
- Changes `enabledIf` to accept `Observable<BooleanType>` instead of `Bool`.

0.1.0
-----

- Initial release.

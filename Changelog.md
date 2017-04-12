Changelog
=========

Current master
--------------

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

[![Build Status](https://travis-ci.org/ashfurrow/Action.svg)](https://travis-ci.org/ashfurrow/NSObject-Rx)

NSObject-Rx
===========

This library is used with [RxSwift](https://github.com/ReactiveX/RxSwift) to provide an abstraction on top of observables: actions. 

An action is a way to say "hey, later I'll need you to subscribe to this thing." It's actually a lot more involved than that.

Actions accept a `workFactory`: a closure that takes some input and produces an observable. When `execute()` is called, it passes its parameter to this closure and subscribes to the work.

- Can only be executed while "enabled" (`true` by default).
- Only execute one thing at a time.
- Aggregates next/error events across individual executions.

Oh, and it has this really swift thing with `UIButton` that's pretty cool. It'll manage the button's enabled state, make sure the button is disabled while your work is being done, all that stuff 👍

Usage
-----

Coming soon!

Installing
----------

This works with RxSwift version 2, which is still prerelease, so you've gotta be fancy with your podfile. 

```ruby
pod 'RxSwift', '~> 2.0.0-beta'
pod 'Action' # Coming soon!
```

And that'll be 👌

Thanks
------

This library is (pretty obviously) inspired by [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa)'s [`Action` class](https://github.com/ReactiveCocoa/ReactiveCocoa/blob/master/ReactiveCocoa/Swift/Action.swift). Those Thanks!

License
-------

MIT obvs.

![Permissive licenses are the only licenses permitted in the Q continuum.](https://38.media.tumblr.com/4ca19ffae09cb09520cbb5611f0a17e9/tumblr_n13vc9nm1Q1svlvsyo6_250.gif)

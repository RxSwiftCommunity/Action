import Quick
import Nimble
import RxSwift
import RxBlocking
import RxTest
import Action

class ActionTests: QuickSpec {
    override func spec() {
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!

        var errors: TestableObserver<ActionError>!
        var elements: TestableObserver<String>!
        var enabled: TestableObserver<Bool>!
        var executing: TestableObserver<Bool>!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            disposeBag = DisposeBag()
            
            errors = scheduler.createObserver(ActionError.self)
            elements = scheduler.createObserver(String.self)
            enabled = scheduler.createObserver(Bool.self)
            executing = scheduler.createObserver(Bool.self)
        }

        func bindAction(action: Action<String, String>) {
            action.errors
                .bindTo(errors)
                .addDisposableTo(disposeBag)
            
            action.elements
                .bindTo(elements)
                .addDisposableTo(disposeBag)
            
            action.enabled
                .bindTo(enabled)
                .addDisposableTo(disposeBag)
            
            action.executing
                .bindTo(executing)
                .addDisposableTo(disposeBag)
        }

        describe("element handling") {
            sharedExamples("send elements to elements observable") {
                it("errors observable receives nothing") {
                    XCTAssertEqual(errors.events, [])
                }
                
                it("elements observable receives generated elements") {
                    XCTAssertEqual(elements.events, [
                        next(10, "a"),
                        next(20, "b"),
                    ])
                }
                
                it("disabled until element returns") {
                    XCTAssertEqual(enabled.events, [
                        next(0, true),
                        next(10, false),
                        next(10, true),
                        next(20, false),
                        next(20, true),
                    ])
                }
                
                it("executing until element returns") {
                    XCTAssertEqual(executing.events, [
                        next(0, false),
                        next(10, true),
                        next(10, false),
                        next(20, true),
                        next(20, false),
                    ])
                }
            }

            var action: Action<String, String>!

            beforeEach {
                action = Action { Observable.just($0) }
                bindAction(action: action)
            }

            context("trigger via inputs subject") {
                beforeEach {
                    scheduler.scheduleAt(10) { action.inputs.onNext("a") }
                    scheduler.scheduleAt(20) { action.inputs.onNext("b") }
                    scheduler.start()
                }

                itBehavesLike("send elements to elements observable")
            }

            context("trigger via execute() method") {
                beforeEach {
                    scheduler.scheduleAt(10) { action.execute("a") }
                    scheduler.scheduleAt(20) { action.execute("b") }
                    scheduler.start()
                }

                itBehavesLike("send elements to elements observable")
            }
        }

        describe("error handling") {
            sharedExamples("send errors to errors observable") {
                it("errors observable receives generated errors") {
                    XCTAssertEqual(errors.events, [
                        next(10, .underlyingError(TestError)),
                        next(20, .underlyingError(TestError)),
                    ])
                }
                
                it("elements observable receives nothing") {
                    XCTAssertEqual(elements.events, [])
                }
                
                it("disabled until error returns") {
                    XCTAssertEqual(enabled.events, [
                        next(0, true),
                        next(10, false),
                        next(10, true),
                        next(20, false),
                        next(20, true),
                    ])
                }
                
                it("executing until error returns") {
                    XCTAssertEqual(executing.events, [
                        next(0, false),
                        next(10, true),
                        next(10, false),
                        next(20, true),
                        next(20, false),
                    ])
                }
            }

            var action: Action<String, String>!

            beforeEach {
                action = Action { _ in Observable.error(TestError) }
                bindAction(action: action)
            }

            context("trigger via inputs subject") {
                beforeEach {
                    scheduler.scheduleAt(10) { action.inputs.onNext("a") }
                    scheduler.scheduleAt(20) { action.inputs.onNext("b") }
                    scheduler.start()
                }

                itBehavesLike("send errors to errors observable")
            }

            context("trigger via execute() method") {
                beforeEach {
                    scheduler.scheduleAt(10) { action.execute("a") }
                    scheduler.scheduleAt(20) { action.execute("b") }
                    scheduler.start()
                }

                itBehavesLike("send errors to errors observable")
            }
        }

        it("sends errors on errors observable as Next events") {
            let subject = errorSubject()
            var receivedError: ActionError?

            subject.errors.subscribe(onNext: { (value) -> Void in
                receivedError = value
            }).addDisposableTo(disposeBag)

            subject.execute()

            expect(receivedError).toNot( beNil() )
        }

        it("sends the correct error types on errors observable") {
            let subject = errorSubject()
            var error: ActionError?

            subject.errors.subscribe(onNext: { (value) -> Void in
                error = value
            }).addDisposableTo(disposeBag)

            subject.execute()

            guard let receivedError = error else {
                fail("received error is nil."); return
            }

            if case ActionError.underlyingError = receivedError {
                // Nop
            } else {
                fail("Incorrect error type.")
            }
        }

        it("sends the correct errors on errors observable") {
            let subject = errorSubject()
            var error: ActionError?

            subject.errors.subscribe(onNext: { (value) -> Void in
                error = value
            }).addDisposableTo(disposeBag)

            subject.execute()

            guard let receivedError = error else {
                fail("received error is nil."); return
            }

            if case ActionError.underlyingError(let e) = receivedError {
                if let e = e as? String {
                    expect(e) == TestError
                } else {
                    fail("Incorrect error returned.")
                }
            }
        }

        it("errors on observable returned from execute()") {
            let subject = errorSubject()
            var errored = false

            waitUntil { done in
                subject
                    .execute()
                    .subscribe(onError: { _ in
                        errored = true
                        done()
                    })
                    .addDisposableTo(disposeBag)
            }

            expect(errored) == true
        }

        it("doesn't error on elements observable") {
            let subject = errorSubject()
            var errored = false

            subject
                .elements
                .subscribe(onError: { _ in
                    errored = true
                })
                .addDisposableTo(disposeBag)

            subject.execute()

            expect(errored) == false
        }


        it("doesn't error on errors observable") {
            let subject = errorSubject()
            var errored = false

            subject
                .errors
                .subscribe(onError: { _ in
                    errored = true
                })
                .addDisposableTo(disposeBag)

            subject.execute()

            expect(errored) == false
        }

        it("calls the work factory with correct input") {
            let testInput = "input"
            var receivedInput: String?
            let subject = Action<String, Void>(workFactory: { (input) in
                receivedInput = input
                return .just(())
            })

            subject.execute(testInput)

            expect(receivedInput) == testInput
        }

        it("sends false on executing observable by default") {
            let subject = emptySubject()

            let executing = try! subject.executing.toBlocking().first()
            expect(executing) == false
        }

        it("only sends true, then false on executing observable when execute() is called") {
            let subject = emptySubject()
            var elements: [Bool] = []

            subject
                .executing
                .skip(1) // Skips initial value
                .subscribe(onNext: { value -> Void in
                    elements += [value]
                })
                .addDisposableTo(disposeBag)

            waitUntil { done in
                subject
                    .execute()
                    .subscribe(onCompleted: {
                        done()
                    })
                    .addDisposableTo(disposeBag)
            }


            expect(elements).toEventually( equal([true, false]) )
        }

        sharedExamples("sending elements") { (context: @escaping SharedExampleContext) -> Void in
            var testItems: [String]!

            beforeEach {
                testItems = context()["items"] as! [String]
            }

            it("sends next elements on inputs and elements observables when execute() is called") {
                let subject = testSubject(testItems)

                var receivedInputs: [Void] = []
                subject.inputs.subscribe(onNext: { (input) -> Void in
                    receivedInputs += [input]
                    }).addDisposableTo(disposeBag)

                var receivedElements: [String] = []
                subject.elements.subscribe(onNext: { (element) -> Void in
                    receivedElements += [element]
                    }).addDisposableTo(disposeBag)

                subject.execute()

                expect(receivedInputs.count) == 1
                expect(receivedElements) == testItems
            }

            it("sends next elements on elements observable when inputs receives next elements") {
                let subject = testSubject(testItems)
                var receivedElements: [String] = []

                subject.elements.subscribe(onNext: { (element) -> Void in
                    receivedElements += [element]
                    }).addDisposableTo(disposeBag)

                subject.inputs.onNext()

                expect(receivedElements) == testItems
            }

            it("sends next elements on observable returned from execte()") {
                let subject = testSubject(testItems)
                var receivedElements: [String] = []

                waitUntil { done in
                    subject.execute().subscribe(onNext: { (element) -> Void in
                        receivedElements += [element]
                        }, onCompleted: done).addDisposableTo(disposeBag)
                }
                
                expect(receivedElements) == testItems
            }
        }
        
        describe("execution observables") {
            it("returns a new observable from execute() which sends work", closure: {
                let subject = testExecutionObservablesSubject()
                
                subject
                    .execute()
                    .subscribe(onNext: { (string) in
                        expect(string) == TestElement
                }).addDisposableTo(disposeBag)
            })
        }

        describe("one element") {
            itBehavesLike("sending elements") { () -> (NSDictionary) in
                return ["items": [TestElement]]
            }
        }

        describe("multiple elements") {
            itBehavesLike("sending elements") { () -> (NSDictionary) in
                return ["items": [TestElement, TestElement, TestElement]]
            }
        }

        it("completes observable returned from execute() when workFactory observable completes") {
            let subject = emptySubject()
            var completed = false

            waitUntil { done in
                subject
                    .execute()
                    .subscribe(onCompleted: {
                        completed = true
                        done()
                    })
                    .addDisposableTo(disposeBag)
            }

            expect(completed) == true
        }

        it("only subscribes to observable returned from work factory once") {
            var invocations = 0
            let subject = Action<Void, Void>(workFactory: { _ in
                invocations += 1
                return .empty()
            })

            waitUntil { done in
                subject.execute()
                    .subscribe(onCompleted: {
                        done()
                    })
                    .addDisposableTo(disposeBag)
            }

            expect(invocations) == 1
        }


        sharedExamples("triggering execution") { (context: @escaping SharedExampleContext) -> Void in
            var executer: TestActionExecuter!

            beforeEach {
                executer = context()["executer"] as! TestActionExecuter
            }

            describe("enabled") {
                it("sends true on the enabled observable") {
                    let subject = emptySubject()

                    let enabled = try! subject.enabled.toBlocking().first()
                    expect(enabled) == true
                }

                it("is externally disabled while executing") {
                    var observer: AnyObserver<Void>!
                    let subject = Action<Void, Void>(workFactory: { _ in
                        return Observable.create { (obsv) -> Disposable in
                            observer = obsv
                            return Disposables.create()
                        }
                    })

                    executer.execute(subject)

                    expect(try! subject.enabled.toBlocking().first()).toEventually( beFalse() )
                }

                it("is externally re-enabled after executing") {
                    var observer: AnyObserver<Void>!
                    let subject = Action<Void, Void>(workFactory: { _ in
                        return Observable.create { (obsv) -> Disposable in
                            observer = obsv
                            return Disposables.create()
                        }
                    })

                    executer.execute(subject)

                    observer.onCompleted()

                    expect(try! subject.enabled.toBlocking().first()).toEventually( beTrue() )
                }
            }

            describe("disabled") {
                it("sends false on enabled observable") {
                    let subject = Action<Void, Void>(enabledIf: .just(false), workFactory: { _ in
                        return .empty()
                    })

                    let enabled = try! subject.enabled.toBlocking().first()
                    expect(enabled) == false
                }
                
                it("errors observable sends error as next event when execute() is called") {
                    let subject = Action<Void, Void>(enabledIf: .just(false), workFactory: { _ in
                        return .empty()
                    })

                    var receivedError: ActionError?

                    subject
                        .errors
                        .subscribe(onNext: { error in
                            receivedError = error
                        })
                        .addDisposableTo(disposeBag)

                    executer.execute(subject)

                    expect(receivedError).toNot( beNil() )
                }

                it("errors observable sends correct error types when execute() is called") {
                    let subject = Action<Void, Void>(enabledIf: .just(false), workFactory: { _ in
                        return .empty()
                    })

                    var receivedError: ActionError?

                    subject
                        .errors
                        .subscribe(onNext: { error in
                            receivedError = error
                        })
                        .addDisposableTo(disposeBag)

                    executer.execute(subject)

                    guard let error = receivedError else {
                        fail("Error is nil"); return
                    }

                    if case ActionError.notEnabled = error {
                        // Nop
                    } else {
                        fail("Incorrect error returned.")
                    }
                }

                it("doesn't invoke the work factory") {
                    var invoked = false

                    let subject = Action<Void, Void>(enabledIf: .just(false), workFactory: { _ in
                        invoked = true
                        return .empty()
                    })

                    executer.execute(subject)

                    expect(invoked) == false
                }
            }
        }

        describe("execute via execute()") {
            itBehavesLike("triggering execution") { () -> (NSDictionary) in
                return ["executer": TestActionExecuter { subject in subject.execute() }]
            }
        }

        describe("execute via inputs subject") {
            itBehavesLike("triggering execution") { () -> (NSDictionary) in
                return ["executer": TestActionExecuter { subject in subject.inputs.onNext() }]
            }
        }
    }
}

extension ActionError: Equatable {
    // Not accurate but convenient for testing.
    public static func ==(lhs: ActionError, rhs: ActionError) -> Bool {
        switch (lhs, rhs) {
        case (.notEnabled, .notEnabled):
            return true
        case (.underlyingError, .underlyingError):
            return true
        default:
            return false
        }
    }
}

extension String: Error { }
let TestError = "Test Error"

func errorObservable() -> Observable<Void> {
    return .create({ (observer) -> Disposable in
        observer.onError(TestError)
        return Disposables.create()
    })
}

func errorSubject() -> Action<Void, Void> {
    return Action(workFactory: { input in
        return errorObservable()
    })
}

func emptySubject() -> Action<Void, Void> {
    return Action(workFactory: { input in
        return .empty()
    })
}

func testExecutionObservablesSubject() -> Action<Void, String> {
    return Action(workFactory: { input in
        return Observable.create({ (observer) -> Disposable in
            observer.onNext(TestElement)
            observer.onCompleted()
            return Disposables.create()
        })
    })
}


let TestElement = "Hi there"

func testSubject(_ elements: [String]) -> Action<Void, String> {
    return Action(workFactory: { input in
        return Observable.from(elements)
    })
}

class TestActionExecuter {
    let execute: (Action<Void, Void>) -> Void

    init(execute: @escaping (Action<Void, Void>) -> Void) {
        self.execute = execute
    }
}

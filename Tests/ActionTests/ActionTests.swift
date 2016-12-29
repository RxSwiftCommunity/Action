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

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            disposeBag = DisposeBag()
        }

        describe("action properties") {
            var inputs: TestableObserver<String>!
            var elements: TestableObserver<String>!
            var errors: TestableObserver<ActionError>!
            var enabled: TestableObserver<Bool>!
            var executing: TestableObserver<Bool>!
            var executionObservables: TestableObserver<Observable<String>>!

            beforeEach {
                inputs = scheduler.createObserver(String.self)
                elements = scheduler.createObserver(String.self)
                errors = scheduler.createObserver(ActionError.self)
                enabled = scheduler.createObserver(Bool.self)
                executing = scheduler.createObserver(Bool.self)
                executionObservables = scheduler.createObserver(Observable<String>.self)
            }

            func bindAction(action: Action<String, String>) {
                action.inputs
                    .bindTo(inputs)
                    .addDisposableTo(disposeBag)

                action.elements
                    .bindTo(elements)
                    .addDisposableTo(disposeBag)

                action.errors
                    .bindTo(errors)
                    .addDisposableTo(disposeBag)
                
                action.enabled
                    .bindTo(enabled)
                    .addDisposableTo(disposeBag)
                
                action.executing
                    .bindTo(executing)
                    .addDisposableTo(disposeBag)

                action.executionObservables
                    .bindTo(executionObservables)
                    .addDisposableTo(disposeBag)

                // Dummy subscription for multiple subcription tests
                action.inputs.subscribe().addDisposableTo(disposeBag)
                action.elements.subscribe().addDisposableTo(disposeBag)
                action.errors.subscribe().addDisposableTo(disposeBag)
                action.enabled.subscribe().addDisposableTo(disposeBag)
                action.executing.subscribe().addDisposableTo(disposeBag)
                action.executionObservables.subscribe().addDisposableTo(disposeBag)
            }

            describe("single element action") {
                sharedExamples("send elements to elements observable") {
                    it("inputs subject receives generated inputs") {
                        XCTAssertEqual(inputs.events, [
                            next(10, "a"),
                            next(20, "b"),
                        ])
                    }

                    it("elements observable receives generated elements") {
                        XCTAssertEqual(elements.events, [
                            next(10, "a"),
                            next(20, "b"),
                        ])
                    }
                    
                    it("errors observable receives nothing") {
                        XCTAssertEqual(errors.events, [])
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

                    it("executes twice") {
                        expect(executionObservables.events.count) == 2
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

            describe("multiple element action") {
                sharedExamples("send array elements to elements observable") {
                    it("inputs subject receives generated inputs") {
                        XCTAssertEqual(inputs.events, [
                            next(10, "a"),
                            next(20, "b"),
                        ])
                    }

                    it("elements observable receives generated elements") {
                        XCTAssertEqual(elements.events, [
                            next(10, "a"),
                            next(10, "b"),
                            next(10, "c"),
                            next(20, "b"),
                            next(20, "c"),
                            next(20, "d"),
                        ])
                    }
                    
                    it("errors observable receives nothing") {
                        XCTAssertEqual(errors.events, [])
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

                    it("executes twice") {
                        expect(executionObservables.events.count) == 2
                    }
                }

                var action: Action<String, String>!

                beforeEach {
                    action = Action { input in
                        // "a" -> ["a", "b", "c"]
                        let baseValue = UnicodeScalar(input)!.value
                        let strings = (baseValue..<(baseValue + 3))
                            .flatMap { UnicodeScalar($0) }
                            .map { String($0) }

                        return Observable.from(strings)
                    }

                    bindAction(action: action)
                }

                context("trigger via inputs subject") {
                    beforeEach {
                        scheduler.scheduleAt(10) { action.inputs.onNext("a") }
                        scheduler.scheduleAt(20) { action.inputs.onNext("b") }
                        scheduler.start()
                    }

                    itBehavesLike("send array elements to elements observable")
                }

                context("trigger via execute() method") {
                    beforeEach {
                        scheduler.scheduleAt(10) { action.execute("a") }
                        scheduler.scheduleAt(20) { action.execute("b") }
                        scheduler.start()
                    }

                    itBehavesLike("send array elements to elements observable")
                }
            }

            describe("error action") {
                sharedExamples("send errors to errors observable") {
                    it("inputs subject receives generated inputs") {
                        XCTAssertEqual(inputs.events, [
                            next(10, "a"),
                            next(20, "b"),
                        ])
                    }

                    it("elements observable receives nothing") {
                        XCTAssertEqual(elements.events, [])
                    }
                    
                    it("errors observable receives generated errors") {
                        XCTAssertEqual(errors.events, [
                            next(10, .underlyingError(TestError)),
                            next(20, .underlyingError(TestError)),
                        ])
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

                    it("executes twice") {
                        expect(executionObservables.events.count) == 2
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

            describe("disabled action") {
                sharedExamples("send notEnabled errors to errors observable") {
                    it("inputs subject receives generated inputs") {
                        XCTAssertEqual(inputs.events, [
                            next(10, "a"),
                            next(20, "b"),
                        ])
                    }

                    it("elements observable receives nothing") {
                        XCTAssertEqual(elements.events, [])
                    }
                    
                    it("errors observable receives generated errors") {
                        XCTAssertEqual(errors.events, [
                            next(10, .notEnabled),
                            next(20, .notEnabled),
                        ])
                    }
                    
                    it("disabled") {
                        XCTAssertEqual(enabled.events, [
                            next(0, false),
                        ])
                    }
                    
                    it("never be executing") {
                        XCTAssertEqual(executing.events, [
                            next(0, false),
                        ])
                    }

                    it("never executes") {
                        expect(executionObservables.events).to(beEmpty())
                    }
                }

                var action: Action<String, String>!

                beforeEach {
                    action = Action(enabledIf: Observable.just(false)) { Observable.just($0) }
                    bindAction(action: action)
                }

                context("trigger via inputs subject") {
                    beforeEach {
                        scheduler.scheduleAt(10) { action.inputs.onNext("a") }
                        scheduler.scheduleAt(20) { action.inputs.onNext("b") }
                        scheduler.start()
                    }

                    itBehavesLike("send notEnabled errors to errors observable")
                }

                context("trigger via execute() method") {
                    beforeEach {
                        scheduler.scheduleAt(10) { action.execute("a") }
                        scheduler.scheduleAt(20) { action.execute("b") }
                        scheduler.start()
                    }

                    itBehavesLike("send notEnabled errors to errors observable")
                }
            }
        }

        describe("execute function return value") {
            var action: Action<String, String>!
            var element: TestableObserver<String>!
            var executionObservables: TestableObserver<Observable<String>>!

            beforeEach {
                element = scheduler.createObserver(String.self)
                executionObservables = scheduler.createObserver(Observable<String>.self)
            }

            func bindAndExecuteTwice(action: Action<String, String>) {
                action.executionObservables
                    .bindTo(executionObservables)
                    .addDisposableTo(disposeBag)
                
                scheduler.scheduleAt(10) {
                    action.execute("a")
                        .bindTo(element)
                        .addDisposableTo(disposeBag)
                }

                scheduler.scheduleAt(20) {
                    action.execute("b")
                        .bindTo(element)
                        .addDisposableTo(disposeBag)
                }

                scheduler.start()
            }

            context("single element action") {
                beforeEach {
                    action = Action { Observable.just($0) }
                    bindAndExecuteTwice(action: action)
                }

                it("element receives single value for each execution") {
                    XCTAssertEqual(element.events, [
                        next(10, "a"),
                        completed(10),
                        next(20, "b"),
                        completed(20),
                    ])
                }

                it("executes twice") {
                    expect(executionObservables.events.count) == 2
                }
            }

            context("multiple element action") {
                beforeEach {
                    action = Action { Observable.of($0, $0, $0) }
                    bindAndExecuteTwice(action: action)
                }

                it("element receives 3 values for each execution") {
                    XCTAssertEqual(element.events, [
                        next(10, "a"),
                        next(10, "a"),
                        next(10, "a"),
                        completed(10),
                        next(20, "b"),
                        next(20, "b"),
                        next(20, "b"),
                        completed(20),
                    ])
                }

                it("executes twice") {
                    expect(executionObservables.events.count) == 2
                }
            }

            context("error action") {
                beforeEach {
                    action = Action { _ in Observable.error(TestError) }
                    bindAndExecuteTwice(action: action)
                }

                it("element fails with underlyingError") {
                    XCTAssertEqual(element.events, [
                        error(10, ActionError.underlyingError(TestError)),
                        error(20, ActionError.underlyingError(TestError)),
                    ])
                }

                it("executes twice") {
                    expect(executionObservables.events.count) == 2
                }
            }

            context("disabled") {
                beforeEach {
                    action = Action(enabledIf: Observable.just(false)) { Observable.just($0) }
                    bindAndExecuteTwice(action: action)
                }

                it("element fails with notEnabled") {
                    XCTAssertEqual(element.events, [
                        error(10, ActionError.notEnabled),
                        error(20, ActionError.notEnabled),
                    ])
                }

                it("never executes") {
                    expect(executionObservables.events).to(beEmpty())
                }
            }

            context("execute while executing") {
                var secondElement: TestableObserver<String>!
                var trigger: PublishSubject<Void>!
                
                beforeEach {
                    secondElement = scheduler.createObserver(String.self)
                    trigger = PublishSubject<Void>()
                    action = Action { Observable.just($0).sample(trigger) }
                    
                    action.executionObservables
                        .bindTo(executionObservables)
                        .addDisposableTo(disposeBag)
                    
                    scheduler.scheduleAt(10) {
                        action.execute("a")
                            .bindTo(element)
                            .addDisposableTo(disposeBag)
                    }

                    scheduler.scheduleAt(20) {
                        action.execute("b")
                            .bindTo(secondElement)
                            .addDisposableTo(disposeBag)
                    }

                    scheduler.scheduleAt(30) {
                        trigger.onNext()
                    }

                    scheduler.start()
                }

                it("first element receives single value") {
                    XCTAssertEqual(element.events, [
                        next(30, "a"),
                        completed(30),
                    ])
                }

                it("second element fails with notEnabled error") {
                    XCTAssertEqual(secondElement.events, [
                        error(20, ActionError.notEnabled)
                    ])
                }

                it("executes once") {
                    expect(executionObservables.events.count) == 1
                }
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

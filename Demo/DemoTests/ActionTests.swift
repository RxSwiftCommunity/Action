import Quick
import Nimble
import RxSwift
import RxBlocking
import Action

class ActionTests: QuickSpec {
    override func spec() {
        var disposeBag: DisposeBag!

        beforeEach {
            disposeBag = DisposeBag()
        }

        it("sends errors on errors observable as Next events") {
            let subject = errorSubject()
            var receivedError: ActionError?

            subject.errors.subscribeNext({ (value) -> Void in
                receivedError = value
            }).addDisposableTo(disposeBag)

            subject.execute()

            expect(receivedError).toNot( beNil() )
        }

        it("sends the correct error types on errors observable") {
            let subject = errorSubject()
            var error: ActionError?

            subject.errors.subscribeNext({ (value) -> Void in
                error = value
            }).addDisposableTo(disposeBag)

            subject.execute()

            guard let receivedError = error else {
                fail("received error is nil."); return
            }

            if case ActionError.UnderlyingError = receivedError {
                // Nop
            } else {
                fail("Incorrect error type.")
            }
        }

        it("sends the correct errors on errors observable") {
            let subject = errorSubject()
            var error: ActionError?

            subject.errors.subscribeNext({ (value) -> Void in
                error = value
            }).addDisposableTo(disposeBag)

            subject.execute()

            guard let receivedError = error else {
                fail("received error is nil."); return
            }

            if case ActionError.UnderlyingError(let e) = receivedError {
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

            subject
                .execute()
                .subscribeError{ _ in
                    errored = true
                }
                .addDisposableTo(disposeBag)

            expect(errored) == true
        }

        it("doesn't error on elements observable") {
            let subject = errorSubject()
            var errored = false

            subject
                .elements
                .subscribeError{ _ in
                    errored = true
                }
                .addDisposableTo(disposeBag)

            subject.execute()

            expect(errored) == false
        }


        it("doesn't error on errors observable") {
            let subject = errorSubject()
            var errored = false

            subject
                .errors
                .subscribeError{ _ in
                    errored = true
                }
                .addDisposableTo(disposeBag)

            subject.execute()

            expect(errored) == false
        }

        it("calls the work factory with correct input") {
            let testInput = "input"
            var receivedInput: String?
            let subject = Action<String, Void>(workFactory: { (input) in
                receivedInput = input
                return .just()
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
                .subscribeNext { value -> Void in
                    elements += [value]
                }
                .addDisposableTo(disposeBag)

            subject.execute()

            expect(elements) == [true, false]
        }

        sharedExamples("sending elements") { (context: QCKDSLSharedExampleContext!) -> Void in
            var testItems: [String]!

            beforeEach {
                testItems = context()["items"] as! [String]
            }

            it("sends next elements on inputs and elements observables when execute() is called") {
                let subject = testSubject(testItems)

                var receivedInputs: [Void] = []
                subject.inputs.subscribeNext { (input) -> Void in
                    receivedInputs += [input]
                    }.addDisposableTo(disposeBag)

                var receivedElements: [String] = []
                subject.elements.subscribeNext { (element) -> Void in
                    receivedElements += [element]
                    }.addDisposableTo(disposeBag)

                subject.execute()

                expect(receivedInputs.count) == 1
                expect(receivedElements) == testItems
            }

            it("sends next elements on elements observable when inputs receives next elements") {
                let subject = testSubject(testItems)
                var receivedElements: [String] = []

                subject.elements.subscribeNext { (element) -> Void in
                    receivedElements += [element]
                    }.addDisposableTo(disposeBag)

                subject.inputs.onNext()

                expect(receivedElements) == testItems
            }

            it("sends next elements on observable returned from execte()") {
                let subject = testSubject(testItems)
                var receivedElements: [String] = []

                subject.execute().subscribeNext { (element) -> Void in
                    receivedElements += [element]
                    }.addDisposableTo(disposeBag)
                
                expect(receivedElements) == testItems
            }
        }
        
        describe("execution observables") {
            it("returns a new observable from execute() which sends work", closure: {
                let subject = testExecutionObservablesSubject()
                
                subject
                    .execute()
                    .subscribeNext({ (string) in
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

            subject
                .execute()
                .subscribeCompleted {
                    completed = true
                }
                .addDisposableTo(disposeBag)

            expect(completed) == true
        }

        it("only subscribes to observable returned from work factory once") {
            var invocations = 0
            let subject = Action<Void, Void>(workFactory: { _ in
                invocations += 1
                return .empty()
            })

            subject.execute()

            expect(invocations) == 1
        }

        sharedExamples("triggering execution") { (context: QCKDSLSharedExampleContext!) -> Void in
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
                            return NopDisposable.instance
                        }
                    })

                    executer.execute(subject)

                    var enabled = try! subject.enabled.toBlocking().first()
                    expect(enabled) == false

                    observer.onCompleted()

                    enabled = try! subject.enabled.toBlocking().first()
                    expect(enabled) == true
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
                        .subscribeNext { error in
                            receivedError = error
                        }
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
                        .subscribeNext { error in
                            receivedError = error
                        }
                        .addDisposableTo(disposeBag)

                    executer.execute(subject)

                    guard let error = receivedError else {
                        fail("Error is nil"); return
                    }

                    if case ActionError.NotEnabled = error {
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



extension String: Error { }
let TestError = "Test Error"

func errorObservable() -> Observable<Void> {
    return .create({ (observer) -> Disposable in
        observer.onError(TestError)
        return NopDisposable.instance
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
            return NopDisposable.instance
        })
    })
}


let TestElement = "Hi there"

func testSubject(_ elements: [String]) -> Action<Void, String> {
    return Action(workFactory: { input in
        return elements.toObservable()
    })
}

class TestActionExecuter {
    let execute: (Action<Void, Void>) -> Void

    init(execute: (Action<Void, Void>) -> Void) {
        self.execute = execute
    }
}

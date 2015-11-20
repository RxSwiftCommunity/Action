import Quick
import Nimble
import RxSwift
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

            subject.execute(Void())

            expect(receivedError).toNot( beNil() )
        }

        it("sends the correct error types on errors observable") {
            let subject = errorSubject()
            var error: ActionError?

            subject.errors.subscribeNext({ (value) -> Void in
                error = value
            }).addDisposableTo(disposeBag)

            subject.execute(Void())

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

            subject.execute(Void())

            guard let receivedError = error else {
                fail("received error is nil."); return
            }

            if case ActionError.UnderlyingError(let e) = receivedError {
                if let e = e as? String {
                    expect(e) == TestError
                } else {
                    fail("Incorrect error returnied.")
                }
            }
        }

        it("errors on observable returned from execute()") {
            let subject = errorSubject()
            var errored = false

            subject
                .execute(Void())
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

            subject.execute(Void())

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

            subject.execute(Void())

            expect(errored) == false
        }

        it("calls the work factory with correct input") {
            let testInput = "input"
            var receivedInput: String?
            let subject = Action<String, Void>(workFactory: { (input) in
                receivedInput = input
                return just(Void())
            })

            subject.execute(testInput)

            expect(receivedInput) == testInput
        }

        it("sends true on executing observable when work starts") {
            let subject = emptySubject()
            var executed = false

            subject
                .executing
                .filter { executing -> Bool in
                    // Only accept true executions
                    return executing == true
                }
                .subscribeNext { (value) -> Void in
                    executed = value
                }
                .addDisposableTo(disposeBag)

            subject.execute(Void())

            expect(executed) == true
        }

        it("sends false on executing observable when work ends") {
            let subject = emptySubject()
            var finishedExecuting = false

            subject
                .executing
                .filter { executing -> Bool in
                    // Only accept false executions
                    return executing == false
                }
                .subscribeNext { _ -> Void in
                    finishedExecuting = true
                }
                .addDisposableTo(disposeBag)

            subject.execute(Void())

            expect(finishedExecuting) == true
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

            subject.execute(Void())

            expect(elements) == [true, false]
        }

        it("sends next elements on elements observable") {
            fail("test not implemented yet")
        }

        it("sends next elements on observable returned from workFactory") {
            fail("test not implemented yet")
        }

        it("completes observable returned from execute() when workFactory observable completes") {
            let subject = emptySubject()
            var completed = false

            subject
                .execute(Void())
                .subscribeCompleted {
                    completed = true
                }
                .addDisposableTo(disposeBag)

            expect(completed) == true
        }

        it("only subscribes to observable returned from work factory once") {
            fail("test not implemented yet")
        }

        describe("enabled") {
            it("sends true on the enabled observable") {
                fail("test not implemented yet")
            }

            it("is externally disabled while executing") {
                fail("test not implemented yet")
            }
        }

        describe("disabled") {
            it("sends false on enabled observable") {
                fail("test not implemented yet")
            }
            
            it("errors observable sends errors as next events when execute() is called") {
                fail("test not implemented yet")
            }

            it("doesn't invoke the work factory") {
                fail("test not implemented yet")
            }
        }
    }
}

class ButtonTests: QuickSpec {
    override func spec() {
        it("isn't written yet") {
            fail()
        }
    }
}


extension String: ErrorType { }
let TestError = "Test Error"

func errorObservable() -> Observable<Void> {
    return create({ (observer) -> Disposable in
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
        return empty()
    })
}

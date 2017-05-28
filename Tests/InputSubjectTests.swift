import Quick
import Nimble
import RxSwift
import RxTest
import Action

class InputSubjectTests: QuickSpec {
    override func spec() {
        var scheduler: TestScheduler!
        var disposeBag: DisposeBag!

        beforeEach {
            scheduler = TestScheduler(initialClock: 0)
            disposeBag = DisposeBag()
        }

        describe("Disposable observable") {
            it("observables can be dispose") {
                let subject = InputSubject<Int>()
                let disposable1 = subject.subscribe()
                let disposable2 = subject.subscribe()
                expect(subject.hasObservers).to(beTrue())
                disposable2.dispose()
                expect(subject.hasObservers).to(beTrue())
                disposable1.dispose()
                expect(subject.hasObservers).to(beFalse())
            }

            it("dispose all observables") {
                let subject = InputSubject<Int>()
                _ = subject.subscribe()
                _ = subject.subscribe()
                expect(subject.hasObservers).to(beTrue())
                subject.dispose()
                expect(subject.hasObservers).to(beFalse())
                expect(subject.isDisposed).to(beTrue())
            }
        }

        describe("emit events") {
            it("emit .next events") {
                let subject = InputSubject<Int>()
                let observer = scheduler.createObserver(Int.self)
                subject.asObservable()
                    .bind(to: observer)
                    .disposed(by: disposeBag)
                scheduler.scheduleAt(10) { subject.onNext(1) }
                scheduler.scheduleAt(20) { subject.onNext(2) }
                scheduler.scheduleAt(30) { subject.onNext(3) }
                scheduler.start()

                XCTAssertEqual(observer.events, [
                    next(10, 1),
                    next(20, 2),
                    next(30, 3)
                ])
            }

            it("ignore .error events") {
                let subject = InputSubject<Int>()
                let observer = scheduler.createObserver(Int.self)
                subject.asObservable()
                    .bind(to: observer)
                    .disposed(by: disposeBag)
                scheduler.scheduleAt(10) { subject.onNext(1) }
                scheduler.scheduleAt(20) { subject.onError(TestError) }
                scheduler.scheduleAt(30) { subject.onNext(3) }
                scheduler.start()

                XCTAssertEqual(observer.events, [
                    next(10, 1),
                    next(30, 3)
                ])
            }

            it("ignore .completed events") {
                let subject = InputSubject<Int>()
                let observer = scheduler.createObserver(Int.self)
                subject.asObservable()
                    .bind(to: observer)
                    .disposed(by: disposeBag)
                scheduler.scheduleAt(10) { subject.onNext(1) }
                scheduler.scheduleAt(20) { subject.onCompleted() }
                scheduler.scheduleAt(30) { subject.onNext(3) }
                scheduler.start()

                XCTAssertEqual(observer.events, [
                    next(10, 1),
                    next(30, 3)
                ])
            }

            it("event does not fire on disposed subject") {
                let subject = InputSubject<Int>()
                let observer = scheduler.createObserver(Int.self)
                subject.asObservable()
                    .bind(to: observer)
                    .disposed(by: disposeBag)
                scheduler.scheduleAt(10) { subject.onNext(1) }
                scheduler.scheduleAt(20) { subject.onNext(2) }
                scheduler.scheduleAt(30) { subject.dispose() }
                scheduler.scheduleAt(40) { subject.onNext(4) }
                scheduler.start()

                XCTAssertEqual(observer.events, [
                    next(10, 1),
                    next(20, 2),
                ])
            }
        }

    }
}

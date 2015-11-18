import Quick
import Nimble
import RxSwift
import Action

class Test: QuickSpec {
    override func spec() {
        it("fails") {
            // TODO: lol
            fail()
        }
//        it("respects setter") {
//            let subject = NSObject()
//            let disposeBag = DisposeBag()
//            subject.rx_disposeBag = disposeBag
//
//            expect(subject.rx_disposeBag) === disposeBag
//        }
//
//        it("diposes when object is deallocated") {
//            var executed = false
//            let variable = PublishSubject<Int>()
//
//            // Force the bag to deinit (and dispose itself).
//            do {
//                let subject = NSObject()
//                variable.subscribeNext { _ in
//                    executed = true
//                }.addDisposableTo(subject.rx_disposeBag)
//            }
//
//            // Force a new value through the subscription to test its been disposed of.
//            variable.onNext(1)
//            expect(executed) == false
//        }
    }
}

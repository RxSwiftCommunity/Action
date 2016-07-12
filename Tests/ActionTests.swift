//
//  ActionTests.swift
//  Tests
//
//  Created by Yosuke Ishikawa on 2016/07/13.
//  Copyright © 2016年 CezaryKopacz. All rights reserved.
//

import XCTest
import RxSwift
import RxTests
import Action

class ActionTests: XCTestCase {
    
    var disposeBag: DisposeBag!
    
    override func setUp() {
        super.setUp()
        
        disposeBag = DisposeBag()
    }
    
    // MARK: Inputs subject
    
    func testInputValues() {
        let scheduler = TestScheduler(initialClock: 0)
        let action = Action<Int, Int> { Observable.of($0) }
        
        let inputsObserver = scheduler.createObserver(Int.self)
        action.inputs
            .bindTo(inputsObserver)
            .addDisposableTo(disposeBag)
        
        let elementsObserver = scheduler.createObserver(Int.self)
        action.elements
            .bindTo(elementsObserver)
            .addDisposableTo(disposeBag)
        
        scheduler.scheduleAt(10) { action.inputs.onNext(1) }
        scheduler.scheduleAt(30) { action.inputs.onNext(3) }
        
        scheduler.scheduleAt(20) { action.execute(2) }
        scheduler.scheduleAt(40) { action.execute(4) }
        scheduler.start()
        
        XCTAssertEqual(inputsObserver.events, [
            next(10, 1),
            next(20, 2),
            next(30, 3),
            next(40, 4),
        ])
        
        XCTAssertEqual(elementsObserver.events, [
            next(10, 1),
            next(20, 2),
            next(30, 3),
            next(40, 4),
        ])
    }
    
    func testInputValuesWhileExecuting() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 1)
        let action = Action<Int, Int> { Observable.of($0).delaySubscription(25, scheduler: scheduler) }
        
        let inputsObserver = scheduler.createObserver(Int.self)
        action.inputs
            .bindTo(inputsObserver)
            .addDisposableTo(disposeBag)
        
        let elementsObserver = scheduler.createObserver(Int.self)
        action.elements
            .bindTo(elementsObserver)
            .addDisposableTo(disposeBag)
        
        let errorsObserver = scheduler.createObserver(ActionError.self)
        action.errors
            .bindTo(errorsObserver)
            .addDisposableTo(disposeBag)
        
        scheduler.scheduleAt(10) { action.inputs.onNext(1) }
        scheduler.scheduleAt(30) { action.inputs.onNext(3) }
        
        scheduler.scheduleAt(20) { action.execute(2) }
        scheduler.scheduleAt(40) { action.execute(4) }
        
        scheduler.start()
        
        XCTAssertEqual(inputsObserver.events, [
            next(10, 1),
            next(20, 2),
            next(30, 3),
            next(40, 4),
        ])
        
        XCTAssertEqual(elementsObserver.events, [
            next(35, 1),
            next(65, 4),
        ])
        
        XCTAssertEqual(errorsObserver.events.count, 2)
        XCTAssertEqual(errorsObserver.events[0].time, 20)
        XCTAssertEqual(errorsObserver.events[1].time, 30)
    }
    
    // MARK: Output of execute()
    
    func testExecuteWithSuccess() {
        let scheduler = TestScheduler(initialClock: 0, resolution: 1)
        let action = Action<Int, Int> { input in
            let firstElement = Observable.of(input)
            let secondElement = Observable.of(input + 1).delaySubscription(5, scheduler: scheduler)
            
            return Observable
                .of(firstElement, secondElement)
                .merge()
        }
        
        let observer = scheduler.createObserver(Int.self)
        action.execute(1)
            .bindTo(observer)
            .addDisposableTo(disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [
            next(0, 1),
            next(5, 2),
            completed(5),
        ])
    }
    
    func testExecuteWithFailure() {
        enum Error: ErrorType {
            case Expected
        }
        
        let scheduler = TestScheduler(initialClock: 0, resolution: 1)
        let action = Action<Int, Int> { input in
            let element1 = Observable.of(input)
            let element2 = Observable.of(input + 1).delaySubscription(5, scheduler: scheduler)
            let element3 = Observable.of(input + 2).delaySubscription(15, scheduler: scheduler)
            let error = Observable<Int>.error(Error.Expected).delaySubscription(10, scheduler: scheduler)
            
            return Observable
                .of(element1, element2, element3, error)
                .merge()
        }
        
        let observer = scheduler.createObserver(Int.self)
        action.execute(1)
            .bindTo(observer)
            .addDisposableTo(disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(observer.events, [
            next(0, 1),
            next(5, 2),
            error(10, Error.Expected),
        ])
    }
    
}

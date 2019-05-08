import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

/// `Foundation`

extension Optional {
    func asString() -> String {
        guard let s = self else { return "nil" }
        return String(describing: s)
    }
}

/// `RxSwift`

extension Event {
    var isError: Bool {
        switch self {
        case .error: return true
        default: return false
        }
    }
}

/// Nimble

extension PredicateResult {
    static var evaluationFailed: PredicateResult {
        return PredicateResult(status: .doesNotMatch,
                               message: .fail("failed to evaluate given expression"))
    }
    
    static func isEqual<T: Equatable>(actual: T?, expected: T?) -> PredicateResult {
        return PredicateResult(bool: actual == expected,
                               message: .expectedCustomValueTo("get <\(expected.asString())>", "<\(actual.asString())>"))
    }
}

public func match<T>(_ expected: T) -> Predicate<T> where T: Equatable {
    return Predicate { events in
        
        guard let source = try events.evaluate() else {
            return PredicateResult.evaluationFailed
        }
        guard source == expected else {
            return PredicateResult(status: .doesNotMatch,
                                   message: .expectedCustomValueTo("get <\(expected)> events", "<\(source)> events"))
        }
        
        
        return PredicateResult(bool: true, message: .fail("matched values and timeline as expected"))
    }
}

public func match<T>(_ expected: [Recorded<Event<T>>]) -> Predicate<[Recorded<Event<T>>]> where T: Equatable {
    return Predicate { events in
        
        guard let source = try events.evaluate() else {
            return PredicateResult.evaluationFailed
        }
        guard source.count == expected.count else {
            return PredicateResult(bool: false,
                                   message: .expectedCustomValueTo("get <\(expected.count)> events", "<\(source.count)> events"))
        }
        
        for (lhs, rhs) in zip(source, expected) {
            guard lhs.time == rhs.time,
                lhs.value == rhs.value else {
                    return PredicateResult(bool: rhs == lhs,
                                           message: .expectedCustomValueTo("match <\(rhs)>", "<\(lhs)>"))
            }
            continue
        }
        
        return PredicateResult(bool: true, message: .fail("match timeline"))
    }
}

public func match<T, E: Error>(with expectedErrors: [Recorded<Event<E>>]) -> Predicate<[Recorded<Event<T>>]> where E: Equatable {
    return Predicate { events in
        guard let source = try events.evaluate() else {
            return PredicateResult.evaluationFailed
        }
        let errorEvents = source.filter { $0.value.isError }
        for (lhs, rhs) in zip(errorEvents, expectedErrors) {
            guard lhs.time == rhs.time,
                lhs.value.error.asString() == rhs.value.error.asString() else {
                return PredicateResult(bool: false,
                                       message: .fail("did not error"))
            }
            continue
        }
        
        return PredicateResult(bool: true, message: .fail("matched values and timeline as expected"))
    }
}

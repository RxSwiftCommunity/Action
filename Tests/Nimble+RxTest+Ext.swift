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

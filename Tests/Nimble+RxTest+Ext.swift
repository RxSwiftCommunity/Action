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


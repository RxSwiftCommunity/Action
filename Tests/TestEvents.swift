import Foundation
import RxSwift
import RxTest
@testable import Action

enum TestEvents {
    static let inputs = Recorded.events([
        .next(10, "a"),
        .next(20, "b"),
        ])

    static let elements = Recorded.events([
        .next(10, "a"),
        .next(20, "b"),
        ])
    
    static let multipleElements = Recorded.events([
        .next(10, "a"),
        .next(10, "b"),
        .next(10, "c"),
        .next(20, "b"),
        .next(20, "c"),
        .next(20, "d"),
        ])

    static let enabled =  Recorded.events([
        .next(0, true),
        .next(10, false),
        .next(10, true),
        .next(20, false),
        .next(20, true),
        ])

    static let disabled = Recorded.events([
        .next(0, true),
        .next(10, false),
        .next(10, true),
        .next(20, false),
        .next(20, true),
        ])

    static let executing = Recorded.events([
        .next(0, false),
        .next(10, true),
        .next(10, false),
        .next(20, true),
        .next(20, false),
        ])
    
    static let `false` = Recorded.events([
        .next(0, false),
        ])

    static let underlyingErrors = Recorded.events([
        .next(10, ActionError.underlyingError(TestError)),
        .next(20, ActionError.underlyingError(TestError)),
        ])
    
    static let notEnabledErrors = Recorded.events([
        .next(10, ActionError.notEnabled),
        .next(20, ActionError.notEnabled),
        ])
    
    static let executionStreams = Recorded.events([
        .next(10, "a"),
        .completed(10),
        .next(20, "b"),
        .completed(20),
        ])
    
    static let elementUnderlyingErrors = Recorded.events([
        .error(10, ActionError.underlyingError(TestError), String.self),
        .error(20, ActionError.underlyingError(TestError), String.self),
        ])

    static let elementNotEnabledErrors = Recorded.events([
        .error(10, ActionError.notEnabled, String.self),
        .error(20, ActionError.notEnabled, String.self),
        ])
    
    static let multipleExecutionStreams = Recorded.events([
        .next(10, "a"),
        .next(10, "a"),
        .next(10, "a"),
        .completed(10),
        .next(20, "b"),
        .next(20, "b"),
        .next(20, "b"),
        .completed(20),
        ])
}

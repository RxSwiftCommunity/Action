//
//  Action+Extensions.swift
//  Action
//
//  Created by Obi Bob on 01.03.19.
//  Copyright © 2019 CezaryKopacz. All rights reserved.
//

import Foundation
import RxSwift

extension Action {
    /// Filters out `notEnabled` errors and returns
    /// only underlying error from `ActionError`
    var underlyingError: Observable<Error?> {
        return errors.map { actionError in
            guard case .underlyingError(let error) = actionError else {
                return nil
            }
            return error
        }
    }
}

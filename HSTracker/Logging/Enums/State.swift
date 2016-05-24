//
//  State.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

// swiftlint:disable type_name

enum State: Int {
    case INVALID = 0,
    LOADING = 1,
    RUNNING = 2,
    COMPLETE = 3

    init?(rawString: String) {
        for _enum in State.allValues() {
            if "\(_enum)" == rawString {
                self = _enum
                return
            }
        }
        if let value = Int(rawString), _enum = State(rawValue: value) {
            self = _enum
            return
        }
        self = .INVALID
    }

    static func allValues() -> [State] {
        return [.INVALID, .LOADING, .RUNNING, .COMPLETE]
    }
}

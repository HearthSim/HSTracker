//
//  State.swift
//  HSTracker
//
//  Created by Benjamin Michotte on 24/05/16.
//  Copyright © 2016 Benjamin Michotte. All rights reserved.
//

import Foundation

// swiftlint:disable type_name

enum State: Int, EnumCollection {
    case invalid = 0,
    loading = 1,
    running = 2,
    complete = 3

    init?(rawString: String) {
        let string = rawString.lowercased()
        for _enum in State.cases() where "\(_enum)" == string {
            self = _enum
            return
        }
        if let value = Int(rawString), let _enum = State(rawValue: value) {
            self = _enum
            return
        }
        self = .invalid
    }
}
